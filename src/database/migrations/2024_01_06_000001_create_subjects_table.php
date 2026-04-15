<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{

    public function up(): void
    {
        Schema::create('subjects', function (Blueprint $table) {
            $table->id();
            $table->string('code', 20)->unique();
            $table->string('name');
            $table->string('education_level', 10);      // SD/SMP/SMA
            $table->integer('grade_level')->nullable();
            $table->decimal('kkm', 5, 2)->default(70.00);
            $table->string('category', 50)->nullable();  // general/religion/specialty
            $table->text('description')->nullable();
            $table->string('status', 20)->default('active');
            $table->timestamps();

            $table->index(['education_level', 'grade_level']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subjects');
    }
};
