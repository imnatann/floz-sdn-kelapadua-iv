<?php

namespace Database\Factories;

use App\Models\Meeting;
use App\Models\MeetingMaterial;
use Illuminate\Database\Eloquent\Factories\Factory;

class MeetingMaterialFactory extends Factory
{
    protected $model = MeetingMaterial::class;

    public function definition(): array
    {
        return [
            'meeting_id' => Meeting::factory(),
            'title' => fake()->sentence(3),
            'type' => 'file',
            'content' => null,
            'file_path' => null,
            'file_name' => null,
            'file_size' => null,
            'url' => null,
            'sort_order' => 0,
        ];
    }
}
