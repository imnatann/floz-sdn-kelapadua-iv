<?php

namespace Database\Factories;

use App\Models\Teacher;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class TeacherFactory extends Factory
{
    protected $model = Teacher::class;

    public function definition(): array
    {
        // Create a teacher-role user; share the email so the email-based relation works.
        $user = User::factory()->teacher()->create();

        return [
            'user_id'     => $user->id,
            'email'       => $user->email,
            'name'        => $user->name,
            'nip'         => null,
            'nuptk'       => null,
            'gender'      => fake()->randomElement(['male', 'female']),
            'birth_place' => fake()->city(),
            'birth_date'  => fake()->date('Y-m-d', '-25 years'),
            'phone'       => fake()->numerify('08##########'),
            'address'     => fake()->address(),
            'is_homeroom' => false,
            'photo_url'   => null,
            'status'      => 'active',
        ];
    }
}
