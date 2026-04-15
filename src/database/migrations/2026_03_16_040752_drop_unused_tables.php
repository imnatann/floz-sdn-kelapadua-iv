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
        Schema::dropIfExists('submission_attachments');
        Schema::dropIfExists('assignment_submissions');
        Schema::dropIfExists('assignment_attachments');
        Schema::dropIfExists('assignments');
        Schema::dropIfExists('counseling_notes');
        Schema::dropIfExists('student_health_records');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Tables are permanently dropped and deprecated.
        // No rollback is provided.
    }
};
