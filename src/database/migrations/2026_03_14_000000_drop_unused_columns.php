<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Drop unused columns from grades table.
     */
    public function up(): void
    {
        // Drop unused columns from grades table
        Schema::table('grades', function (Blueprint $table) {
            $table->dropColumn(['attendance_score', 'description']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('grades', function (Blueprint $table) {
            $table->decimal('attendance_score', 5, 2)->nullable();
            $table->text('description')->nullable();
        });
    }
};
