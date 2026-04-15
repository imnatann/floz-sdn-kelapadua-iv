<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{

    public function up(): void
    {
        Schema::create('students', function (Blueprint $table) {
            $table->id();
            $table->string('nis', 20)->unique();
            $table->string('nisn', 20)->unique()->nullable();
            $table->string('name');
            $table->string('gender', 10)->nullable();
            $table->string('birth_place', 100)->nullable();
            $table->date('birth_date')->nullable();
            $table->string('religion', 20)->nullable();
            $table->text('address')->nullable();
            $table->string('parent_name')->nullable();
            $table->string('parent_phone', 20)->nullable();
            $table->string('email')->nullable();
            $table->foreignId('class_id')->nullable()->constrained('classes')->onDelete('set null');
            $table->string('status', 20)->default('active');
            $table->string('photo_url')->nullable();
            $table->timestamps();

            $table->index('status');
            $table->index('class_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('students');
    }
};
