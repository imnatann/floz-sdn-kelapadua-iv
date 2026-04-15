<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{

    public function up(): void
    {
        // Add type column to offline_assignments
        Schema::table('offline_assignments', function (Blueprint $table) {
            $table->string('type')->default('manual')->after('status'); // manual, quiz
        });

        // Quiz questions
        Schema::create('offline_assignment_questions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('offline_assignment_id')->constrained('offline_assignments')->cascadeOnDelete();
            $table->text('question_text');
            $table->string('question_type')->default('multiple_choice'); // multiple_choice, essay, true_false
            $table->jsonb('options')->nullable(); // For MC: ["Option A", "Option B", "Option C", "Option D"]
            $table->text('correct_answer')->nullable(); // Answer key (null for essay)
            $table->decimal('points', 5, 2)->default(0);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });

        // Quiz answers per student per question
        Schema::create('offline_assignment_answers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('submission_id')->constrained('offline_assignment_submissions')->cascadeOnDelete();
            $table->foreignId('question_id')->constrained('offline_assignment_questions')->cascadeOnDelete();
            $table->text('answer')->nullable();
            $table->boolean('is_correct')->nullable();
            $table->decimal('points_earned', 5, 2)->default(0);
            $table->timestamps();

            $table->unique(['submission_id', 'question_id'], 'oa_answer_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('offline_assignment_answers');
        Schema::dropIfExists('offline_assignment_questions');

        Schema::table('offline_assignments', function (Blueprint $table) {
            $table->dropColumn('type');
        });
    }
};
