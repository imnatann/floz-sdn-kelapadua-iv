<?php

namespace Database\Factories;

use App\Models\Subject;
use Illuminate\Database\Eloquent\Factories\Factory;

class SubjectFactory extends Factory
{
    protected $model = Subject::class;

    public function definition(): array
    {
        return [
            'code' => fake()->unique()->bothify('SUB-####'),
            'name' => fake()->words(3, true),
            'education_level' => fake()->randomElement(['SD', 'SMP', 'SMA']),
            'grade_level' => fake()->numberBetween(1, 6),
            'kkm' => 70.00,
            'category' => fake()->randomElement(['general', 'religion', 'specialty']),
            'description' => null,
            'status' => 'active',
        ];
    }
}
