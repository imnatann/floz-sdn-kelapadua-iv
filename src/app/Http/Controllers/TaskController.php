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
     * Display a listing of classes to choose from.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $query = SchoolClass::where('status', 'active');
        
        if ($user->role === 'teacher' && $user->teacher) {
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

        return Inertia::render('Tenant/Tasks/Index', [
            'classes' => $classes,
        ]);
    }

    /**
     * Display tasks for a specific class.
     */
    public function classIndex(SchoolClass $class)
    {
        $activeSemester = Semester::where('is_active', true)->first();
        
        if (!$activeSemester) {
            return redirect()->back()->with('error', 'Tidak ada semester aktif.');
        }

        $tasks = Task::where('class_id', $class->id)
            ->where('semester_id', $activeSemester->id)
            ->with(['subject', 'teacher'])
            ->withCount('scores')
            ->orderByDesc('task_date')
            ->get();
            
        return Inertia::render('Tenant/Tasks/ClassIndex', [
            'schoolClass' => $class,
            'tasks' => $tasks,
            'studentsCount' => $class->students()->count()
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
        
        if ($user->role === 'teacher' && $user->teacher) {
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

        return Inertia::render('Tenant/Tasks/Create', [
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

        return Inertia::render('Tenant/Tasks/Show', [
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
        $classId = $task->class_id;
        $task->delete();
        
        return redirect()->route('tasks.class', $classId)->with('success', 'Tugas dan nilai-nilainya berhasil dihapus.');
    }
}
