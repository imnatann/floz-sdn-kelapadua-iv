<?php

namespace Database\Factories;

use App\Models\AcademicYear;
use App\Models\Semester;
use Illuminate\Database\Eloquent\Factories\Factory;

class SemesterFactory extends Factory
{
    protected $model = Semester::class;

    public function definition(): array
    {
        return [
            'academic_year_id' => AcademicYear::factory(),
            'semester_number'  => fake()->randomElement([1, 2]),
            'start_date'       => '2026-07-14',
            'end_date'         => '2026-12-19',
            'is_active'        => true,
        ];
    }
}
