<?php

namespace Database\Factories;

use App\Models\Student;
use App\Models\Task;
use Illuminate\Database\Eloquent\Factories\Factory;

class TaskScoreFactory extends Factory
{
    public function definition(): array
    {
        return [
            'task_id'           => Task::factory(),
            'student_id'        => Student::factory(),
            'score'             => $this->faker->numberBetween(50, 100),
            'notes'             => null,
            'submission_status' => 'kumpul',
        ];
    }
}
