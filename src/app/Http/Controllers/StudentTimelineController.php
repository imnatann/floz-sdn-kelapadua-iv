<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\Exam;
use App\Models\ExamScore;
use App\Models\ReportCard;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\Task;
use App\Models\TaskScore;
use Illuminate\Support\Facades\Gate;
use Inertia\Inertia;

class StudentTimelineController extends Controller
{
    public function show(Student $student, Semester $semester)
    {
        Gate::authorize('view', $student);

        $enrollment = StudentClassEnrollment::with('schoolClass')
            ->where('student_id', $student->id)
            ->where('semester_id', $semester->id)
            ->first();

        $classId = $enrollment?->class_id;

        $tasks = Task::query()
            ->where('semester_id', $semester->id)
            ->when($classId, fn($q) => $q->where('class_id', $classId))
            ->with('subject:id,name')
            ->orderBy('task_date')
            ->get()
            ->map(function ($task) use ($student) {
                $score = TaskScore::where('task_id', $task->id)
                    ->where('student_id', $student->id)
                    ->first();
                return [
                    'id'                => $task->id,
                    'title'             => $task->title,
                    'task_date'         => $task->task_date,
                    'subject'           => $task->subject,
                    'max_score'         => $task->max_score,
                    'student_score'     => $score?->score,
                    'submission_status' => $score?->submission_status,
                ];
            });

        $exams = Exam::query()
            ->where('semester_id', $semester->id)
            ->when($classId, fn($q) => $q->where('class_id', $classId))
            ->with('subject:id,name')
            ->orderBy('exam_date')
            ->get()
            ->map(function ($exam) use ($student) {
                $score = ExamScore::where('exam_id', $exam->id)
                    ->where('student_id', $student->id)
                    ->first();
                return [
                    'id'            => $exam->id,
                    'title'         => $exam->title,
                    'exam_type'     => $exam->exam_type,
                    'exam_date'     => $exam->exam_date,
                    'subject'       => $exam->subject,
                    'max_score'     => $exam->max_score,
                    'student_score' => $score?->score,
                ];
            });

        $attendanceSummary = Attendance::where('student_id', $student->id)
            ->where('semester_id', $semester->id)
            ->when($classId, fn($q) => $q->where('class_id', $classId))
            ->selectRaw('status, COUNT(*) as n')
            ->groupBy('status')
            ->pluck('n', 'status');

        $reportCard = ReportCard::where('student_id', $student->id)
            ->where('semester_id', $semester->id)
            ->first();

        $semester->load('academicYear');

        return Inertia::render('Students/Timeline', [
            'student'           => $student->only(['id', 'nis', 'name', 'status']),
            'semester'          => array_merge(
                $semester->only(['id', 'semester_number', 'start_date', 'end_date']),
                ['academic_year' => $semester->academicYear?->only(['id', 'name'])]
            ),
            'enrollment'        => $enrollment ? array_merge(
                $enrollment->only(['id', 'class_id', 'status', 'exit_date', 'exit_reason']),
                ['school_class' => $enrollment->schoolClass?->only(['id', 'name', 'grade_level'])]
            ) : null,
            'tasks'             => $tasks,
            'exams'             => $exams,
            'attendanceSummary' => $attendanceSummary,
            'reportCard'        => $reportCard?->only(['id', 'rank', 'total_score', 'average_score', 'status']),
        ]);
    }
}
