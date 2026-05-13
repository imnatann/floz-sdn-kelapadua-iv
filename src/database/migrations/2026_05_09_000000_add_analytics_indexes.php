<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('attendance', function (Blueprint $table) {
            $table->index(['student_id', 'semester_id'], 'attendance_student_semester_idx');
        });
        Schema::table('task_scores', function (Blueprint $table) {
            $table->index('student_id', 'task_scores_student_idx');
        });
        Schema::table('exam_scores', function (Blueprint $table) {
            $table->index('student_id', 'exam_scores_student_idx');
        });
        Schema::table('exams', function (Blueprint $table) {
            $table->index(['class_id', 'semester_id', 'exam_type'], 'exams_class_semester_type_idx');
        });
        Schema::table('tasks', function (Blueprint $table) {
            $table->index(['class_id', 'semester_id'], 'tasks_class_semester_idx');
        });
    }

    public function down(): void
    {
        Schema::table('attendance',  fn ($t) => $t->dropIndex('attendance_student_semester_idx'));
        Schema::table('task_scores', fn ($t) => $t->dropIndex('task_scores_student_idx'));
        Schema::table('exam_scores', fn ($t) => $t->dropIndex('exam_scores_student_idx'));
        Schema::table('exams',       fn ($t) => $t->dropIndex('exams_class_semester_type_idx'));
        Schema::table('tasks',       fn ($t) => $t->dropIndex('tasks_class_semester_idx'));
    }
};
