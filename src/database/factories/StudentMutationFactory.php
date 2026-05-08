<?php

namespace Database\Factories;

use App\Models\Student;
use App\Models\StudentMutation;
use Illuminate\Database\Eloquent\Factories\Factory;

class StudentMutationFactory extends Factory
{
    protected $model = StudentMutation::class;

    public function definition(): array
    {
        return [
            'student_id'       => Student::factory(),
            'type'             => $this->faker->randomElement(['promotion', 'retention', 'graduated', 'transfer_in', 'transfer_out']),
            'from_class_id'    => null,
            'to_class_id'      => null,
            'date'             => $this->faker->dateTimeBetween('-1 year', 'now')->format('Y-m-d'),
            'reason'           => $this->faker->optional()->sentence(),
            'reference_number' => null,
            'notes'            => null,
        ];
    }
}
