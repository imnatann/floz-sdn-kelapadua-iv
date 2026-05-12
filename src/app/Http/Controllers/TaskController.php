<?php

namespace App\Http\Controllers;

use App\Models\Task;
use App\Models\TaskScore;
use App\Models\SchoolClass;
use App\Models\Subject;
use App\Models\Semester;
use App\Models\Student;
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

        return Inertia::render('Tasks/Index', [
            'classes' => $classes,
        ]);
    }

    /**
     * Display tasks for a specific class.
     */
    public function classIndex(SchoolClass $class, Request $request)
    {
        $user = $request->user();
        if ($user->isStudent() && $user->student && $user->student->class_id !== $class->id) {
            abort(403, 'Anda hanya dapat melihat kelas Anda sendiri.');
        }

        // Resolve semester filter: explicit `semester_id` → active semester → most recent semester with tasks in class
        $semesters = Semester::with('academicYear')
            ->whereIn('id', Task::where('class_id', $class->id)->distinct()->pluck('semester_id'))
            ->orderByDesc('start_date')
            ->get();
        $activeSemester = Semester::where('is_active', true)->first();
        $selectedSemesterId = $request->integer('semester_id')
            ?: ($activeSemester?->id ?? $semesters->first()?->id);

        if (!$selectedSemesterId) {
            return Inertia::render('Tasks/ClassIndex', [
                'schoolClass'   => $class,
                'tasks'         => [],
                'subjects'      => [],
                'semesters'     => $semesters,
                'filters'       => ['subject_id' => null, 'semester_id' => null],
                'studentsCount' => $class->students()->count(),
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

        return Inertia::render('Tasks/ClassIndex', [
            'schoolClass'   => $class,
            'tasks'         => $tasks,
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
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'task_date' => 'required|date',
            'due_date' => 'nullable|date|after_or_equal:task_date',
            'max_score' => 'required|numeric|min:1|max:1000',
        ]);

        // A4/A5 guard: only admin or teacher with TA for this class+subject may create tasks.
        $this->authorizeManage($request, $validated['class_id'], $validated['subject_id']);

        $activeSemester = Semester::where('is_active', true)->first();
        if (!$activeSemester) {
            return redirect()->back()->with('error', 'Tidak ada semester aktif.');
        }

        $teacherId = $request->user()->teacher ? $request->user()->teacher->id : null;

        $task = Task::create([
            'class_id' => $validated['class_id'],
            'subject_id' => $validated['subject_id'],
            'semester_id' => $activeSemester->id,
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
     * This is the main interface for inputting grades.
     */
    public function show(Task $task)
    {
        $task->load(['schoolClass', 'subject', 'semester', 'teacher']);
        
        $students = Student::where('class_id', $task->class_id)
            ->where('status', 'active')
            ->orderBy('name')
            ->get();
            
        $scores = TaskScore::where('task_id', $task->id)
            ->get()
            ->keyBy('student_id');

        return Inertia::render('Tasks/Show', [
            'task' => $task,
            'students' => $students,
            'scores' => $scores,
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
