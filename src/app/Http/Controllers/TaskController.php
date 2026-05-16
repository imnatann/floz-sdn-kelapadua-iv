<?php

namespace App\Http\Controllers;

use App\Models\Task;
use App\Models\TaskScore;
use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Subject;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class TaskController extends Controller
{
    /**
     * Assert the authenticated user may manage tasks for the given class+subject.
     * - Admin: always allowed.
     * - Teacher: must have a TeachingAssignment for (teacher_id, class_id, subject_id).
     * - Others (student, etc.): 403.
     */
    private function authorizeManage(Request $request, int $classId, int $subjectId): void
    {
        $user = $request->user();

        if ($user->isSchoolAdmin()) {
            return;
        }

        if ($user->isTeacher() && $user->teacher) {
            $hasTA = DB::table('teaching_assignments')
                ->where('teacher_id', $user->teacher->id)
                ->where('class_id', $classId)
                ->where('subject_id', $subjectId)
                ->exists();

            abort_unless($hasTA, 403, 'Anda tidak mengajar mata pelajaran ini di kelas tersebut.');
            return;
        }

        abort(403, 'Unauthorized');
    }

    /**
     * Assert the authenticated user may manage an existing task (storeScores / destroy).
     */
    private function authorizeTaskOwnership(Request $request, Task $task): void
    {
        $this->authorizeManage($request, $task->class_id, $task->subject_id);
    }
    /**
     * Display a listing of classes to choose from.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        // Filter by academic year: explicit query param, else default to active AY
        $activeAy = AcademicYear::where('is_active', true)->first();
        $selectedAyId = $request->integer('academic_year_id') ?: $activeAy?->id;
        $student = ($user->isStudent() && $user->student) ? $user->student : null;

        $academicYears = AcademicYear::orderByDesc('start_date')->get(['id', 'name', 'is_active']);
        $query = SchoolClass::query()->with('academicYear:id,name,is_active');

        if ($student) {
            $academicYears = AcademicYear::query()
                ->whereHas('semesters.enrollments', fn ($q) => $q->where('student_id', $student->id))
                ->orderByDesc('start_date')
                ->get(['id', 'name', 'is_active']);

            if ($academicYears->isEmpty() && $activeAy) {
                $academicYears = AcademicYear::whereKey($activeAy->id)->get(['id', 'name', 'is_active']);
            }

            $selectedAyId = $request->integer('academic_year_id')
                ?: (($activeAy && $academicYears->contains('id', $activeAy->id))
                    ? $activeAy->id
                    : $academicYears->first()?->id);

            $enrollmentClassIds = StudentClassEnrollment::query()
                ->where('student_id', $student->id)
                ->whereHas('semester', fn ($q) => $q->when($selectedAyId, fn ($qq, $ay) => $qq->where('academic_year_id', $ay)))
                ->pluck('class_id');

            $student->loadMissing('class');
            $currentClassId = $student->class && (! $selectedAyId || (int) $student->class->academic_year_id === (int) $selectedAyId)
                ? [$student->class_id]
                : [];

            $classIds = $enrollmentClassIds
                ->merge($currentClassId)
                ->filter()
                ->unique()
                ->values();

            $query->whereIn('id', $classIds->all() ?: [0]);
        } elseif ($user->isTeacher() && $user->teacher) {
            $teacherId = $user->teacher->id;
            $classIds = DB::table('teaching_assignments')
                ->where('teacher_id', $teacherId)
                ->pluck('class_id')
                ->toArray();

            $homeroomClassIds = SchoolClass::where('homeroom_teacher_id', $teacherId)
                ->pluck('id')
                ->toArray();

            $allClassIds = array_unique(array_merge($classIds, $homeroomClassIds));
            $query->where('status', 'active')->whereIn('id', $allClassIds);
        } else {
            $query->where('status', 'active');
        }

        if ($selectedAyId) {
            $query->where('academic_year_id', $selectedAyId);
        }

        $query->withCount([
            'enrollments as students_count' => fn ($q) => $q
                ->whereHas(
                    'semester',
                    fn ($qq) => $qq->when($selectedAyId, fn ($qqq, $ay) => $qqq->where('academic_year_id', $ay))
                )
                ->select(DB::raw('count(distinct student_id)')),
        ]);

        $classes = $query->orderBy('grade_level')->orderBy('name')->get();

        return Inertia::render('Tasks/Index', [
            'classes'       => $classes,
            'academicYears' => $academicYears,
            'filters'       => ['academic_year_id' => $selectedAyId],
        ]);
    }

    /**
     * Display tasks for a specific class.
     */
    public function classIndex(SchoolClass $class, Request $request)
    {
        $user = $request->user();
        $student = ($user->isStudent() && $user->student) ? $user->student : null;

        $studentSemesterIds = collect();
        if ($student) {
            $studentSemesterIds = StudentClassEnrollment::query()
                ->where('student_id', $student->id)
                ->where('class_id', $class->id)
                ->whereHas('semester', fn ($q) => $q->where('academic_year_id', $class->academic_year_id))
                ->pluck('semester_id');

            $student->loadMissing('class');
            if ($student->class_id === $class->id && $student->class?->academic_year_id === $class->academic_year_id) {
                $currentClassSemesterIds = Semester::where('academic_year_id', $class->academic_year_id)->pluck('id');
                $studentSemesterIds = $studentSemesterIds->merge($currentClassSemesterIds);
            }

            $studentSemesterIds = $studentSemesterIds->filter()->unique()->values();
            abort_if($studentSemesterIds->isEmpty(), 403, 'Anda hanya dapat melihat kelas yang ada di riwayat Anda.');
        }

        // Semester dropdown: all semesters belonging to the class's academic year (not just those with tasks).
        // This lets admin pick any semester within this AY even before any task is created.
        $semesters = Semester::with('academicYear')
            ->where('academic_year_id', $class->academic_year_id)
            ->when($student, fn ($q) => $q->whereIn('id', $studentSemesterIds->all()))
            ->orderBy('semester_number')
            ->get();

        // Default selected semester: query param → active semester within this AY → first semester of this AY
        $activeSemesterInAy = Semester::where('is_active', true)
            ->where('academic_year_id', $class->academic_year_id)
            ->first();
        $requestedSemesterId = $request->integer('semester_id') ?: null;
        abort_if($requestedSemesterId && ! $semesters->contains('id', $requestedSemesterId), 404, 'Semester tidak tersedia untuk kelas ini.');

        $selectedSemesterId = $requestedSemesterId
            ?: (($activeSemesterInAy && $semesters->contains('id', $activeSemesterInAy->id))
                ? $activeSemesterInAy->id
                : $semesters->first()?->id);

        if (!$selectedSemesterId) {
            return Inertia::render('Tasks/ClassIndex', [
                'schoolClass'   => $class,
                'tasks'         => [],
                'subjects'      => [],
                'semesters'     => $semesters,
                'filters'       => ['subject_id' => null, 'semester_id' => null],
                'studentsCount' => 0,
            ]);
        }

        $tasksQuery = Task::where('class_id', $class->id)
            ->where('semester_id', $selectedSemesterId)
            ->when($request->subject_id, fn ($q, $s) => $q->where('subject_id', $s))
            ->with(['subject', 'teacher'])
            ->withCount([
                'scores',
                'scores as kumpul_count' => fn ($q) => $q->where('submission_status', TaskScore::STATUS_KUMPUL),
                'scores as terlambat_count' => fn ($q) => $q->where('submission_status', TaskScore::STATUS_TERLAMBAT),
                'scores as tidak_kumpul_count' => fn ($q) => $q->where('submission_status', TaskScore::STATUS_TIDAK_KUMPUL),
            ])
            ->orderByDesc('task_date');

        $tasks = $tasksQuery->get();

        // Subjects available for filter dropdown: distinct subjects that have tasks in this class (across all semesters)
        $subjects = Subject::whereIn('id', Task::where('class_id', $class->id)->distinct()->pluck('subject_id'))
            ->orderBy('name')
            ->get(['id', 'name']);

        // Subjects available for Excel export: all subjects taught in this class (via teaching assignments).
        // This is broader than $subjects above — admin can export a mapel even before any task exists.
        $exportableSubjects = Subject::whereIn(
                'id',
                DB::table('teaching_assignments')->where('class_id', $class->id)->pluck('subject_id')->unique()
            )
            ->where('status', 'active')
            ->orderBy('name')
            ->get(['id', 'name']);

        return Inertia::render('Tasks/ClassIndex', [
            'schoolClass'        => $class,
            'tasks'              => $tasks,
            'subjects'           => $subjects,
            'exportableSubjects' => $exportableSubjects,
            'semesters'          => $semesters,
            'filters'            => [
                'subject_id'  => $request->integer('subject_id') ?: null,
                'semester_id' => $selectedSemesterId,
            ],
            'studentsCount'      => \App\Models\StudentClassEnrollment::where('class_id', $class->id)
                ->where('semester_id', $selectedSemesterId)
                ->count(),
        ]);
    }

    /**
     * Show the form for creating a new task.
     */
    public function create(SchoolClass $class, Request $request)
    {
        $user = $request->user();
        
        // Get subjects taught by this teacher in this class
        $subjectsQuery = Subject::where('status', 'active');
        
        if ($user->isTeacher() && $user->teacher) {
            $isHomeroom = $class->homeroom_teacher_id === $user->teacher->id;
            if (!$isHomeroom) {
                // If not homeroom, only show subjects they teach
                $subjectIds = DB::table('teaching_assignments')
                    ->where('teacher_id', $user->teacher->id)
                    ->where('class_id', $class->id)
                    ->pluck('subject_id')
                    ->toArray();
                $subjectsQuery->whereIn('id', $subjectIds);
            }
        }
        
        $subjects = $subjectsQuery->orderBy('name')->get();

        return Inertia::render('Tasks/Create', [
            'schoolClass' => $class,
            'subjects' => $subjects,
            'todayDate' => Carbon::today()->format('Y-m-d')
        ]);
    }

    /**
     * Store a newly created task in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'class_id' => 'required|exists:classes,id',
            'subject_id' => 'required|exists:subjects,id',
            'semester_id' => 'nullable|exists:semesters,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'task_date' => 'required|date',
            'due_date' => 'nullable|date|after_or_equal:task_date',
            'max_score' => 'required|numeric|min:1|max:1000',
        ]);

        // A4/A5 guard: only admin or teacher with TA for this class+subject may create tasks.
        $this->authorizeManage($request, $validated['class_id'], $validated['subject_id']);

        // Pick a semester belonging to the target class's AY — explicit > active-in-AY > first-in-AY.
        $class = SchoolClass::findOrFail($validated['class_id']);
        $semester = isset($validated['semester_id'])
            ? Semester::where('id', $validated['semester_id'])->where('academic_year_id', $class->academic_year_id)->first()
            : null;
        $semester ??= Semester::where('is_active', true)->where('academic_year_id', $class->academic_year_id)->first();
        $semester ??= Semester::where('academic_year_id', $class->academic_year_id)->orderBy('semester_number')->first();

        if (!$semester) {
            return redirect()->back()->with('error', 'Belum ada semester yang dibuat untuk tahun ajaran kelas ini. Buat semester dulu di menu Tahun Ajaran.');
        }

        $teacherId = $request->user()->teacher ? $request->user()->teacher->id : null;

        $task = Task::create([
            'class_id' => $validated['class_id'],
            'subject_id' => $validated['subject_id'],
            'semester_id' => $semester->id,
            'teacher_id' => $teacherId,
            'title' => $validated['title'],
            'description' => $validated['description'],
            'task_date' => $validated['task_date'],
            'due_date' => $validated['due_date'],
            'max_score' => $validated['max_score'],
            'status' => 'active',
        ]);

        return redirect()->route('tasks.class', $task->class_id)->with('success', 'Tugas berhasil dibuat.');
    }

    /**
     * Display the specified task and student scores.
     * This is the main interface for inputting grades (teacher/admin) or
     * viewing own score (student).
     */
    public function show(Task $task, Request $request)
    {
        $user = $request->user();
        $task->load(['schoolClass', 'subject', 'semester', 'teacher']);

        $studentsQuery = \App\Models\Student::query()
            ->select('students.*')
            ->join('student_class_enrollments as sce', 'sce.student_id', '=', 'students.id')
            ->where('sce.class_id', $task->class_id)
            ->where('sce.semester_id', $task->semester_id)
            ->orderBy('students.name');

        if ($user->isStudent() && $user->student) {
            // Siswa: must have an enrollment in this task's class+semester; only see their own row.
            $enrolled = \App\Models\StudentClassEnrollment::where('student_id', $user->student->id)
                ->where('class_id', $task->class_id)
                ->where('semester_id', $task->semester_id)
                ->exists();
            if (!$enrolled) {
                abort(403, 'Anda hanya dapat melihat tugas dari kelas Anda sendiri.');
            }
            $studentsQuery->where('students.id', $user->student->id);
        }

        $students = $studentsQuery->get();

        $scoresQuery = TaskScore::where('task_id', $task->id);
        if ($user->isStudent() && $user->student) {
            $scoresQuery->where('student_id', $user->student->id);
        }
        $scores = $scoresQuery->get()->keyBy('student_id');

        return Inertia::render('Tasks/Show', [
            'task'     => $task,
            'students' => $students,
            'scores'   => $scores,
        ]);
    }

    /**
     * Store all student scores for a task.
     */
    public function storeScores(Request $request, Task $task)
    {
        // A4/A5 guard: only admin or the teacher who owns this task's TA may input scores.
        $this->authorizeTaskOwnership($request, $task);

        $validated = $request->validate([
            'scores' => 'required|array',
            'scores.*.student_id' => 'required|exists:students,id',
            'scores.*.score' => 'nullable|numeric|min:0|max:1000',
            'scores.*.notes' => 'nullable|string|max:255',
            'scores.*.submission_status' => 'required|in:'.implode(',', TaskScore::STATUSES),
        ]);

        DB::transaction(function () use ($validated, $task) {
            foreach ($validated['scores'] as $data) {
                $status = $data['submission_status'];
                $score = $status === TaskScore::STATUS_TIDAK_KUMPUL ? null : $data['score'];

                $hasData = $score !== null
                    || !empty($data['notes'])
                    || $status !== TaskScore::STATUS_KUMPUL;

                if ($hasData) {
                    TaskScore::updateOrCreate(
                        [
                            'task_id' => $task->id,
                            'student_id' => $data['student_id'],
                        ],
                        [
                            'score' => $score,
                            'notes' => $data['notes'],
                            'submission_status' => $status,
                        ]
                    );
                } else {
                    TaskScore::where('task_id', $task->id)
                             ->where('student_id', $data['student_id'])
                             ->delete();
                }
            }

            // Mark task as graded
            $task->update(['status' => 'graded']);
        });

        return redirect()->back()->with('success', 'Nilai tugas berhasil disimpan.');
    }

    /**
     * Remove the specified task.
     */
    public function destroy(Task $task)
    {
        // A4/A5 guard: only admin or the teacher with TA for this task may delete it.
        $this->authorizeTaskOwnership(request(), $task);

        $classId = $task->class_id;
        $task->delete();
        
        return redirect()->route('tasks.class', $classId)->with('success', 'Tugas dan nilai-nilainya berhasil dihapus.');
    }
}
