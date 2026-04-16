<?php

use App\Models\Schedule;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('returns weekly schedule grouped by day for authenticated student', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $ta = TeachingAssignment::factory()->create(['class_id' => $student->class_id]);
    Schedule::factory()->onDay(1)->create(['teaching_assignment_id' => $ta->id]);
    Schedule::factory()->onDay(3)->create(['teaching_assignment_id' => $ta->id]);

    $token = $user->createToken('mobile')->plainTextToken;

    $response = $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/schedules');

    $response->assertOk()
        ->assertJsonStructure([
            'data' => [
                '*' => [
                    'day',
                    'day_name',
                    'items' => [
                        '*' => ['id', 'start_time', 'end_time', 'subject', 'teacher'],
                    ],
                ],
            ],
        ])
        ->assertJsonPath('data.0.day', 1)
        ->assertJsonPath('data.0.day_name', 'Senin')
        ->assertJsonPath('data.1.day', 3)
        ->assertJsonPath('data.1.day_name', 'Rabu');
});

it('returns empty data array when student has no schedule', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/schedules')
        ->assertOk()
        ->assertJsonPath('data', []);
});

it('returns 401 without a token', function () {
    $this->getJson('/api/v1/student/schedules')->assertUnauthorized();
});

it('returns 403 for teacher token', function () {
    $teacher = Teacher::factory()->create();
    $token = $teacher->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/schedules')
        ->assertForbidden();
});
