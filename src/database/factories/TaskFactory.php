<?php

namespace Database\Factories;

use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Subject;
use Illuminate\Database\Eloquent\Factories\Factory;

class TaskFactory extends Factory
{
    public function definition(): array
    {
        return [
            'class_id'   => SchoolClass::factory(),
            'subject_id' => Subject::factory(),
            'semester_id'=> Semester::factory(),
            'teacher_id' => null,
            'title'      => $this->faker->sentence(3),
            'description'=> null,
            'task_date'  => $this->faker->date(),
            'due_date'   => $this->faker->date(),
            'max_score'  => 100,
            'status'     => 'active',
        ];
    }
}
