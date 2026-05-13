<?php

namespace App\Http\Controllers;

use App\Models\Exam;
use App\Models\ExamScore;
use App\Models\SchoolClass;
use App\Models\Subject;
use App\Models\Semester;
use App\Models\Student;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class ExamController extends Controller
{
    /**
     * Assert the authenticated user may manage exams for the given class+subject.
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
     * Assert the authenticated user may manage an existing exam (storeScores / destroy).
     */
    private function authorizeExamOwnership(Request $request, Exam $exam): void
    {
        $this->authorizeManage($request, $exam->class_id, $exam->subject_id);
    }
    /**
     * Display a listing of classes to choose from.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $query = SchoolClass::where('status', 'active');

        if ($user->isStudent() && $user->student) {
            // Students only see their own class
            $query->where('id', $user->student->class_id);
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
            $query->whereIn('id', $allClassIds);
        }

        $classes = $query->withCount('students')->orderBy('name')->get();

        return Inertia::render('Exams/Index', [
            'classes' => $classes,
        ]);
    }

    /**
     * Display exams for a specific class.
     */
    public function classIndex(SchoolClass $class, Request $request)
    {
        $user = $request->user();
        if ($user->isStudent() && $user->student && $user->student->class_id !== $class->id) {
            abort(403, 'Anda hanya dapat melihat kelas Anda sendiri.');
        }

        $semesters = Semester::with('academicYear')
            ->whereIn('id', Exam::where('class_id', $class->id)->distinct()->pluck('semester_id'))
            ->orderByDesc('start_date')
            ->get();
        $activeSemester = Semester::where('is_active', true)->first();
        $selectedSemesterId = $request->integer('semester_id')
            ?: ($activeSemester?->id ?? $semesters->first()?->id);

        if (!$selectedSemesterId) {
            return Inertia::render('Exams/ClassIndex', [
                'schoolClass'   => $class,
                'exams'         => [],
                'subjects'      => [],
                'semesters'     => $semesters,
                'filters'       => ['subject_id' => null, 'semester_id' => null],
                'studentsCount' => $class->students()->count(),
            ]);
        }

        $exams = Exam::where('class_id', $class->id)
            ->where('semester_id', $selectedSemesterId)
            ->when($request->subject_id, fn ($q, $s) => $q->where('subject_id', $s))
            ->with(['subject', 'teacher'])
            ->withCount([
                'scores',
                'scores as kumpul_count' => fn ($q) => $q->where('submission_status', ExamScore::STATUS_KUMPUL),
                'scores as terlambat_count' => fn ($q) => $q->where('submission_status', ExamScore::STATUS_TERLAMBAT),
                'scores as tidak_kumpul_count' => fn ($q) => $q->where('submission_status', ExamScore::STATUS_TIDAK_KUMPUL),
            ])
            ->orderByDesc('exam_date')
            ->get();

        $subjects = Subject::whereIn('id', Exam::where('class_id', $class->id)->distinct()->pluck('subject_id'))
            ->orderBy('name')
            ->get(['id', 'name']);

        return Inertia::render('Exams/ClassIndex', [
            'schoolClass'   => $class,
            'exams'         => $exams,
            'subjects'      => $subjects,
            'semesters'     => $semesters,
            'filters'       => [
                'subject_id'  => $request->integer('subject_id') ?: null,
                'semester_id' => $selectedSemesterId,
            ],
            'studentsCount' => $class->students()->count(),
        ]);
    }

    /**
     * Show the form for creating a new exam.
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

        return Inertia::render('Exams/Create', [
            'schoolClass' => $class,
            'subjects' => $subjects,
            'todayDate' => Carbon::today()->format('Y-m-d')
        ]);
    }

    /**
     * Store a newly created exam in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'class_id' => 'required|exists:classes,id',
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'exam_type' => 'required|in:ulangan_harian,uts,uas',
            'exam_date' => 'required|date',
            'max_score' => 'required|numeric|min:1|max:100',
        ]);

        // A4/A5 guard: only admin or teacher with TA for this class+subject may create exams.
        $this->authorizeManage($request, $validated['class_id'], $validated['subject_id']);

        $activeSemester = Semester::where('is_active', true)->first();
        if (!$activeSemester) {
            return redirect()->back()->with('error', 'Tidak ada semester aktif.');
        }

        $teacherId = $request->user()->teacher ? $request->user()->teacher->id : null;

        $exam = Exam::create([
            'class_id' => $validated['class_id'],
            'subject_id' => $validated['subject_id'],
            'semester_id' => $activeSemester->id,
            'teacher_id' => $teacherId,
            'title' => $validated['title'],
            'exam_type' => $validated['exam_type'],
            'exam_date' => $validated['exam_date'],
            'max_score' => $validated['max_score'],
            'status' => 'active',
        ]);

        return redirect()->route('exams.class', $exam->class_id)->with('success', 'Ujian berhasil dibuat.');
    }

    /**
     * Display the specified exam and student scores.
     * This is the main interface for inputting grades (teacher/admin) or
     * viewing own score (student).
     */
    public function show(Exam $exam, Request $request)
    {
        $user = $request->user();
        $exam->load(['schoolClass', 'subject', 'semester', 'teacher']);

        $studentsQuery = Student::where('class_id', $exam->class_id)
            ->where('status', 'active')
            ->orderBy('name');

        if ($user->isStudent() && $user->student) {
            if ($user->student->class_id !== $exam->class_id) {
                abort(403, 'Anda hanya dapat melihat ujian dari kelas Anda sendiri.');
            }
            $studentsQuery->where('id', $user->student->id);
        }

        $students = $studentsQuery->get();

        $scoresQuery = ExamScore::where('exam_id', $exam->id);
        if ($user->isStudent() && $user->student) {
            $scoresQuery->where('student_id', $user->student->id);
        }
        $scores = $scoresQuery->get()->keyBy('student_id');

        return Inertia::render('Exams/Show', [
            'exam'     => $exam,
            'students' => $students,
            'scores'   => $scores,
        ]);
    }

    /**
     * Store all student scores for an exam.
     */
    public function storeScores(Request $request, Exam $exam)
    {
        // A4/A5 guard: only admin or the teacher who owns this exam's TA may input scores.
        $this->authorizeExamOwnership($request, $exam);

        $validated = $request->validate([
            'scores' => 'required|array',
            'scores.*.student_id' => 'required|exists:students,id',
            'scores.*.score' => 'nullable|numeric|min:0|max:100',
            'scores.*.notes' => 'nullable|string|max:255',
            'scores.*.submission_status' => 'required|in:'.implode(',', ExamScore::STATUSES),
        ]);

        DB::transaction(function () use ($validated, $exam) {
            foreach ($validated['scores'] as $data) {
                $status = $data['submission_status'];
                $score = $status === ExamScore::STATUS_TIDAK_KUMPUL ? null : $data['score'];

                $hasData = $score !== null
                    || !empty($data['notes'])
                    || $status !== ExamScore::STATUS_KUMPUL;

                if ($hasData) {
                    ExamScore::updateOrCreate(
                        [
                            'exam_id' => $exam->id,
                            'student_id' => $data['student_id'],
                        ],
                        [
                            'score' => $score,
                            'notes' => $data['notes'],
                            'submission_status' => $status,
                        ]
                    );
                } else {
                    ExamScore::where('exam_id', $exam->id)
                             ->where('student_id', $data['student_id'])
                             ->delete();
                }
            }

            // Mark exam as graded
            $exam->update(['status' => 'graded']);
        });

        return redirect()->back()->with('success', 'Nilai ujian berhasil disimpan.');
    }

    /**
     * Remove the specified exam.
     */
    public function destroy(Exam $exam)
    {
        // A4/A5 guard: only admin or the teacher with TA for this exam may delete it.
        $this->authorizeExamOwnership(request(), $exam);

        $classId = $exam->class_id;
        $exam->delete();
        
        return redirect()->route('exams.class', $classId)->with('success', 'Ujian dan nilai-nilainya berhasil dihapus.');
    }
}
