<?php

namespace Database\Factories;

use App\Models\Meeting;
use App\Models\TeachingAssignment;
use Illuminate\Database\Eloquent\Factories\Factory;

class MeetingFactory extends Factory
{
    protected $model = Meeting::class;

    public function definition(): array
    {
        return [
            'teaching_assignment_id' => TeachingAssignment::factory(),
            'meeting_number' => fake()->numberBetween(1, 14),
            'title' => fake()->sentence(3),
            'description' => null,
            'is_locked' => true,
        ];
    }
}
