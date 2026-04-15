<?php

namespace Database\Factories;

use App\Models\Announcement;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class AnnouncementFactory extends Factory
{
    protected $model = Announcement::class;

    public function definition(): array
    {
        return [
            'title'           => fake()->sentence(6),
            'content'         => fake()->paragraphs(2, true),
            'excerpt'         => fake()->sentence(12),
            'cover_image_url' => null,
            'target_audience' => 'all',
            'is_pinned'       => false,
            'type'            => 'info',
            'is_published'    => true,
            'user_id'         => User::factory()->schoolAdmin(),
        ];
    }

    public function forStudents(): static
    {
        return $this->state(fn (array $attributes) => [
            'target_audience' => 'students',
        ]);
    }

    public function forTeachers(): static
    {
        return $this->state(fn (array $attributes) => [
            'target_audience' => 'teachers',
        ]);
    }

    public function pinned(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_pinned' => true,
        ]);
    }

    public function unpublished(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_published' => false,
        ]);
    }
}
