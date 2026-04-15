<?php

namespace Database\Factories;

use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class StudentFactory extends Factory
{
    protected $model = Student::class;

    public function definition(): array
    {
        // Create a student-role user; share the email so the email-based relation works.
        $user = User::factory()->student()->create();

        return [
            'email'              => $user->email,
            'nis'                => fake()->unique()->numerify('##########'),
            'nisn'               => null,
            'nik'                => null,
            'family_card_number' => null,
            'name'               => $user->name,
            'gender'             => fake()->randomElement(['male', 'female']),
            'birth_place'        => fake()->city(),
            'birth_date'         => fake()->date('Y-m-d', '-10 years'),
            'religion'           => fake()->randomElement(['Islam', 'Kristen', 'Katholik', 'Hindu', 'Buddha']),
            'address'            => fake()->address(),
            'parent_name'        => fake()->name(),
            'parent_phone'       => fake()->numerify('08##########'),
            'class_id'           => SchoolClass::factory(),
            'status'             => 'active',
            'photo_url'          => null,
        ];
    }
}
