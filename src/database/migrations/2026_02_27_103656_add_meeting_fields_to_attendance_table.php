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
        Schema::table('attendance', function (Blueprint $table) {
            $table->foreignId('class_id')->nullable()->constrained('classes')->cascadeOnDelete();
            $table->foreignId('subject_id')->nullable()->constrained('subjects')->nullOnDelete();
            $table->foreignId('semester_id')->nullable()->constrained('semesters')->cascadeOnDelete();
            $table->foreignId('recorded_by')->nullable()->constrained('teachers')->nullOnDelete();
            $table->integer('meeting_number')->default(1);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('attendance', function (Blueprint $table) {
            $table->dropForeign(['class_id']);
            $table->dropForeign(['subject_id']);
            $table->dropForeign(['semester_id']);
            $table->dropForeign(['recorded_by']);
            
            $table->dropColumn(['class_id', 'subject_id', 'semester_id', 'recorded_by', 'meeting_number']);
        });
    }
};
