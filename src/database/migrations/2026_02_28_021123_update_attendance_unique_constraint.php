<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // MySQL/MariaDB requires every FK column to have a backing index. The
        // unique index we're about to drop is currently the only index on
        // student_id, so a fresh standalone index has to be created first or
        // the drop fails with "needed in a foreign key constraint".
        Schema::table('attendance', function (Blueprint $table) {
            $table->index('student_id', 'attendance_student_id_idx');
        });

        Schema::table('attendance', function (Blueprint $table) {
            $table->dropUnique(['student_id', 'date']);
            $table->unique(['class_id', 'semester_id', 'meeting_number', 'student_id'], 'attendance_meeting_student_unique');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('attendance', function (Blueprint $table) {
            $table->dropUnique('attendance_meeting_student_unique');
            $table->unique(['student_id', 'date']);
        });

        Schema::table('attendance', function (Blueprint $table) {
            $table->dropIndex('attendance_student_id_idx');
        });
    }
};
