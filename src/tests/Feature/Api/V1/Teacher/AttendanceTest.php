<?php

use App\Models\Attendance;
use App\Models\Semester;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->semester = Semester::factory()->create(['is_active' => true]);
});

it('returns attendance roster for a meeting', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->first();
    Student::factory()->count(3)->create(['class_id' => $ta->class_id]);

    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/teacher/meetings/{$meeting->id}/attendance")
        ->assertOk()
        ->assertJsonStructure([
            'data' => [
                'meeting' => ['id', 'meeting_number', 'title'],
                'class' => ['id', 'name'],
                'teaching_assignment' => ['id', 'subject'],
                'students' => [
                    '*' => ['id', 'name', 'nis', 'status', 'note'],
                ],
            ],
        ])
        ->assertJsonCount(3, 'data.students');
});

it('submits attendance and returns refreshed roster', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->first();
    $student = Student::factory()->create(['class_id' => $ta->class_id]);

    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/teacher/meetings/{$meeting->id}/attendance", [
            'entries' => [
                ['student_id' => $student->id, 'status' => 'hadir', 'note' => null],
            ],
        ])
        ->assertOk()
        ->assertJsonPath('data.students.0.status', 'hadir');

    expect(Attendance::count())->toBe(1);
});

it('returns 422 for invalid status', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->first();
    $student = Student::factory()->create(['class_id' => $ta->class_id]);
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/teacher/meetings/{$meeting->id}/attendance", [
            'entries' => [
                ['student_id' => $student->id, 'status' => 'invalid_status'],
            ],
        ])
        ->assertStatus(422)
        ->assertJsonStructure(['message', 'errors']);
});

it('returns 403 for another teacher\'s meeting', function () {
    $teacherA = Teacher::factory()->create();
    $teacherB = Teacher::factory()->create();
    $taB = TeachingAssignment::factory()->create(['teacher_id' => $teacherB->id]);
    $meetingB = $taB->meetings()->first();

    $tokenA = $teacherA->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$tokenA}")
        ->getJson("/api/v1/teacher/meetings/{$meetingB->id}/attendance")
        ->assertForbidden();
});

it('returns 403 for student accessing teacher endpoint', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/teacher/meetings/1/attendance')
        ->assertForbidden();
});

it('returns 401 without token', function () {
    $this->getJson('/api/v1/teacher/meetings/1/attendance')
        ->assertUnauthorized();
});
