<?php

namespace App\Services\Mobile;

use App\Models\Grade;
use App\Models\Subject;
use App\Models\User;

class GradeService
{
    public function listForStudent(User $user): array
    {
        $student = $user->student;
        if (! $student) {
            return [];
        }

        return Grade::where('student_id', $student->id)
            ->with('subject')
            ->get()
            ->groupBy('subject_id')
            ->map(function ($subjectGrades, $subjectId) {
                $subject = $subjectGrades->first()->subject;
                $avg = round($subjectGrades->avg('final_score'), 1);

                return [
                    'subject_id' => (int) $subjectId,
                    'subject_name' => $subject->name ?? '-',
                    'average' => (float) $avg,
                    'grade_count' => $subjectGrades->count(),
                    'kkm' => (float) ($subject->kkm ?? 75),
                ];
            })
            ->values()
            ->all();
    }

    public function detailForStudent(User $user, int $subjectId): array
    {
        $student = $user->student;
        $subject = Subject::find($subjectId);

        $grades = [];
        if ($student) {
            $grades = Grade::where('student_id', $student->id)
                ->where('subject_id', $subjectId)
                ->with('semester')
                ->get()
                ->map(fn (Grade $g) => [
                    'id' => $g->id,
                    'daily_test_avg' => (float) ($g->daily_test_avg ?? 0),
                    'mid_test' => (float) ($g->mid_test ?? 0),
                    'final_test' => (float) ($g->final_test ?? 0),
                    'knowledge_score' => $g->knowledge_score ? (float) $g->knowledge_score : null,
                    'skill_score' => $g->skill_score ? (float) $g->skill_score : null,
                    'final_score' => (float) ($g->final_score ?? 0),
                    'predicate' => $g->predicate ?? '-',
                    'semester' => $g->semester?->name ?? 'Semester ' . $g->semester_id,
                    'notes' => $g->notes,
                    'created_at' => $g->created_at?->toIso8601String(),
                ])
                ->all();
        }

        return [
            'subject' => [
                'id' => $subject?->id,
                'name' => $subject?->name ?? '-',
                'kkm' => (float) ($subject?->kkm ?? 75),
            ],
            'grades' => $grades,
        ];
    }
}
