<?php

use App\Models\Grade;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('returns grades list by subject for authenticated student', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $subject = Subject::factory()->create();
    Grade::factory()->create([
        'student_id' => $student->id,
        'subject_id' => $subject->id,
        'class_id' => $student->class_id,
        'final_score' => 85.00,
    ]);
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/grades')
        ->assertOk()
        ->assertJsonStructure([
            'data' => ['*' => ['subject_id', 'subject_name', 'average', 'grade_count', 'kkm']],
        ])
        ->assertJsonPath('data.0.subject_name', $subject->name);
});

it('returns grade detail for a subject', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $subject = Subject::factory()->create();
    Grade::factory()->create([
        'student_id' => $student->id,
        'subject_id' => $subject->id,
        'class_id' => $student->class_id,
        'final_score' => 85.00,
        'predicate' => 'A',
    ]);
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/student/grades/{$subject->id}")
        ->assertOk()
        ->assertJsonStructure([
            'data' => [
                'subject' => ['id', 'name', 'kkm'],
                'grades' => ['*' => ['id', 'final_score', 'predicate']],
            ],
        ]);
});

it('returns 401 without token', function () {
    $this->getJson('/api/v1/student/grades')->assertUnauthorized();
});

it('returns 403 for teacher', function () {
    $teacher = Teacher::factory()->create();
    $token = $teacher->user->createToken('mobile')->plainTextToken;
    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/grades')
        ->assertForbidden();
});
