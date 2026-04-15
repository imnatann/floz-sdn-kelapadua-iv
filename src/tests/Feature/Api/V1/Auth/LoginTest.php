<?php

use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\RateLimiter;

uses(RefreshDatabase::class);

beforeEach(function () {
    RateLimiter::clear('login|127.0.0.1');
});

it('logs in a student successfully', function () {
    $student = Student::factory()->create();
    // Student factory creates a linked user via the email join.
    // Find the user by the student's email and set password.
    $user = User::where('email', $student->email)->first();
    expect($user)->not->toBeNull();
    $user->update(['password' => bcrypt('rahasia123')]);

    $response = $this->postJson('/api/v1/auth/login', [
        'email' => $user->email,
        'password' => 'rahasia123',
    ]);

    $response->assertOk()
        ->assertJsonStructure([
            'data' => [
                'token',
                'user' => ['id', 'name', 'email', 'role', 'is_active', 'student' => ['id', 'nis', 'nisn', 'class']],
            ],
        ])
        ->assertJsonPath('data.user.role', 'student');
});

it('returns 422 when email is missing', function () {
    $this->postJson('/api/v1/auth/login', ['password' => 'rahasia123'])
        ->assertStatus(422)
        ->assertJsonStructure(['message', 'errors' => ['email']]);
});

it('returns 401 on wrong password', function () {
    $user = User::factory()->student()->create(['password' => bcrypt('rahasia123')]);

    $this->postJson('/api/v1/auth/login', [
        'email' => $user->email,
        'password' => 'salah123',
    ])->assertStatus(401)
        ->assertJsonStructure(['message', 'code']);
});

it('returns 403 for inactive user', function () {
    $user = User::factory()->student()->inactive()->create(['password' => bcrypt('rahasia123')]);

    $this->postJson('/api/v1/auth/login', [
        'email' => $user->email,
        'password' => 'rahasia123',
    ])->assertStatus(403);
});

it('returns 403 for parent role with explicit message', function () {
    $user = User::factory()->parent()->create(['password' => bcrypt('rahasia123')]);

    $this->postJson('/api/v1/auth/login', [
        'email' => $user->email,
        'password' => 'rahasia123',
    ])->assertStatus(403)
        ->assertJsonPath('message', 'Akun parent belum didukung di mobile saat ini.');
});
