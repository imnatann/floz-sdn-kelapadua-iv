<?php

use App\Models\ReportCard;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('returns published report cards for student', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    ReportCard::factory()->create([
        'student_id' => $student->id,
        'class_id' => $student->class_id,
        'status' => 'published',
        'published_at' => now(),
        'average_score' => 85,
    ]);
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/report-cards')
        ->assertOk()
        ->assertJsonStructure(['data' => ['*' => ['id', 'semester_name', 'average_score', 'rank', 'published_at']]]);
});

it('returns report card detail', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $rc = ReportCard::factory()->create([
        'student_id' => $student->id,
        'class_id' => $student->class_id,
        'status' => 'published',
        'published_at' => now(),
        'pdf_url' => 'https://example.com/rapor.pdf',
    ]);
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/student/report-cards/{$rc->id}")
        ->assertOk()
        ->assertJsonStructure(['data' => ['id', 'semester_name', 'class_name', 'average_score', 'pdf_url']]);
});

it('returns pdf url', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $rc = ReportCard::factory()->create([
        'student_id' => $student->id,
        'class_id' => $student->class_id,
        'status' => 'published',
        'published_at' => now(),
        'pdf_url' => 'https://cdn.example.com/report.pdf',
    ]);
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/student/report-cards/{$rc->id}/pdf")
        ->assertOk()
        ->assertJsonPath('data.url', 'https://cdn.example.com/report.pdf');
});

it('returns 401 without token', function () {
    $this->getJson('/api/v1/student/report-cards')->assertUnauthorized();
});

it('returns 403 for teacher', function () {
    $teacher = Teacher::factory()->create();
    $token = $teacher->user->createToken('mobile')->plainTextToken;
    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/report-cards')
        ->assertForbidden();
});
