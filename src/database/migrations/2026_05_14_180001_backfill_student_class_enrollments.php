<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $activeSemester = DB::table('semesters')->where('is_active', true)->first();
        if (! $activeSemester) {
            return;
        }

        DB::table('students')
            ->where('status', 'active')
            ->whereNotNull('class_id')
            ->orderBy('id')
            ->chunkById(500, function ($students) use ($activeSemester) {
                $rows = [];
                $now = now();
                foreach ($students as $s) {
                    $rows[] = [
                        'student_id'  => $s->id,
                        'semester_id' => $activeSemester->id,
                        'class_id'    => $s->class_id,
                        'status'      => 'active',
                        'created_at'  => $now,
                        'updated_at'  => $now,
                    ];
                }
                if (! empty($rows)) {
                    DB::table('student_class_enrollments')->insertOrIgnore($rows);
                }
            });
    }

    public function down(): void
    {
        // Non-destructive: do not delete enrollments on rollback.
    }
};
