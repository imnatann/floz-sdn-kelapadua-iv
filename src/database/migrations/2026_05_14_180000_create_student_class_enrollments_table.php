<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('student_class_enrollments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('students')->cascadeOnDelete();
            $table->foreignId('semester_id')->constrained('semesters')->restrictOnDelete();
            $table->foreignId('class_id')->constrained('classes')->restrictOnDelete();
            $table->string('status', 20)->default('active');
            $table->date('exit_date')->nullable();
            $table->string('exit_reason', 255)->nullable();
            $table->timestamps();

            $table->unique(['student_id', 'semester_id'], 'sce_student_semester_unique');
            $table->index(['semester_id', 'class_id'], 'sce_semester_class_idx');
            $table->index(['student_id', 'semester_id'], 'sce_student_semester_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('student_class_enrollments');
    }
};
