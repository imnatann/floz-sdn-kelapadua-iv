<?php

namespace App\Services;

use App\Models\Grade;
use App\Models\ReportCard;
use App\Models\Attendance;
use App\Models\Subject;
use Illuminate\Support\Facades\DB;

class ReportCardService
{
    /**
     * Generate or update a report card for a student.
     * Takes in report_type: 'uts' or 'final'
     */
    public function generate(int $studentId, int $classId, int $semesterId, string $reportType = 'final'): ReportCard
    {
        // 1. Calculate and save grades per subject
        $subjects = Subject::where('status', 'active')->get();
        
        foreach ($subjects as $subject) {
            $this->calculateSubjectGrade($studentId, $classId, $semesterId, $subject->id, $reportType);
        }

        // 2. Refresh grades to calculate total report card score
        $grades = Grade::where('student_id', $studentId)
            ->where('class_id', $classId)
            ->where('semester_id', $semesterId)
            ->get();

        $totalScore = $grades->sum('final_score');
        $averageScore = $grades->count() > 0 ? round($totalScore / $grades->count(), 2) : 0;

        // 3. Calculate attendance summary
        $attendance = $this->calculateAttendance($studentId, $classId, $semesterId);

        // 4. Save Report Card
        return ReportCard::updateOrCreate(
            [
                'student_id'  => $studentId,
                'semester_id' => $semesterId,
                'report_type' => $reportType,
            ],
            [
                'class_id'           => $classId,
                'total_score'        => $totalScore,
                'average_score'      => $averageScore,
                'attendance_present' => $attendance['present'],
                'attendance_sick'    => $attendance['sick'],
                'attendance_permit'  => $attendance['permit'],
                'attendance_absent'  => $attendance['absent'],
                'status'             => 'draft',
                'extracurricular'    => [], // Initialize empty extracurriculars
            ]
        );
    }

    protected function calculateSubjectGrade(int $studentId, int $classId, int $semesterId, int $subjectId, string $reportType)
    {
        // Formative Average = Average of Task Scores + Ulangan Harian Scores
        $taskScoresAvg = DB::table('task_scores')
            ->join('tasks', 'task_scores.task_id', '=', 'tasks.id')
            ->where('tasks.class_id', $classId)
            ->where('tasks.semester_id', $semesterId)
            ->where('tasks.subject_id', $subjectId)
            ->where('task_scores.student_id', $studentId)
            ->avg('task_scores.score') ?? 0;

        $ulanganScoresAvg = DB::table('exam_scores')
            ->join('exams', 'exam_scores.exam_id', '=', 'exams.id')
            ->where('exams.class_id', $classId)
            ->where('exams.semester_id', $semesterId)
            ->where('exams.subject_id', $subjectId)
            ->where('exams.exam_type', 'ulangan_harian')
            ->where('exam_scores.student_id', $studentId)
            ->avg('exam_scores.score') ?? 0;

        // Combine task and ulangan into one formative average
        $formativeDivisor = ($taskScoresAvg > 0 && $ulanganScoresAvg > 0) ? 2 : 1;
        $dailyTestAvg = ($taskScoresAvg + $ulanganScoresAvg) === 0 ? 0 : round(($taskScoresAvg + $ulanganScoresAvg) / $formativeDivisor, 2);

        // UTS Score
        $utsScoreStr = DB::table('exam_scores')
            ->join('exams', 'exam_scores.exam_id', '=', 'exams.id')
            ->where('exams.class_id', $classId)
            ->where('exams.semester_id', $semesterId)
            ->where('exams.subject_id', $subjectId)
            ->where('exams.exam_type', 'uts')
            ->where('exam_scores.student_id', $studentId)
            ->avg('exam_scores.score');
        $midTest = $utsScoreStr ? round((float)$utsScoreStr, 2) : 0;

        // UAS Score
        $uasScoreStr = DB::table('exam_scores')
            ->join('exams', 'exam_scores.exam_id', '=', 'exams.id')
            ->where('exams.class_id', $classId)
            ->where('exams.semester_id', $semesterId)
            ->where('exams.subject_id', $subjectId)
            ->where('exams.exam_type', 'uas')
            ->where('exam_scores.student_id', $studentId)
            ->avg('exam_scores.score');
        $finalTest = $uasScoreStr ? round((float)$uasScoreStr, 2) : 0;

        // Calculate Final Grade based on report type
        $finalScore = 0;
        if ($reportType === 'uts') {
            // Formula for UTS: (Formative + UTS) / 2
            $finalScore = round(($dailyTestAvg + $midTest) / 2, 2);
        } else {
            // Formula for Final: (Formative + UTS + UAS) / 3
            // In Kurikulum Merdeka it's often more balanced, e.g Formative has more weight. 
            // We use simple average for MVP.
            $finalScore = round(($dailyTestAvg + $midTest + $finalTest) / 3, 2);
        }

        Grade::updateOrCreate(
            [
                'student_id'  => $studentId,
                'subject_id'  => $subjectId,
                'class_id'    => $classId,
                'semester_id' => $semesterId,
            ],
            [
                'daily_test_avg' => $dailyTestAvg,
                'mid_test'       => $midTest,
                'final_test'     => $finalTest,
                'final_score'    => $finalScore,
                'teacher_id'     => null, // Optional tracking
            ]
        );
    }

    /**
     * Calculate class rankings for a semester.
     */
    public function calculateRankings(int $classId, int $semesterId, string $reportType): void
    {
        $reportCards = ReportCard::where('class_id', $classId)
            ->where('semester_id', $semesterId)
            ->where('report_type', $reportType)
            ->orderByDesc('average_score')
            ->get();

        $rank = 1;
        foreach ($reportCards as $reportCard) {
            $reportCard->update(['rank' => $rank]);
            $rank++;
        }
    }

    /**
     * Publish a report card.
     */
    public function publish(ReportCard $reportCard): void
    {
        $reportCard->update([
            'status'       => 'published',
            'published_at' => now(),
        ]);
    }

    /**
     * Calculate attendance summary for a student in a semester.
     * With new MVP attendance structure: 'class_id', 'semester_id', and presence in 'meeting_number'.
     * Since MVP uses simple present/absent matrix, let's tally based on `attendance` table.
     */
    protected function calculateAttendance(int $studentId, int $classId, int $semesterId): array
    {
        $attendances = Attendance::where('student_id', $studentId)
            ->where('class_id', $classId)
            ->where('semester_id', $semesterId)
            ->get();

        return [
            'present' => $attendances->where('status', 'present')->count(),
            'sick'    => $attendances->where('status', 'sick')->count(),
            'permit'  => $attendances->where('status', 'permit')->count(),
            'absent'  => $attendances->where('status', 'absent')->count(),
        ];
    }
}
