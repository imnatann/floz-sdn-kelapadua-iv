<?php

use App\Models\Meeting;
use App\Models\MeetingMaterial;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->class = SchoolClass::factory()->create();
    $this->student = Student::factory()->create(['class_id' => $this->class->id]);
    // StudentFactory auto-creates a User with the student's email — fetch it, don't re-create.
    $this->user = User::where('email', $this->student->email)->first();
    $this->user->update(['role' => 'student']);
    $this->token = $this->user->createToken('mobile')->plainTextToken;
});

it('GET /student/courses returns subjects for the student class', function () {
    $teacher = Teacher::factory()->create();
    $ta = TeachingAssignment::factory()->for($teacher)->create(['class_id' => $this->class->id]);
    // TeachingAssignment::booted() auto-generates 16 meetings — no need to create more.

    $this->withHeader('Authorization', "Bearer {$this->token}")
        ->getJson('/api/v1/student/courses')
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.id', $ta->id);
});

it('GET /student/courses/{ta}/meetings returns meetings list', function () {
    $ta = TeachingAssignment::factory()->create(['class_id' => $this->class->id]);
    // booted() already generated 16 meetings.

    $this->withHeader('Authorization', "Bearer {$this->token}")
        ->getJson("/api/v1/student/courses/{$ta->id}/meetings")
        ->assertOk()
        ->assertJsonCount(16, 'data.meetings')
        ->assertJsonPath('data.teaching_assignment.id', $ta->id);
});

it('GET /student/meetings/{meeting} returns materials list', function () {
    $ta = TeachingAssignment::factory()->create(['class_id' => $this->class->id]);
    // Use the auto-generated meeting #1 (already exists).
    $meeting = Meeting::where('teaching_assignment_id', $ta->id)
        ->where('meeting_number', 1)
        ->first();
    MeetingMaterial::factory()->create([
        'meeting_id' => $meeting->id,
        'title' => 'Slide',
        'type' => 'file',
        'file_path' => 'materials/slide.pdf',
    ]);

    $this->withHeader('Authorization', "Bearer {$this->token}")
        ->getJson("/api/v1/student/meetings/{$meeting->id}")
        ->assertOk()
        ->assertJsonPath('data.meeting.id', $meeting->id)
        ->assertJsonCount(1, 'data.materials');
});

it('returns 403 when student tries to access TA from another class', function () {
    $otherClass = SchoolClass::factory()->create();
    $ta = TeachingAssignment::factory()->create(['class_id' => $otherClass->id]);

    $this->withHeader('Authorization', "Bearer {$this->token}")
        ->getJson("/api/v1/student/courses/{$ta->id}/meetings")
        ->assertForbidden();
});

it('returns 401 without token on courses endpoint', function () {
    $this->getJson('/api/v1/student/courses')->assertUnauthorized();
});
