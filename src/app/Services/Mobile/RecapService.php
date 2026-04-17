<?php

namespace App\Services\Mobile;

use App\Models\Attendance;
use App\Models\Grade;
use App\Models\Semester;
use App\Models\TeachingAssignment;

class RecapService
{
    public function attendanceRecap(TeachingAssignment $ta): array
    {
        $semester = $this->getActiveSemester();

        $students = $ta->schoolClass->students()
            ->where('status', 'active')
            ->orderBy('name')
            ->get()
            ->map(function ($student) use ($ta, $semester) {
                $counts = Attendance::where('student_id', $student->id)
                    ->where('class_id', $ta->class_id)
                    ->where('semester_id', $semester->id)
                    ->selectRaw('status, COUNT(*) as total')
                    ->groupBy('status')
                    ->pluck('total', 'status')
                    ->all();

                $hadir = (int) ($counts['hadir'] ?? 0);
                $sakit = (int) ($counts['sakit'] ?? 0);
                $izin = (int) ($counts['izin'] ?? 0);
                $alpha = (int) ($counts['alpha'] ?? 0);
                $total = $hadir + $sakit + $izin + $alpha;
                $percentage = $total > 0 ? round(($hadir / $total) * 100, 2) : 0.0;

                return [
                    'id' => $student->id,
                    'name' => $student->name,
                    'nis' => $student->nis,
                    'hadir' => $hadir,
                    'sakit' => $sakit,
                    'izin' => $izin,
                    'alpha' => $alpha,
                    'total' => $total,
                    'percentage' => $percentage,
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

    public function gradeRecap(TeachingAssignment $ta): array
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

    private function getActiveSemester(): Semester
    {
        $semester = Semester::where('is_active', true)->first();
        if (! $semester) {
            throw new \RuntimeException('Tidak ada semester aktif. Hubungi admin untuk mengaktifkan semester.');
        }
        return $semester;
    }
}
