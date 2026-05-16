<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $statusMap = [
            'promotion'    => 'promoted_out',
            'retention'    => 'retained_out',
            'graduated'    => 'graduated',
            'transfer_out' => 'transferred_out',
            'dropout'      => 'dropped_out',
        ];

        $now = now();
        $rows = [];

        $mutations = DB::table('student_mutations')
            ->whereIn('type', array_keys($statusMap))
            ->get();

        foreach ($mutations as $m) {
            $sourceClass = $m->from_class_id ? DB::table('classes')->find($m->from_class_id) : null;
            $targetClass = $m->to_class_id ? DB::table('classes')->find($m->to_class_id) : null;

            // Source enrollment — closed
            if ($sourceClass) {
                $sourceSem2 = DB::table('semesters')
                    ->where('academic_year_id', $sourceClass->academic_year_id)
                    ->orderByDesc('semester_number')
                    ->first();
                if ($sourceSem2) {
                    $rows[] = [
                        'student_id'  => $m->student_id,
                        'semester_id' => $sourceSem2->id,
                        'class_id'    => $m->from_class_id,
                        'status'      => $statusMap[$m->type],
                        'exit_date'   => $m->date,
                        'exit_reason' => 'Backfilled from year transition',
                        'created_at'  => $now,
                        'updated_at'  => $now,
                    ];
                }
            }

            // Target enrollment — active in Sem 1 of target AY
            if ($targetClass && in_array($m->type, ['promotion', 'retention'])) {
                $targetSem1 = DB::table('semesters')
                    ->where('academic_year_id', $targetClass->academic_year_id)
                    ->where('semester_number', 1)
                    ->first();
                if ($targetSem1) {
                    $rows[] = [
                        'student_id'  => $m->student_id,
                        'semester_id' => $targetSem1->id,
                        'class_id'    => $m->to_class_id,
                        'status'      => 'active',
                        'exit_date'   => null,
                        'exit_reason' => null,
                        'created_at'  => $now,
                        'updated_at'  => $now,
                    ];
                }
            }
        }

        if (! empty($rows)) {
            DB::table('student_class_enrollments')->insertOrIgnore($rows);
        }
    }

    public function down(): void
    {
        // Non-destructive
    }
};
