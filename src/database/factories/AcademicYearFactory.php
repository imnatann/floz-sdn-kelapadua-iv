<?php

namespace Database\Factories;

use App\Models\AcademicYear;
use Illuminate\Database\Eloquent\Factories\Factory;

class AcademicYearFactory extends Factory
{
    protected $model = AcademicYear::class;

    public function definition(): array
    {
        return [
            'name'       => '2026/2027 - Ganjil',
            'start_date' => '2026-07-14',
            'end_date'   => '2026-12-19',
            'is_active'  => true,
        ];
    }
}
