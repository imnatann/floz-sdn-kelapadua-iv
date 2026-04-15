<?php

use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('returns the authenticated student profile', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/auth/me')
        ->assertOk()
        ->assertJsonPath('data.role', 'student')
        ->assertJsonPath('data.id', $user->id)
        ->assertJsonStructure(['data' => ['student' => ['id', 'nis', 'nisn', 'class']]]);
});

it('returns the authenticated teacher profile', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user; // Teacher->user() uses user_id FK
    expect($user)->not->toBeNull();
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/auth/me')
        ->assertOk()
        ->assertJsonPath('data.role', 'teacher')
        ->assertJsonStructure(['data' => ['teacher' => ['id', 'nip', 'name']]]);
});

it('returns 401 without a token', function () {
    $this->getJson('/api/v1/auth/me')->assertUnauthorized();
});
