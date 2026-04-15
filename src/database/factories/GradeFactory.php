<?php

namespace Database\Factories;

use App\Models\Grade;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\Subject;
use Illuminate\Database\Eloquent\Factories\Factory;

class GradeFactory extends Factory
{
    protected $model = Grade::class;

    public function definition(): array
    {
        return [
            'student_id' => Student::factory(),
            'subject_id' => Subject::factory(),
            'class_id' => SchoolClass::factory(),
            'semester_id' => Semester::factory(),
            'teacher_id' => null,
            'daily_test_avg' => null,
            'mid_test' => null,
            'final_test' => null,
            'knowledge_score' => null,
            'skill_score' => null,
            'final_score' => null,
            'predicate' => null,
            'attitude_score' => null,
            'notes' => null,
        ];
    }
}
