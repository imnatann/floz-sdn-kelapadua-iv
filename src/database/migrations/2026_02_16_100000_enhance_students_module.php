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
        // 1. Enhance Students Table
        Schema::table('students', function (Blueprint $table) {
            $table->string('family_card_number')->nullable()->after('parent_phone'); // No. KK
            $table->string('nik')->nullable()->unique()->after('nisn'); // NIK
        });

        // 2. Student Mutations (Lifecycle)
        Schema::create('student_mutations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained()->cascadeOnDelete();
            $table->string('type'); // promotion, retention, transfer_in, transfer_out, dropout, graduated
            $table->foreignId('from_class_id')->nullable()->constrained('classes')->nullOnDelete();
            $table->foreignId('to_class_id')->nullable()->constrained('classes')->nullOnDelete();
            $table->date('date');
            $table->string('reason')->nullable(); // e.g., "Pindah ikut orang tua"
            $table->string('reference_number')->nullable(); // SK Number
            $table->text('notes')->nullable();
            $table->timestamps();
        });

        // 3. Health Records
        Schema::create('student_health_records', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained()->cascadeOnDelete();
            $table->string('blood_type', 5)->nullable();
            $table->integer('height')->nullable(); // in cm
            $table->integer('weight')->nullable(); // in kg
            $table->text('medical_history')->nullable(); // Riwayat penyakit
            $table->text('allergies')->nullable();
            $table->text('special_needs')->nullable(); // Berkebutuhan khusus
            $table->timestamps();
        });

        // 4. Counseling Notes (BK)
        Schema::create('counseling_notes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained()->cascadeOnDelete();
            $table->foreignId('counselor_id')->nullable()->constrained('teachers')->nullOnDelete(); // Guru BK / Wali Kelas
            $table->date('date');
            $table->string('category'); // behavior, academic, social, career
            $table->string('severity')->default('low'); // low, medium, high, critical
            $table->text('title');
            $table->text('description');
            $table->text('follow_up_action')->nullable();
            $table->string('status')->default('open'); // open, in_progress, resolved
            $table->boolean('is_confidential')->default(true); // If true, only visible to authorized
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('counseling_notes');
        Schema::dropIfExists('student_health_records');
        Schema::dropIfExists('student_mutations');
        
        Schema::table('students', function (Blueprint $table) {
            $table->dropColumn(['family_card_number', 'nik']);
        });
    }
};
