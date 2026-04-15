<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{

    public function up(): void
    {
        Schema::create('report_cards', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('students')->onDelete('cascade');
            $table->foreignId('class_id')->constrained('classes')->onDelete('cascade');
            $table->foreignId('semester_id')->constrained('semesters')->onDelete('cascade');
            $table->integer('rank')->nullable();
            $table->decimal('total_score', 7, 2)->nullable();
            $table->decimal('average_score', 5, 2)->nullable();
            $table->integer('attendance_present')->default(0);
            $table->integer('attendance_sick')->default(0);
            $table->integer('attendance_permit')->default(0);
            $table->integer('attendance_absent')->default(0);
            $table->text('achievements')->nullable();
            $table->text('notes')->nullable();
            $table->text('behavior_notes')->nullable();
            $table->text('homeroom_comment')->nullable();
            $table->text('principal_comment')->nullable();
            $table->string('status', 20)->default('draft');
            $table->timestamp('published_at')->nullable();
            $table->string('pdf_url')->nullable();
            $table->timestamps();

            $table->unique(['student_id', 'semester_id']);
            $table->index(['class_id', 'semester_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('report_cards');
    }
};
