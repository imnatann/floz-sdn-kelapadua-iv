<?php

use App\Models\OfflineAssignment;
use App\Models\OfflineAssignmentSubmission;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

// ─── Auth / authz guards ──────────────────────────────────────────────────────

it('rejects unauthenticated submit', function () {
    $assignment = OfflineAssignment::factory()->create(['status' => 'active']);

    $this->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [
        'answer_text' => 'My answer',
    ])->assertUnauthorized();
});

it('rejects teacher role on submit', function () {
    $teacher = Teacher::factory()->create();
    $user    = User::where('email', $teacher->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()->create(['status' => 'active']);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [
            'answer_text' => 'My answer',
        ])->assertForbidden();
});

// ─── Validation ───────────────────────────────────────────────────────────────

it('returns 422 when both answer_text and answer_link are missing', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()
        ->withClasses([$student->class_id])
        ->create(['status' => 'active']);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [])
        ->assertUnprocessable();
});

it('returns 422 when answer_link is not a URL', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()
        ->withClasses([$student->class_id])
        ->create(['status' => 'active']);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [
            'answer_link' => 'not-a-url',
        ])->assertUnprocessable();
});

// ─── Business logic ───────────────────────────────────────────────────────────

it('returns 404 when assignment not in student class', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()->create(['status' => 'active']); // no class link

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [
            'answer_text' => 'My answer',
        ])->assertNotFound();
});

it('creates submission and returns 201 with correct structure', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()
        ->withClasses([$student->class_id])
        ->create(['status' => 'active', 'type' => 'manual']);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [
            'answer_text' => 'My detailed answer.',
            'answer_link' => 'https://drive.google.com/file/xyz',
        ])
        ->assertCreated()
        ->assertJsonStructure(['data' => ['submission_id', 'status', 'submitted_at', 'is_late']]);

    $this->assertDatabaseHas('offline_assignment_submissions', [
        'offline_assignment_id' => $assignment->id,
        'student_id'            => $student->id,
        'answer_text'           => 'My detailed answer.',
        'answer_link'           => 'https://drive.google.com/file/xyz',
    ]);
});

it('returns status submitted (not graded) immediately after submit', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()
        ->withClasses([$student->class_id])
        ->create(['status' => 'active']);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [
            'answer_text' => 'Answer',
        ])
        ->assertJsonPath('data.status', 'submitted');
});

it('flags is_late true when submitted after due_date', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()
        ->withClasses([$student->class_id])
        ->create(['status' => 'active', 'due_date' => now()->subDay()]);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [
            'answer_text' => 'Late answer',
        ])
        ->assertCreated()
        ->assertJsonPath('data.is_late', true);
});

it('returns 409 when student submits twice', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()
        ->withClasses([$student->class_id])
        ->create(['status' => 'active']);

    OfflineAssignmentSubmission::create([
        'offline_assignment_id' => $assignment->id,
        'student_id'            => $student->id,
        'submitted_at'          => now(),
        'answer_text'           => 'First submit',
    ]);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [
            'answer_text' => 'Second attempt',
        ])
        ->assertStatus(409);
});
