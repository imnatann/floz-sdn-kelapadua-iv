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
        Schema::table('task_scores', function (Blueprint $table) {
            $table->string('submission_status', 20)->default('kumpul')->after('notes');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('task_scores', function (Blueprint $table) {
            $table->dropColumn('submission_status');
        });
    }
};
