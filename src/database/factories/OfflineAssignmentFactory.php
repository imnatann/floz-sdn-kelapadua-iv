<?php

namespace Database\Factories;

use App\Models\OfflineAssignment;
use App\Models\SchoolClass;
use App\Models\Subject;
use App\Models\Teacher;
use Illuminate\Database\Eloquent\Factories\Factory;

class OfflineAssignmentFactory extends Factory
{
    protected $model = OfflineAssignment::class;

    public function definition(): array
    {
        $teacher = Teacher::factory()->create();
        $subject = Subject::factory()->create();

        return [
            'teacher_id' => $teacher->id,
            'subject_id' => $subject->id,
            'title' => fake()->sentence(),
            'description' => fake()->paragraph(),
            'due_date' => fake()->dateTimeBetween('+1 day', '+30 days'),
            'status' => 'active',
            'created_by' => $teacher->user_id,
            'type' => 'manual',
        ];
    }

    public function withClasses($classIds = null): self
    {
        return $this->afterCreating(function (OfflineAssignment $assignment) use ($classIds) {
            if ($classIds === null) {
                $classIds = [SchoolClass::factory()->create()->id];
            }

            if (! is_array($classIds)) {
                $classIds = [$classIds];
            }

            $assignment->classes()->attach($classIds);
        });
    }
}
