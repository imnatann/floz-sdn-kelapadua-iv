<?php

use App\Models\OfflineAssignment;
use App\Models\OfflineAssignmentSubmission;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

// ─── List ─────────────────────────────────────────────────────────────────────

it('returns assignment list for student', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    OfflineAssignment::factory()->withClasses([$student->class_id])->create([
        'status'   => 'active',
        'due_date' => now()->addDays(5),
    ]);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/assignments')
        ->assertOk()
        ->assertJsonStructure(['data' => ['*' => ['id', 'title', 'description', 'due_date', 'subject', 'teacher', 'type']]]);
});

it('returns completed assignments when status=completed', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()->withClasses([$student->class_id])->create([
        'status'   => 'active',
        'due_date' => now()->addDays(3),
    ]);

    OfflineAssignmentSubmission::create([
        'offline_assignment_id' => $assignment->id,
        'student_id'            => $student->id,
        'submitted_at'          => now(),
    ]);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/assignments?status=completed')
        ->assertOk()
        ->assertJsonPath('data.0.id', $assignment->id);
});

// ─── Detail ───────────────────────────────────────────────────────────────────

it('returns assignment detail with correct envelope', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()->withClasses([$student->class_id])->create([
        'status' => 'active',
    ]);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/student/assignments/{$assignment->id}")
        ->assertOk()
        ->assertJsonStructure(['data' => ['id', 'title', 'description', 'due_date', 'subject', 'teacher', 'type', 'files', 'submission']]);
});

it('returns 404 for assignment not in student class', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()->create([
        'status' => 'active',
    ]);
    // Note: NOT attached to student's class

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/student/assignments/{$assignment->id}")
        ->assertNotFound();
});

// ─── Auth / Role guards ───────────────────────────────────────────────────────

it('returns 401 without token on list', function () {
    $this->getJson('/api/v1/student/assignments')->assertUnauthorized();
});

it('returns 403 for teacher on list', function () {
    $teacher = Teacher::factory()->create();
    $token   = $teacher->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/assignments')
        ->assertForbidden();
});
