<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{

    public function up(): void
    {
        Schema::create('meetings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('teaching_assignment_id')->constrained('teaching_assignments')->cascadeOnDelete();
            $table->unsignedSmallInteger('meeting_number'); // 1-14 = Pertemuan, 15 = UTS, 16 = UAS
            $table->string('title'); // "Pertemuan 1", "Ujian Tengah Semester", etc.
            $table->text('description')->nullable();
            $table->boolean('is_locked')->default(true);
            $table->timestamps();

            $table->unique(['teaching_assignment_id', 'meeting_number'], 'meetings_ta_number_unique');
        });

        Schema::create('meeting_materials', function (Blueprint $table) {
            $table->id();
            $table->foreignId('meeting_id')->constrained('meetings')->cascadeOnDelete();
            $table->string('title');
            $table->string('type')->default('file'); // file, link, text
            $table->text('content')->nullable(); // For text type
            $table->string('file_path')->nullable();
            $table->string('file_name')->nullable();
            $table->bigInteger('file_size')->nullable();
            $table->string('url')->nullable(); // For link type
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('meeting_materials');
        Schema::dropIfExists('meetings');
    }
};
