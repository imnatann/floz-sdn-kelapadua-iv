<?php

use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use App\Services\Mobile\TeacherClassService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new TeacherClassService();
});

// ─── listForTeacher ───────────────────────────────────────────────────────────

it('returns teaching assignments for the authenticated teacher', function () {
    $teacher = Teacher::factory()->create();
    $user    = $teacher->user;

    TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);

    $result = $this->service->listForTeacher($user);

    expect($result)->toHaveCount(2);
    expect($result[0])->toHaveKeys(['id', 'subject_name', 'class_name', 'academic_year', 'student_count', 'meeting_count']);
});

it('returns empty array when teacher has no teaching assignments', function () {
    $teacher = Teacher::factory()->create();
    $user    = $teacher->user;

    $result = $this->service->listForTeacher($user);

    expect($result)->toBe([]);
});

it('returns empty array when user has no teacher record', function () {
    $user = User::factory()->create();

    $result = $this->service->listForTeacher($user);

    expect($result)->toBe([]);
});

it('includes student_count reflecting the number of students in the class', function () {
    $teacher = Teacher::factory()->create();
    $user    = $teacher->user;

    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);

    // Add students to the class
    \App\Models\Student::factory()->count(3)->create(['class_id' => $ta->class_id]);

    $result = $this->service->listForTeacher($user);

    expect($result[0]['student_count'])->toBe(3);
});

it('includes meeting_count which is always 16 from the observer', function () {
    $teacher = Teacher::factory()->create();
    $user    = $teacher->user;

    TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);

    $result = $this->service->listForTeacher($user);

    expect($result[0]['meeting_count'])->toBe(16);
});

it('does not return teaching assignments belonging to other teachers', function () {
    $teacherA = Teacher::factory()->create();
    $teacherB = Teacher::factory()->create();

    TeachingAssignment::factory()->create(['teacher_id' => $teacherA->id]);
    TeachingAssignment::factory()->create(['teacher_id' => $teacherB->id]);

    $result = $this->service->listForTeacher($teacherA->user);

    expect($result)->toHaveCount(1);
});

// ─── meetingsForTeachingAssignment ────────────────────────────────────────────

it('returns 16 meetings ordered by meeting_number for a valid teaching assignment', function () {
    $teacher = Teacher::factory()->create();
    $user    = $teacher->user;

    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);

    $result = $this->service->meetingsForTeachingAssignment($user, $ta->id);

    expect($result)->not->toBeNull();
    expect($result)->toHaveKeys(['teaching_assignment', 'meetings']);
    expect($result['meetings'])->toHaveCount(16);
    expect($result['meetings'][0]['meeting_number'])->toBe(1);
    expect($result['meetings'][15]['meeting_number'])->toBe(16);
});

it('returns null when the teaching assignment belongs to a different teacher', function () {
    $teacherA = Teacher::factory()->create();
    $teacherB = Teacher::factory()->create();

    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacherB->id]);

    $result = $this->service->meetingsForTeachingAssignment($teacherA->user, $ta->id);

    expect($result)->toBeNull();
});

it('returns null when the teaching assignment does not exist', function () {
    $teacher = Teacher::factory()->create();

    $result = $this->service->meetingsForTeachingAssignment($teacher->user, 99999);

    expect($result)->toBeNull();
});

it('includes meeting fields: id, meeting_number, title, description, is_locked, material_count, assignment_count', function () {
    $teacher = Teacher::factory()->create();
    $ta      = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);

    $result = $this->service->meetingsForTeachingAssignment($teacher->user, $ta->id);

    $meeting = $result['meetings'][0];
    expect($meeting)->toHaveKeys([
        'id', 'meeting_number', 'title', 'description', 'is_locked', 'material_count', 'assignment_count',
    ]);
    expect($meeting['material_count'])->toBe(0);
    expect($meeting['assignment_count'])->toBe(0);
});

it('includes correct teaching_assignment envelope with subject_name and class_name', function () {
    $teacher = Teacher::factory()->create();
    $ta      = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);

    $result = $this->service->meetingsForTeachingAssignment($teacher->user, $ta->id);

    expect($result['teaching_assignment'])->toHaveKeys(['id', 'subject_name', 'class_name']);
    expect($result['teaching_assignment']['id'])->toBe($ta->id);
    expect($result['teaching_assignment']['subject_name'])->not->toBeEmpty();
    expect($result['teaching_assignment']['class_name'])->not->toBeEmpty();
});
