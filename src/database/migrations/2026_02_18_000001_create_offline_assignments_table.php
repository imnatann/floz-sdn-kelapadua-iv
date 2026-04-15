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
        Schema::create('offline_assignments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('teacher_id')->constrained('teachers')->cascadeOnDelete();
            $table->foreignId('subject_id')->constrained('subjects')->cascadeOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->dateTime('due_date');
            $table->string('status')->default('active'); // active, inactive
            $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $table->timestamps();
        });

        Schema::create('offline_assignment_classes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('offline_assignment_id')->constrained('offline_assignments')->cascadeOnDelete();
            $table->foreignId('class_id')->constrained('classes')->cascadeOnDelete();
            $table->timestamps();
            
            $table->unique(['offline_assignment_id', 'class_id'], 'oa_classes_unique');
        });

        Schema::create('offline_assignment_files', function (Blueprint $table) {
            $table->id();
            $table->foreignId('offline_assignment_id')->constrained('offline_assignments')->cascadeOnDelete();
            $table->string('file_path');
            $table->string('file_name');
            $table->string('file_type');
            $table->bigInteger('file_size');
            $table->timestamps();
        });

        Schema::create('offline_assignment_submissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('offline_assignment_id')->constrained('offline_assignments')->cascadeOnDelete();
            $table->foreignId('student_id')->constrained('students')->cascadeOnDelete();
            $table->dateTime('submitted_at')->nullable();
            
            $table->decimal('grade', 5, 2)->nullable();
            $table->text('correction_note')->nullable();
            $table->string('correction_file')->nullable(); // Path to correction file form teacher
            
            $table->text('answer_text')->nullable();
            $table->string('answer_link')->nullable();
            
            $table->timestamps();

            $table->unique(['offline_assignment_id', 'student_id'], 'oa_submissions_unique');
        });

        Schema::create('offline_submission_files', function (Blueprint $table) {
            $table->id();
            $table->foreignId('submission_id')->constrained('offline_assignment_submissions')->cascadeOnDelete();
            $table->string('file_path');
            $table->string('file_name');
            $table->string('file_type');
            $table->bigInteger('file_size');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('offline_submission_files');
        Schema::dropIfExists('offline_assignment_submissions');
        Schema::dropIfExists('offline_assignment_files');
        Schema::dropIfExists('offline_assignment_classes');
        Schema::dropIfExists('offline_assignments');
    }
};
