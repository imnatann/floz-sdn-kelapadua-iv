<?php

namespace Database\Factories;

use App\Models\Schedule;
use App\Models\TeachingAssignment;
use Illuminate\Database\Eloquent\Factories\Factory;

class ScheduleFactory extends Factory
{
    protected $model = Schedule::class;

    public function definition(): array
    {
        return [
            'teaching_assignment_id' => TeachingAssignment::factory(),
            'day_of_week' => fake()->numberBetween(1, 5),
            'start_time' => '07:00:00',
            'end_time'   => '08:30:00',
        ];
    }

    public function onDay(int $dayOfWeek): static
    {
        return $this->state(fn () => ['day_of_week' => $dayOfWeek]);
    }

    public function at(string $start, string $end): static
    {
        return $this->state(fn () => [
            'start_time' => $start,
            'end_time' => $end,
        ]);
    }
}
