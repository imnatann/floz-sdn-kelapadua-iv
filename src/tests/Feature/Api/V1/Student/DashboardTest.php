<?php

use App\Models\Announcement;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('returns dashboard data wrapped in envelope for authenticated student', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    Announcement::factory()->count(3)->create(['is_published' => true]);

    $token = $user->createToken('mobile')->plainTextToken;

    $response = $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/dashboard');

    $response->assertOk()
        ->assertJsonStructure([
            'data' => [
                'role',
                'student' => ['id', 'name', 'class'],
                'stats' => ['attendance_percentage'],
                'todays_schedules',
                'recent_announcements',
            ],
        ])
        ->assertJsonPath('data.role', 'student')
        ->assertJsonPath('data.student.id', $student->id);
});

it('returns 401 without a token', function () {
    $this->getJson('/api/v1/student/dashboard')->assertUnauthorized();
});

it('returns 403 for teacher token', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/dashboard')
        ->assertForbidden();
});
