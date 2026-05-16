<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\AcademicYear;
use App\Models\Grade;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\StudentClassEnrollment;
use App\Models\Subject;
use App\Models\TeachingAssignment;
use App\Services\GradeCalculationService;
use App\Services\ReportCardService;
use App\Notifications\GradePostedNotification;
use Illuminate\Http\Request;
use Inertia\Inertia;
use OpenApi\Attributes as OA;

class GradeController extends Controller
{
    public function __construct(
        protected GradeCalculationService $gradeService,
        protected ReportCardService $reportCardService
    ) {}

    #[OA\Get(
        path: "/grades",
        tags: ["Grades"],
        summary: "List Grades",
        description: "Get list of grades with filtering"
    )]
    #[OA\Parameter(name: "class_id", in: "query", description: "Filter by class ID", required: false, schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "semester_id", in: "query", description: "Filter by semester ID", required: false, schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "subject_id", in: "query", description: "Filter by subject ID", required: false, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "List of grades")]
    public function index(Request $request)
    {
        \Illuminate\Support\Facades\Gate::authorize('viewAny', Grade::class);

        $user = $request->user();
        $activeAy = AcademicYear::where('is_active', true)->first();
        $requestedAyId = $request->integer('academic_year_id') ?: null;
        $selectedAyId = $requestedAyId ?: $activeAy?->id;

        $academicYears = AcademicYear::orderByDesc('start_date')->get(['id', 'name', 'is_active']);
        $student = ($user->isStudent() && $user->student) ? $user->student : null;

        if ($student) {
            $academicYears = AcademicYear::query()
                ->where(function ($query) use ($student) {
                    $query->whereHas('semesters.enrollments', fn ($q) => $q->where('student_id', $student->id))
                        ->orWhereHas('semesters.grades', fn ($q) => $q->where('student_id', $student->id))
                        ->orWhereHas('classes.students', fn ($q) => $q->where('students.id', $student->id));
                })
                ->orderByDesc('start_date')
                ->get(['id', 'name', 'is_active']);

            if ($academicYears->isEmpty() && $activeAy) {
                $academicYears = AcademicYear::whereKey($activeAy->id)->get(['id', 'name', 'is_active']);
            }

            $selectedAyId = $requestedAyId
                ?: (($activeAy && $academicYears->contains('id', $activeAy->id))
                    ? $activeAy->id
                    : $academicYears->first()?->id);
        }

        $classesQuery = SchoolClass::query()
            ->with('academicYear')
            ->orderBy('grade_level')
            ->orderBy('name');

        // Scope teacher: only classes they are homeroom of OR have a TA in
        if ($user->isTeacher() && $user->teacher) {
            $teacherId = $user->teacher->id;
            $taClassIds = TeachingAssignment::where('teacher_id', $teacherId)->pluck('class_id')->all();
            $homeroomClassIds = SchoolClass::where('homeroom_teacher_id', $teacherId)->pluck('id')->all();
            $visibleIds = array_values(array_unique(array_merge($taClassIds, $homeroomClassIds)));
            $classesQuery->where('status', 'active')
                ->when($selectedAyId, fn ($q, $ay) => $q->where('academic_year_id', $ay))
                ->whereIn('id', $visibleIds ?: [0]);
        } elseif ($student) {
            $student->loadMissing('class');

            $enrollmentClassIds = StudentClassEnrollment::query()
                ->where('student_id', $student->id)
                ->whereHas('semester', fn ($q) => $q->when($selectedAyId, fn ($qq, $ay) => $qq->where('academic_year_id', $ay)))
                ->pluck('class_id');

            $gradeClassIds = Grade::query()
                ->where('student_id', $student->id)
                ->whereHas('semester', fn ($q) => $q->when($selectedAyId, fn ($qq, $ay) => $qq->where('academic_year_id', $ay)))
                ->pluck('class_id');

            $currentClassId = $student->class && (! $selectedAyId || (int) $student->class->academic_year_id === (int) $selectedAyId)
                ? [$student->class_id]
                : [];

            $visibleClassIds = $enrollmentClassIds
                ->merge($gradeClassIds)
                ->merge($currentClassId)
                ->filter()
                ->unique()
                ->values();

            $classesQuery->whereIn('id', $visibleClassIds->all() ?: [0]);
        } else {
            $classesQuery->where('status', 'active')
                ->when($selectedAyId, fn ($q, $ay) => $q->where('academic_year_id', $ay));
        }

        $classes = $classesQuery->get();

        if ($student) {
            $visibleSemesterIds = StudentClassEnrollment::query()
                ->where('student_id', $student->id)
                ->pluck('semester_id')
                ->merge(Grade::where('student_id', $student->id)->pluck('semester_id'))
                ->filter()
                ->unique()
                ->values();

            $semesters = Semester::query()
                ->whereIn('id', $visibleSemesterIds->all() ?: [0])
                ->when($selectedAyId, fn ($q, $ay) => $q->where('academic_year_id', $ay))
                ->with('academicYear')
                ->orderBy('semester_number')
                ->get();
        } else {
            $semesters = Semester::query()
                ->when($selectedAyId, fn ($q, $ay) => $q->where('academic_year_id', $ay))
                ->with('academicYear')
                ->orderBy('semester_number')
                ->get();
        }

        $subjects = Subject::active()->get();

        $grades = null;
        $classId = $request->integer('class_id') ?: null;
        $semesterId = $request->integer('semester_id') ?: null;
        $subjectId = $request->integer('subject_id') ?: null;

        if ($student) {
            abort_if($classId && ! $classes->contains('id', $classId), 403, 'Kelas ini tidak ada di riwayat siswa.');
            abort_if($semesterId && ! $semesters->contains('id', $semesterId), 403, 'Semester ini tidak ada di riwayat siswa.');
        }

        if ($classId && $semesterId) {
            // Scope grades to own student record if siswa, otherwise full class.
            $scopeStudentId = $student?->id;

            // Cache key MUST include the scope to prevent cross-user cache poisoning.
            $cacheKey = 'grades_' . md5(json_encode([
                [
                    'academic_year_id' => $selectedAyId,
                    'class_id' => $classId,
                    'semester_id' => $semesterId,
                    'subject_id' => $subjectId,
                ],
                'student_scope' => $scopeStudentId,
            ]));

            $grades = cache()->remember($cacheKey, 60, function () use ($classId, $semesterId, $subjectId, $scopeStudentId) {
                return Grade::with(['student', 'subject', 'teacher', 'semester.academicYear', 'schoolClass.academicYear'])
                    ->where('class_id', $classId)
                    ->where('semester_id', $semesterId)
                    ->when($subjectId, fn($q, $s) => $q->where('subject_id', $s))
                    ->when($scopeStudentId, fn($q, $sid) => $q->where('student_id', $sid))
                    ->get();
            });
        }

        return Inertia::render('Grades/Index', [
            'academicYears' => $academicYears,
            'classes'    => $classes,
            'semesters'  => $semesters,
            'subjects'   => $subjects,
            'grades'     => $grades,
            'filters'    => array_merge(
                $request->only(['class_id', 'semester_id', 'subject_id']),
                ['academic_year_id' => $selectedAyId]
            ),
        ]);
    }

    #[OA\Get(
        path: "/grades/batch",
        tags: ["Grades"],
        summary: "Batch Input View",
        description: "Get view for batch grade input"
    )]
    #[OA\Parameter(name: "class_id", in: "query", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "semester_id", in: "query", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "subject_id", in: "query", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Batch input view")]
    public function batchInput(Request $request)
    {
        \Illuminate\Support\Facades\Gate::authorize('create', Grade::class);

        $class = SchoolClass::with('students')->findOrFail($request->class_id);
        $semester = Semester::findOrFail($request->semester_id);
        $subject = Subject::findOrFail($request->subject_id);

        $students = $class->students()->active()->orderBy('name')->get();

        // Load existing grades
        $existingGrades = Grade::where('class_id', $class->id)
            ->where('semester_id', $semester->id)
            ->where('subject_id', $subject->id)
            ->get()
            ->keyBy('student_id');

        return Inertia::render('Grades/BatchInput', [
            'class'          => $class,
            'semester'       => $semester,
            'subject'        => $subject,
            'students'       => $students,
            'existingGrades' => $existingGrades,
        ]);
    }

    #[OA\Post(
        path: "/grades/batch",
        tags: ["Grades"],
        summary: "Store Batch Grades",
        description: "Store multiple grades at once"
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["class_id", "semester_id", "subject_id", "grades"],
            properties: [
                new OA\Property(property: "class_id", type: "integer"),
                new OA\Property(property: "semester_id", type: "integer"),
                new OA\Property(property: "subject_id", type: "integer"),
                new OA\Property(property: "grades", type: "array", items: new OA\Items(
                    type: "object",
                    properties: [
                        new OA\Property(property: "student_id", type: "integer"),
                        new OA\Property(property: "daily_test_avg", type: "number"),
                        new OA\Property(property: "mid_test", type: "number"),
                        new OA\Property(property: "final_test", type: "number"),
                        new OA\Property(property: "knowledge_score", type: "number"),
                        new OA\Property(property: "skill_score", type: "number"),
                    ]
                )),
            ]
        )
    )]
    #[OA\Response(response: 302, description: "Redirect to index")]
    public function storeBatch(Request $request)
    {
        \Illuminate\Support\Facades\Gate::authorize('create', Grade::class);

        $validated = $request->validate([
            'class_id'    => 'required|exists:classes,id',
            'semester_id' => 'required|exists:semesters,id',
            'subject_id'  => 'required|exists:subjects,id',
            'grades'      => 'required|array',
            'grades.*.student_id'      => 'required|exists:students,id',
            'grades.*.daily_test_avg'  => 'nullable|numeric|min:0|max:100',
            'grades.*.mid_test'        => 'nullable|numeric|min:0|max:100',
            'grades.*.final_test'      => 'nullable|numeric|min:0|max:100',
            'grades.*.knowledge_score' => 'nullable|numeric|min:0|max:100',
            'grades.*.skill_score'     => 'nullable|numeric|min:0|max:100',
            'grades.*.attitude_score'  => 'nullable|string|max:5',
            'grades.*.notes'           => 'nullable|string|max:255',
        ]);

        // A3/A4 guard: teacher must have a TA for this class+subject to submit grades.
        $user = $request->user();
        if ($user->isTeacher() && $user->teacher) {
            $hasTA = \Illuminate\Support\Facades\DB::table('teaching_assignments')
                ->where('teacher_id', $user->teacher->id)
                ->where('class_id', $validated['class_id'])
                ->where('subject_id', $validated['subject_id'])
                ->exists();
            abort_unless($hasTA, 403, 'Anda tidak mengajar mata pelajaran ini di kelas tersebut.');
        }

        $subject = Subject::findOrFail($validated['subject_id']);
        $educationLevel = config('school.education_level', 'SD');

        $studentIdsToUpdate = [];

        foreach ($validated['grades'] as $gradeData) {
            $calculated = [];

            if ($educationLevel === 'SD') {
                $calculated = $this->gradeService->calculateSD(
                    $gradeData['daily_test_avg'] ?? 0,
                    $gradeData['mid_test'] ?? 0,
                    $gradeData['final_test'] ?? 0
                );
            } else {
                $calculated = $this->gradeService->calculateSMPSMA(
                    $gradeData['knowledge_score'] ?? 0,
                    $gradeData['skill_score'] ?? 0
                );
            }

            $grade = Grade::updateOrCreate(
                [
                    'student_id'  => $gradeData['student_id'],
                    'subject_id'  => $validated['subject_id'],
                    'semester_id' => $validated['semester_id'],
                ],
                array_merge($gradeData, $calculated, [
                    'class_id'   => $validated['class_id'],
                    'teacher_id' => auth()->user()->id ?? null,
                ])
            );

            $studentIdsToUpdate[] = $gradeData['student_id'];

            // Notify Student (and Parent linked via student)
            if ($grade && $grade->student && $grade->student->user) {
                // Check if grade was actually updated/created recently? 
                // For now, always notify on save.
                $grade->student->user->notify(new GradePostedNotification($grade));
            }
        }

        // Auto-synchronize Report Cards for these students (default report type 'final')
        $studentIdsToUpdate = array_unique($studentIdsToUpdate);
        foreach ($studentIdsToUpdate as $studentId) {
            $this->reportCardService->generate(
                $studentId,
                $validated['class_id'],
                $validated['semester_id'],
                'final'
            );
        }

        // Auto-recalculate class rankings for the same report type
        $this->reportCardService->calculateRankings(
            $validated['class_id'],
            $validated['semester_id'],
            'final'
        );

        return redirect()->route('grades.index', [
            'class_id'    => $validated['class_id'],
            'semester_id' => $validated['semester_id'],
            'subject_id'  => $validated['subject_id'],
        ])->with('success', 'Nilai berhasil disimpan.');
    }
}
