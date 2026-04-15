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
        Schema::table('announcements', function (Blueprint $table) {
            $table->enum('target_audience', ['all', 'teachers', 'students'])->default('all')->after('content');
            $table->boolean('is_pinned')->default(false)->after('target_audience');
            $table->string('cover_image_url')->nullable()->after('title');
            $table->text('excerpt')->nullable()->after('cover_image_url');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('announcements', function (Blueprint $table) {
            $table->dropColumn(['target_audience', 'is_pinned', 'cover_image_url', 'excerpt']);
        });
    }
};
