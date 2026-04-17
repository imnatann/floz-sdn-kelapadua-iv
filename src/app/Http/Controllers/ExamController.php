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

        return Inertia::render('Tenant/Exams/Index', [
            'classes' => $classes,
        ]);
    }

    /**
     * Display exams for a specific class.
     */
    public function classIndex(SchoolClass $class)
    {
        $activeSemester = Semester::where('is_active', true)->first();
        
        if (!$activeSemester) {
            return redirect()->back()->with('error', 'Tidak ada semester aktif.');
        }

        $exams = Exam::where('class_id', $class->id)
            ->where('semester_id', $activeSemester->id)
            ->with(['subject', 'teacher'])
            ->withCount([
                'scores',
                'scores as kumpul_count' => fn ($q) => $q->where('submission_status', ExamScore::STATUS_KUMPUL),
                'scores as terlambat_count' => fn ($q) => $q->where('submission_status', ExamScore::STATUS_TERLAMBAT),
                'scores as tidak_kumpul_count' => fn ($q) => $q->where('submission_status', ExamScore::STATUS_TIDAK_KUMPUL),
            ])
            ->orderByDesc('exam_date')
            ->get();
            
        return Inertia::render('Tenant/Exams/ClassIndex', [
            'schoolClass' => $class,
            'exams' => $exams,
            'studentsCount' => $class->students()->count()
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

        return Inertia::render('Tenant/Exams/Create', [
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
     * This is the main interface for inputting grades.
     */
    public function show(Exam $exam)
    {
        $exam->load(['schoolClass', 'subject', 'semester', 'teacher']);
        
        $students = Student::where('class_id', $exam->class_id)
            ->where('status', 'active')
            ->orderBy('name')
            ->get();
            
        $scores = ExamScore::where('exam_id', $exam->id)
            ->get()
            ->keyBy('student_id');

        return Inertia::render('Tenant/Exams/Show', [
            'exam' => $exam,
            'students' => $students,
            'scores' => $scores,
        ]);
    }

    /**
     * Store all student scores for an exam.
     */
    public function storeScores(Request $request, Exam $exam)
    {
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
        $classId = $exam->class_id;
        $exam->delete();
        
        return redirect()->route('exams.class', $classId)->with('success', 'Ujian dan nilai-nilainya berhasil dihapus.');
    }
}
