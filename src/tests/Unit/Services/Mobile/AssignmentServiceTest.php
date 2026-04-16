<?php

use App\Models\OfflineAssignment;
use App\Models\OfflineAssignmentSubmission;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\User;
use App\Services\Mobile\AssignmentService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new AssignmentService();
});

// ─── listForStudent ───────────────────────────────────────────────────────────

it('list upcoming returns assignments not yet submitted ordered by due_date asc', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();

    $later  = OfflineAssignment::factory()->withClasses([$student->class_id])->create([
        'due_date' => now()->addDays(10),
        'status'   => 'active',
    ]);
    $sooner = OfflineAssignment::factory()->withClasses([$student->class_id])->create([
        'due_date' => now()->addDays(3),
        'status'   => 'active',
    ]);

    $result = $this->service->listForStudent($user, 'upcoming');

    expect($result)->toHaveCount(2);
    expect($result[0]['id'])->toBe($sooner->id);
    expect($result[1]['id'])->toBe($later->id);
    expect($result[0])->toHaveKeys(['id', 'title', 'description', 'due_date', 'subject', 'teacher', 'type']);
});

it('list completed returns only submitted assignments ordered by due_date desc', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();

    $submitted = OfflineAssignment::factory()->withClasses([$student->class_id])->create([
        'due_date' => now()->addDays(5),
        'status'   => 'active',
    ]);
    $notSubmitted = OfflineAssignment::factory()->withClasses([$student->class_id])->create([
        'due_date' => now()->addDays(2),
        'status'   => 'active',
    ]);

    OfflineAssignmentSubmission::create([
        'offline_assignment_id' => $submitted->id,
        'student_id'            => $student->id,
        'submitted_at'          => now(),
    ]);

    $result = $this->service->listForStudent($user, 'completed');

    expect($result)->toHaveCount(1);
    expect($result[0]['id'])->toBe($submitted->id);
});

it('list returns empty array when student has no class', function () {
    $student = Student::factory()->create(['class_id' => null]);
    $user    = User::where('email', $student->email)->first();

    OfflineAssignment::factory()->create(['status' => 'active']);

    $result = $this->service->listForStudent($user, 'upcoming');

    expect($result)->toBe([]);
});

it('list description is trimmed to 100 characters', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();

    $longDesc = str_repeat('A', 200);

    OfflineAssignment::factory()->withClasses([$student->class_id])->create([
        'description' => $longDesc,
        'status'      => 'active',
        'due_date'    => now()->addDay(),
    ]);

    $result = $this->service->listForStudent($user, 'upcoming');

    expect(mb_strlen($result[0]['description']))->toBeLessThanOrEqual(103); // Str::limit adds '...'
    expect($result[0]['description'])->toEndWith('...');
});

// ─── detailForStudent ─────────────────────────────────────────────────────────

it('detail returns full assignment data with submission when one exists', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();

    $assignment = OfflineAssignment::factory()->withClasses([$student->class_id])->create([
        'status'      => 'active',
        'description' => 'Full description text.',
    ]);

    $submission = OfflineAssignmentSubmission::create([
        'offline_assignment_id' => $assignment->id,
        'student_id'            => $student->id,
        'submitted_at'          => now(),
        'grade'                 => 90,
        'correction_note'       => 'Great work!',
    ]);

    $result = $this->service->detailForStudent($user, $assignment->id);

    expect($result)->not->toBeNull();
    expect($result)->toHaveKeys(['id', 'title', 'description', 'due_date', 'subject', 'teacher', 'type', 'files', 'submission']);
    expect($result['description'])->toBe('Full description text.');
    expect($result['submission'])->not->toBeNull();
    expect($result['submission']['status'])->toBe('graded');
    expect($result['submission']['score'])->toBe(90);
    expect($result['submission']['teacher_notes'])->toBe('Great work!');
});

it('detail returns submission null when student has not submitted', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();

    $assignment = OfflineAssignment::factory()->withClasses([$student->class_id])->create([
        'status' => 'active',
    ]);

    $result = $this->service->detailForStudent($user, $assignment->id);

    expect($result)->not->toBeNull();
    expect($result['submission'])->toBeNull();
    expect($result['files'])->toBe([]);
});

it('detail returns null for assignment belonging to a different class', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();

    $otherClass  = SchoolClass::factory()->create();
    $assignment  = OfflineAssignment::factory()->withClasses([$otherClass->id])->create([
        'status' => 'active',
    ]);

    $result = $this->service->detailForStudent($user, $assignment->id);

    expect($result)->toBeNull();
});

it('detail returns submitted status when grade is null', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();

    $assignment = OfflineAssignment::factory()->withClasses([$student->class_id])->create([
        'status' => 'active',
    ]);

    OfflineAssignmentSubmission::create([
        'offline_assignment_id' => $assignment->id,
        'student_id'            => $student->id,
        'submitted_at'          => now(),
        'grade'                 => null,
    ]);

    $result = $this->service->detailForStudent($user, $assignment->id);

    expect($result['submission']['status'])->toBe('submitted');
    expect($result['submission']['score'])->toBeNull();
});
