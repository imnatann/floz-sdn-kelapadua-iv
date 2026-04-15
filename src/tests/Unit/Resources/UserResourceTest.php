<?php

use App\Enums\UserRole;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

it('formats a student user with student profile', function () {
    $student = Student::factory()->create();
    $user = $student->user;

    expect($user)->not->toBeNull();

    $resource = (new UserResource($user))->resolve();

    expect($resource)->toHaveKeys(['id', 'name', 'email', 'role', 'is_active', 'student']);
    expect($resource['role'])->toBe('student');
    expect($resource['student'])->toHaveKeys(['id', 'nis', 'nisn', 'class']);
    expect($resource)->not->toHaveKey('teacher');
});

it('formats a teacher user with teacher profile', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;

    expect($user)->not->toBeNull();

    $resource = (new UserResource($user))->resolve();

    expect($resource['role'])->toBe('teacher');
    expect($resource['teacher'])->toHaveKeys(['id', 'nip', 'name']);
    expect($resource)->not->toHaveKey('student');
});

it('formats school admin without student or teacher profile', function () {
    $admin = User::factory()->schoolAdmin()->create();
    $resource = (new UserResource($admin))->resolve();

    expect($resource['role'])->toBe('school_admin');
    expect($resource)->not->toHaveKey('student');
    expect($resource)->not->toHaveKey('teacher');
});
