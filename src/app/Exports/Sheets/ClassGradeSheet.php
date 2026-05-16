<?php

namespace App\Exports\Sheets;

use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\Subject;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class ClassGradeSheet implements FromCollection, WithHeadings, WithTitle, WithStyles
{
    private Collection $tasks;
    private Collection $ulanganHarianExams;

    public function __construct(
        private readonly SchoolClass $class,
        private readonly Semester $semester,
        private readonly Subject $subject,
    ) {
        // Load tasks for this class + semester + subject, ordered by created_at for stable columns
        $this->tasks = DB::table('tasks')
            ->where('class_id', $this->class->id)
            ->where('semester_id', $this->semester->id)
            ->where('subject_id', $this->subject->id)
            ->orderBy('created_at')
            ->orderBy('id')
            ->get(['id', 'title']);

        // Load ulangan_harian exams ordered by exam_date ASC, id ASC
        $this->ulanganHarianExams = DB::table('exams')
            ->where('class_id', $this->class->id)
            ->where('semester_id', $this->semester->id)
            ->where('subject_id', $this->subject->id)
            ->where('exam_type', 'ulangan_harian')
            ->orderBy('exam_date')
            ->orderBy('id')
            ->get(['id']);
    }

    public function title(): string
    {
        // Sheet tab: "SubjectName - ClassName" truncated to 31 chars
        $tab = substr($this->subject->name, 0, 15) . ' - ' . substr($this->class->name, 0, 13);
        return substr($tab, 0, 31);
    }

    public function headings(): array
    {
        $headers = ['No', 'NIS', 'Nama Siswa'];

        foreach ($this->tasks as $i => $task) {
            $headers[] = 'Nilai Tugas ' . ($i + 1);
        }

        foreach ($this->ulanganHarianExams as $i => $exam) {
            $headers[] = 'UH ' . ($i + 1);
        }

        $headers[] = 'UTS';
        $headers[] = 'UAS';
        $headers[] = 'Nilai Akhir';
        $headers[] = 'Predikat';

        return $headers;
    }

    public function collection(): Collection
    {
        $students = Student::where('class_id', $this->class->id)
            ->where('status', 'active')
            ->orderBy('name')
            ->get(['id', 'nis', 'name']);

        // Pre-load all task scores for efficiency
        $taskIds = $this->tasks->pluck('id')->all();
        $taskScoreMap = [];
        if (!empty($taskIds)) {
            DB::table('task_scores')
                ->whereIn('task_id', $taskIds)
                ->whereIn('student_id', $students->pluck('id')->all())
                ->get(['task_id', 'student_id', 'score'])
                ->each(function ($row) use (&$taskScoreMap) {
                    $taskScoreMap[$row->student_id][$row->task_id] = $row->score;
                });
        }

        // Pre-load ulangan_harian scores (per exam, per student)
        $uhExamIds = $this->ulanganHarianExams->pluck('id')->all();
        $uhScoreMap = []; // [student_id][exam_id] = score
        if (!empty($uhExamIds)) {
            DB::table('exam_scores')
                ->whereIn('exam_id', $uhExamIds)
                ->whereIn('student_id', $students->pluck('id')->all())
                ->get(['exam_id', 'student_id', 'score'])
                ->each(function ($row) use (&$uhScoreMap) {
                    $uhScoreMap[$row->student_id][$row->exam_id] = (float) $row->score;
                });
        }

        // Pre-load UTS scores
        $utsScoreMap = [];
        DB::table('exam_scores')
            ->join('exams', 'exam_scores.exam_id', '=', 'exams.id')
            ->where('exams.class_id', $this->class->id)
            ->where('exams.semester_id', $this->semester->id)
            ->where('exams.subject_id', $this->subject->id)
            ->where('exams.exam_type', 'uts')
            ->whereIn('exam_scores.student_id', $students->pluck('id')->all())
            ->selectRaw('exam_scores.student_id, AVG(exam_scores.score) as avg_score')
            ->groupBy('exam_scores.student_id')
            ->get()
            ->each(function ($row) use (&$utsScoreMap) {
                $utsScoreMap[$row->student_id] = round((float) $row->avg_score, 2);
            });

        // Pre-load UAS scores
        $uasScoreMap = [];
        DB::table('exam_scores')
            ->join('exams', 'exam_scores.exam_id', '=', 'exams.id')
            ->where('exams.class_id', $this->class->id)
            ->where('exams.semester_id', $this->semester->id)
            ->where('exams.subject_id', $this->subject->id)
            ->where('exams.exam_type', 'uas')
            ->whereIn('exam_scores.student_id', $students->pluck('id')->all())
            ->selectRaw('exam_scores.student_id, AVG(exam_scores.score) as avg_score')
            ->groupBy('exam_scores.student_id')
            ->get()
            ->each(function ($row) use (&$uasScoreMap) {
                $uasScoreMap[$row->student_id] = round((float) $row->avg_score, 2);
            });

        return $students->map(function ($student, $idx) use ($taskScoreMap, $uhScoreMap, $utsScoreMap, $uasScoreMap) {
            $row = [$idx + 1, $student->nis, $student->name];

            $taskScores = [];
            foreach ($this->tasks as $task) {
                $score       = $taskScoreMap[$student->id][$task->id] ?? null;
                $taskScores[] = $score;
                $row[]        = $score;
            }

            $uhScores = [];
            foreach ($this->ulanganHarianExams as $exam) {
                $score     = $uhScoreMap[$student->id][$exam->id] ?? null;
                $uhScores[] = $score;
                $row[]      = $score;
            }

            $uts = $utsScoreMap[$student->id] ?? null;
            $uas = $uasScoreMap[$student->id] ?? null;

            $row[] = $uts;
            $row[] = $uas;

            // taskAvg = average of task scores (non-null)
            $nonNullTasks = array_filter($taskScores, fn($s) => $s !== null);
            $taskAvg      = count($nonNullTasks) > 0
                ? array_sum($nonNullTasks) / count($nonNullTasks)
                : 0;

            // uhAvg = average of ulangan_harian scores (non-null)
            $nonNullUh = array_filter($uhScores, fn($s) => $s !== null);
            $uhAvg     = count($nonNullUh) > 0
                ? array_sum($nonNullUh) / count($nonNullUh)
                : 0;

            // formative = avg(taskAvg, uhAvg) for non-zero components
            $formativeComponents = array_filter([$taskAvg > 0 ? $taskAvg : null, $uhAvg > 0 ? $uhAvg : null], fn($s) => $s !== null);
            $formative = count($formativeComponents) > 0
                ? array_sum($formativeComponents) / count($formativeComponents)
                : 0;

            $scores   = array_filter([$formative > 0 ? $formative : null, $uts, $uas], fn($s) => $s !== null);
            $divisor  = count($scores);
            $final    = $divisor > 0 ? round(array_sum($scores) / $divisor, 2) : 0;

            $row[] = $final;
            $row[] = self::predikat($final);

            return $row;
        });
    }

    public static function predikat(float $score): string
    {
        if ($score >= 90) return 'A';
        if ($score >= 75) return 'B';
        if ($score >= 60) return 'C';
        return 'D';
    }

    public function styles(Worksheet $sheet): array
    {
        return [
            1 => ['font' => ['bold' => true]],
        ];
    }
}
