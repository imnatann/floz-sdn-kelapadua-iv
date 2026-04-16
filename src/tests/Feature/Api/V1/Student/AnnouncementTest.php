<?php

use App\Models\Announcement;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('returns published announcements visible to student', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $token = $user->createToken('mobile')->plainTextToken;

    Announcement::factory()->create([
        'is_published'    => true,
        'target_audience' => 'all',
        'title'           => 'For Everyone',
    ]);
    Announcement::factory()->create([
        'is_published'    => true,
        'target_audience' => 'students',
        'title'           => 'For Students',
    ]);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/announcements')
        ->assertOk()
        ->assertJsonStructure(['data' => ['*' => ['id', 'title', 'excerpt', 'type', 'is_pinned', 'created_at']]]);
});

it('returns announcement detail', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $token = $user->createToken('mobile')->plainTextToken;

    $announcement = Announcement::factory()->create([
        'is_published'    => true,
        'target_audience' => 'all',
        'title'           => 'Test Detail',
        'content'         => 'Full content body.',
    ]);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/student/announcements/{$announcement->id}")
        ->assertOk()
        ->assertJsonStructure(['data' => ['id', 'title', 'content', 'excerpt', 'type', 'is_pinned', 'created_at', 'updated_at']])
        ->assertJsonPath('data.title', 'Test Detail')
        ->assertJsonPath('data.content', 'Full content body.');
});

it('returns 404 for unpublished announcement', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $token = $user->createToken('mobile')->plainTextToken;

    $announcement = Announcement::factory()->unpublished()->create([
        'target_audience' => 'all',
    ]);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/student/announcements/{$announcement->id}")
        ->assertNotFound();
});

it('returns 404 for teacher-only announcement', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $token = $user->createToken('mobile')->plainTextToken;

    $announcement = Announcement::factory()->forTeachers()->create([
        'is_published' => true,
    ]);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/student/announcements/{$announcement->id}")
        ->assertNotFound();
});

it('returns 401 without token', function () {
    $this->getJson('/api/v1/student/announcements')->assertUnauthorized();
});

it('returns 403 for teacher', function () {
    $teacher = Teacher::factory()->create();
    $token = $teacher->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/announcements')
        ->assertForbidden();
});
