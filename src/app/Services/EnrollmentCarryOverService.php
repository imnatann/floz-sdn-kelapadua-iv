<?php

namespace App\Services;

use App\Models\Semester;
use App\Models\StudentClassEnrollment;
use Illuminate\Support\Facades\DB;

class EnrollmentCarryOverService
{
    /**
     * Return a plan of which students would be carried into `$targetSemesterId`
     * from the previous semester in the same academic year, and which would be
     * skipped (status != active).
     *
     * Shape:
     * [
     *   'source_semester_id' => int|null,
     *   'target_semester_id' => int,
     *   'carry_over' => [ ['student_id' => int, 'name' => string, 'class_id' => int, 'class_name' => string], ... ],
     *   'skipped'    => [ ['student_id' => int, 'name' => string, 'reason' => string], ... ],
     * ]
     */
    public function preview(int $targetSemesterId): array
    {
        $target = Semester::findOrFail($targetSemesterId);

        $source = Semester::where('academic_year_id', $target->academic_year_id)
            ->where('semester_number', '<', $target->semester_number)
            ->orderByDesc('semester_number')
            ->first();

        if (! $source) {
            return [
                'source_semester_id' => null,
                'target_semester_id' => $targetSemesterId,
                'carry_over'         => [],
                'skipped'            => [],
            ];
        }

        $rows = StudentClassEnrollment::where('semester_id', $source->id)
            ->with(['student:id,name', 'schoolClass:id,name'])
            ->get();

        $carry = [];
        $skipped = [];
        foreach ($rows as $r) {
            if ($r->status === StudentClassEnrollment::STATUS_ACTIVE) {
                $carry[] = [
                    'student_id' => $r->student_id,
                    'name'       => $r->student->name ?? '—',
                    'class_id'   => $r->class_id,
                    'class_name' => $r->schoolClass->name ?? '—',
                ];
            } else {
                $skipped[] = [
                    'student_id' => $r->student_id,
                    'name'       => $r->student->name ?? '—',
                    'reason'     => "Status di semester sumber: {$r->status}",
                ];
            }
        }

        return [
            'source_semester_id' => $source->id,
            'target_semester_id' => $targetSemesterId,
            'carry_over'         => $carry,
            'skipped'            => $skipped,
        ];
    }

    /**
     * Atomically carry over active enrollments from the previous semester
     * into `$targetSemesterId`. Idempotent: existing rows are not duplicated.
     *
     * @return array{carried:int, skipped:int, source_semester_id:?int, target_semester_id:int}
     */
    public function execute(int $targetSemesterId): array
    {
        return DB::transaction(function () use ($targetSemesterId) {
            $plan = $this->preview($targetSemesterId);

            if ($plan['source_semester_id'] === null || empty($plan['carry_over'])) {
                return [
                    'carried'            => 0,
                    'skipped'            => count($plan['skipped']),
                    'source_semester_id' => $plan['source_semester_id'],
                    'target_semester_id' => $targetSemesterId,
                ];
            }

            $now = now();
            $rows = [];
            foreach ($plan['carry_over'] as $entry) {
                $rows[] = [
                    'student_id'  => $entry['student_id'],
                    'semester_id' => $targetSemesterId,
                    'class_id'    => $entry['class_id'],
                    'status'      => StudentClassEnrollment::STATUS_ACTIVE,
                    'created_at'  => $now,
                    'updated_at'  => $now,
                ];
            }

            $before = StudentClassEnrollment::where('semester_id', $targetSemesterId)->count();
            DB::table('student_class_enrollments')->insertOrIgnore($rows);
            $after = StudentClassEnrollment::where('semester_id', $targetSemesterId)->count();

            return [
                'carried'            => $after - $before,
                'skipped'            => count($plan['skipped']),
                'source_semester_id' => $plan['source_semester_id'],
                'target_semester_id' => $targetSemesterId,
            ];
        });
    }
}
