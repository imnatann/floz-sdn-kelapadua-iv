<?php

namespace App\Services\Mobile;

use App\Models\Grade;
use App\Models\Semester;
use App\Models\TeachingAssignment;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class GradingService
{
    public function getRoster(TeachingAssignment $ta, User $user): array
    {
        $semester = $this->getActiveSemester();

        $students = $ta->schoolClass->students()
            ->where('status', 'active')
            ->orderBy('name')
            ->get()
            ->map(function ($student) use ($ta, $semester) {
                $grade = Grade::where('student_id', $student->id)
                    ->where('subject_id', $ta->subject_id)
                    ->where('semester_id', $semester->id)
                    ->first();

                return [
                    'id' => $student->id,
                    'name' => $student->name,
                    'nis' => $student->nis,
                    'daily_test_avg' => $grade?->daily_test_avg !== null ? (float) $grade->daily_test_avg : null,
                    'mid_test' => $grade?->mid_test !== null ? (float) $grade->mid_test : null,
                    'final_test' => $grade?->final_test !== null ? (float) $grade->final_test : null,
                    'final_score' => $grade?->final_score !== null ? (float) $grade->final_score : null,
                    'predicate' => $grade?->predicate,
                ];
            })
            ->values()
            ->all();

        return [
            'teaching_assignment' => [
                'id' => $ta->id,
                'subject_name' => $ta->subject->name ?? '-',
                'class_name' => $ta->schoolClass->name ?? '-',
            ],
            'students' => $students,
        ];
    }

    public function storeGrades(TeachingAssignment $ta, array $entries, User $user): array
    {
        $semester = $this->getActiveSemester();
        $teacher = $user->teacher;

        DB::transaction(function () use ($entries, $ta, $semester, $teacher) {
            foreach ($entries as $entry) {
                $daily = $entry['daily_test_avg'] ?? null;
                $mid = $entry['mid_test'] ?? null;
                $final = $entry['final_test'] ?? null;

                // Auto-calculate final_score only when all 3 are present
                $finalScore = null;
                $predicate = null;
                if ($daily !== null && $mid !== null && $final !== null) {
                    $finalScore = round(($daily * 0.3) + ($mid * 0.3) + ($final * 0.4), 2);
                    $predicate = match (true) {
                        $finalScore >= 90 => 'A',
                        $finalScore >= 80 => 'B',
                        $finalScore >= 70 => 'C',
                        default => 'D',
                    };
                }

                Grade::updateOrCreate(
                    [
                        'student_id' => $entry['student_id'],
                        'subject_id' => $ta->subject_id,
                        'semester_id' => $semester->id,
                    ],
                    [
                        'class_id' => $ta->class_id,
                        'teacher_id' => $teacher?->id,
                        'daily_test_avg' => $daily,
                        'mid_test' => $mid,
                        'final_test' => $final,
                        'final_score' => $finalScore,
                        'predicate' => $predicate,
                    ]
                );
            }
        });

        return $this->getRoster($ta, $user);
    }

    private function getActiveSemester(): Semester
    {
        $semester = Semester::where('is_active', true)->first();
        if (! $semester) {
            throw new \RuntimeException('Tidak ada semester aktif. Hubungi admin untuk mengaktifkan semester.');
        }
        return $semester;
    }
}
