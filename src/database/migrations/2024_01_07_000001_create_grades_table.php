<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{

    public function up(): void
    {
        Schema::create('grades', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('students')->onDelete('cascade');
            $table->foreignId('subject_id')->constrained('subjects')->onDelete('cascade');
            $table->foreignId('class_id')->constrained('classes')->onDelete('cascade');
            $table->foreignId('semester_id')->constrained('semesters')->onDelete('cascade');
            $table->foreignId('teacher_id')->nullable()->constrained('teachers')->onDelete('set null');

            // For SD (Elementary)
            $table->decimal('daily_test_avg', 5, 2)->nullable();
            $table->decimal('mid_test', 5, 2)->nullable();
            $table->decimal('final_test', 5, 2)->nullable();

            // For SMP/SMA (Junior/Senior High)
            $table->decimal('knowledge_score', 5, 2)->nullable();
            $table->decimal('skill_score', 5, 2)->nullable();

            // Common
            $table->decimal('final_score', 5, 2)->nullable();
            $table->string('predicate', 2)->nullable();
            $table->text('description')->nullable();
            $table->decimal('attendance_score', 5, 2)->nullable();
            $table->string('attitude_score', 2)->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->unique(['student_id', 'subject_id', 'semester_id']);
            $table->index(['class_id', 'semester_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('grades');
    }
};
