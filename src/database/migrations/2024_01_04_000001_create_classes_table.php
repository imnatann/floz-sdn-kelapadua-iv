<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{

    public function up(): void
    {
        Schema::create('classes', function (Blueprint $table) {
            $table->id();
            $table->string('name', 50);                // e.g., "7A", "X IPA 1"
            $table->integer('grade_level');             // 1-12
            $table->foreignId('academic_year_id')->constrained('academic_years')->onDelete('cascade');
            $table->foreignId('homeroom_teacher_id')->nullable()->constrained('teachers')->onDelete('set null');
            $table->integer('max_students')->default(40);
            $table->string('status', 20)->default('active');
            $table->timestamps();

            $table->index(['academic_year_id', 'grade_level']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('classes');
    }
};
