<?php

namespace Database\Factories;

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use Illuminate\Database\Eloquent\Factories\Factory;

class SchoolClassFactory extends Factory
{
    protected $model = SchoolClass::class;

    public function definition(): array
    {
        return [
            'name'                => fake()->randomElement(['1A', '1B', '2A', '2B', '3A', '4A', '5A', '6A']),
            'grade_level'         => fake()->numberBetween(1, 6),
            'academic_year_id'    => AcademicYear::factory(),
            'homeroom_teacher_id' => null,
            'max_students'        => 40,
            'status'              => 'active',
        ];
    }
}
