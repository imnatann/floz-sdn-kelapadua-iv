<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('year_transition_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('executed_by')->constrained('users')->restrictOnDelete();
            $table->foreignId('source_academic_year_id')->constrained('academic_years')->restrictOnDelete();
            $table->foreignId('target_academic_year_id')->constrained('academic_years')->restrictOnDelete();
            $table->timestamp('executed_at');
            $table->integer('promoted_count')->default(0);
            $table->integer('graduated_count')->default(0);
            $table->integer('retained_count')->default(0);
            $table->integer('excluded_count')->default(0);
            $table->json('plan_snapshot'); // full dry-run plan for manual restore reference
            $table->string('ip_address', 45)->nullable();
            $table->timestamps();

            // BLOCK-1 + BLOCK-5: Prevent double-execute for same (source, target) pair
            $table->unique(['source_academic_year_id', 'target_academic_year_id'], 'ytl_unique_transition');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('year_transition_logs');
    }
};
