<?php

use App\Models\Student;
use App\Models\Teacher;
use App\Enums\UserRole;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

it('creates a student with linked user and class', function () {
    $student = Student::factory()->create();
    expect($student->user)->not->toBeNull();
    expect($student->class)->not->toBeNull();
    expect($student->user->role)->toBe(UserRole::Student);
});

it('creates a teacher with linked user', function () {
    $teacher = Teacher::factory()->create();
    expect($teacher->user)->not->toBeNull();
    expect($teacher->user->role)->toBe(UserRole::Teacher);
});
