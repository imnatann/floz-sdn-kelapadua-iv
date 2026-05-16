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
     * into `$targetSemesterId`. Idempotent.
     *
     * @param  array<int,string>  $overrides  Optional map student_id => status. Students with non-active override
     *                                        get their source enrollment closed with that status, no target row.
     *
     * @return array{carried:int, skipped:int, source_semester_id:?int, target_semester_id:int}
     */
    public function execute(int $targetSemesterId, array $overrides = []): array
    {
        return DB::transaction(function () use ($targetSemesterId, $overrides) {
            $plan = $this->preview($targetSemesterId);

            if ($plan['source_semester_id'] === null) {
                return [
                    'carried'            => 0,
                    'skipped'            => count($plan['skipped']),
                    'source_semester_id' => null,
                    'target_semester_id' => $targetSemesterId,
                ];
            }

            $studentStatusMap = [
                'transferred_out' => 'transferred',
                'dropped_out'     => 'dropout',
                'graduated'       => 'graduated',
                'retained_out'    => 'active',
            ];

            $now = now();
            $rowsToCarry = [];
            $exits = [];

            foreach ($plan['carry_over'] as $entry) {
                $override = $overrides[$entry['student_id']] ?? StudentClassEnrollment::STATUS_ACTIVE;
                if ($override === StudentClassEnrollment::STATUS_ACTIVE) {
                    $rowsToCarry[] = [
                        'student_id'  => $entry['student_id'],
                        'semester_id' => $targetSemesterId,
                        'class_id'    => $entry['class_id'],
                        'status'      => StudentClassEnrollment::STATUS_ACTIVE,
                        'created_at'  => $now,
                        'updated_at'  => $now,
                    ];
                } else {
                    $exits[$entry['student_id']] = $override;
                }
            }

            foreach ($exits as $studentId => $exitStatus) {
                StudentClassEnrollment::where('student_id', $studentId)
                    ->where('semester_id', $plan['source_semester_id'])
                    ->update([
                        'status'      => $exitStatus,
                        'exit_date'   => $now->toDateString(),
                        'exit_reason' => 'Set during semester transition',
                    ]);
                if (isset($studentStatusMap[$exitStatus]) && $studentStatusMap[$exitStatus] !== 'active') {
                    \App\Models\Student::where('id', $studentId)->update(['status' => $studentStatusMap[$exitStatus]]);
                }
            }

            $before = StudentClassEnrollment::where('semester_id', $targetSemesterId)->count();
            if (! empty($rowsToCarry)) {
                DB::table('student_class_enrollments')->insertOrIgnore($rowsToCarry);
            }
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
