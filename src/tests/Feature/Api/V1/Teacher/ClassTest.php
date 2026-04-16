<?php

use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

// ─── List teaching assignments ────────────────────────────────────────────────

it('returns teaching assignments list for authenticated teacher', function () {
    $teacher = Teacher::factory()->create();
    $user    = $teacher->user;
    $token   = $user->createToken('mobile')->plainTextToken;

    TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/teacher/teaching-assignments')
        ->assertOk()
        ->assertJsonStructure([
            'data' => [
                '*' => [
                    'id',
                    'subject_name',
                    'class_name',
                    'academic_year',
                    'student_count',
                    'meeting_count',
                ],
            ],
        ])
        ->assertJsonCount(2, 'data');
});

it('returns empty data array when teacher has no teaching assignments', function () {
    $teacher = Teacher::factory()->create();
    $token   = $teacher->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/teacher/teaching-assignments')
        ->assertOk()
        ->assertJsonPath('data', []);
});

// ─── Meetings for a teaching assignment ───────────────────────────────────────

it('returns 16 meetings for a teaching assignment owned by the teacher', function () {
    $teacher = Teacher::factory()->create();
    $user    = $teacher->user;
    $token   = $user->createToken('mobile')->plainTextToken;

    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/teacher/teaching-assignments/{$ta->id}/meetings")
        ->assertOk()
        ->assertJsonStructure([
            'data' => [
                'teaching_assignment' => ['id', 'subject_name', 'class_name'],
                'meetings' => [
                    '*' => [
                        'id',
                        'meeting_number',
                        'title',
                        'description',
                        'is_locked',
                        'material_count',
                        'assignment_count',
                    ],
                ],
            ],
        ])
        ->assertJsonCount(16, 'data.meetings');
});

// ─── 403 for non-teacher's TA ─────────────────────────────────────────────────

it('returns 404 for a teaching assignment owned by a different teacher', function () {
    $teacherA = Teacher::factory()->create();
    $teacherB = Teacher::factory()->create();

    $ta    = TeachingAssignment::factory()->create(['teacher_id' => $teacherB->id]);
    $token = $teacherA->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/teacher/teaching-assignments/{$ta->id}/meetings")
        ->assertNotFound();
});

it('returns 404 for a non-existent teaching assignment id', function () {
    $teacher = Teacher::factory()->create();
    $token   = $teacher->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/teacher/teaching-assignments/99999/meetings')
        ->assertNotFound();
});

// ─── 401 without token ────────────────────────────────────────────────────────

it('returns 401 without a token on list endpoint', function () {
    $this->getJson('/api/v1/teacher/teaching-assignments')->assertUnauthorized();
});

it('returns 401 without a token on meetings endpoint', function () {
    $this->getJson('/api/v1/teacher/teaching-assignments/1/meetings')->assertUnauthorized();
});

// ─── 403 for student accessing teacher endpoint ───────────────────────────────

it('returns 403 for student accessing teacher list endpoint', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/teacher/teaching-assignments')
        ->assertForbidden();
});

it('returns 403 for student accessing teacher meetings endpoint', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/teacher/teaching-assignments/1/meetings')
        ->assertForbidden();
});
