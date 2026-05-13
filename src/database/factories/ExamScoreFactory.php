<?php

namespace Database\Factories;

use App\Models\Exam;
use App\Models\Student;
use Illuminate\Database\Eloquent\Factories\Factory;

class ExamScoreFactory extends Factory
{
    public function definition(): array
    {
        return [
            'exam_id'           => Exam::factory(),
            'student_id'        => Student::factory(),
            'score'             => $this->faker->numberBetween(50, 100),
            'notes'             => null,
            'submission_status' => 'kumpul',
        ];
    }
}
