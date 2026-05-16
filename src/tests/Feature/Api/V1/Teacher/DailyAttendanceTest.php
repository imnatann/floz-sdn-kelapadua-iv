<?php

use App\Models\Attendance;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->semester = Semester::factory()->create(['is_active' => true]);
});

it('blocks non homeroom teacher from daily attendance', function () {
    $homeroom = Teacher::factory()->create();
    $other    = Teacher::factory()->create();
    $class    = SchoolClass::factory()->create(['homeroom_teacher_id' => $homeroom->id]);

    $token = $other->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/teacher/classes/{$class->id}/attendance/today")
        ->assertForbidden();
});

it('blocks non homeroom teacher from posting daily attendance', function () {
    $homeroom = Teacher::factory()->create();
    $other    = Teacher::factory()->create();
    $class    = SchoolClass::factory()->create(['homeroom_teacher_id' => $homeroom->id]);
    $student  = Student::factory()->create(['class_id' => $class->id]);

    $token = $other->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/teacher/classes/{$class->id}/attendance/today", [
            'entries' => [
                ['student_id' => $student->id, 'status' => 'hadir'],
            ],
        ])
        ->assertForbidden();
});

it('writes attendance row with next meeting number for today', function () {
    $teacher = Teacher::factory()->create();
    $class   = SchoolClass::factory()->create(['homeroom_teacher_id' => $teacher->id]);
    $student = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);

    $token = $teacher->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/teacher/classes/{$class->id}/attendance/today", [
            'entries' => [
                ['student_id' => $student->id, 'status' => 'hadir', 'note' => null],
            ],
        ])
        ->assertOk()
        ->assertJsonStructure([
            'data' => [
                'meeting_number',
                'date',
                'class' => ['id', 'name'],
                'students' => [
                    '*' => ['id', 'name', 'nis', 'status', 'note'],
                ],
            ],
        ])
        ->assertJsonPath('data.students.0.status', 'hadir');

    $row = Attendance::first();
    expect($row)->not->toBeNull()
        ->and($row->meeting_number)->toBe(1)
        ->and($row->date->toDateString())->toBe(now()->toDateString())
        ->and($row->class_id)->toBe($class->id)
        ->and($row->semester_id)->toBe($this->semester->id);
});

it('reuses same meeting number when attendance already recorded today', function () {
    $teacher = Teacher::factory()->create();
    $class   = SchoolClass::factory()->create(['homeroom_teacher_id' => $teacher->id]);
    $s1      = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);
    $s2      = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);

    // Pre-seed a row for today with meeting_number = 3
    Attendance::factory()->create([
        'class_id'      => $class->id,
        'semester_id'   => $this->semester->id,
        'student_id'    => $s1->id,
        'meeting_number'=> 3,
        'date'          => now()->toDateString(),
        'status'        => 'hadir',
    ]);

    $token = $teacher->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/teacher/classes/{$class->id}/attendance/today", [
            'entries' => [
                ['student_id' => $s2->id, 'status' => 'alpha'],
            ],
        ])
        ->assertOk()
        ->assertJsonPath('data.meeting_number', 3);

    // Both rows share meeting_number 3
    expect(Attendance::where('meeting_number', 3)->count())->toBe(2);
});

it('increments meeting number beyond existing records', function () {
    $teacher = Teacher::factory()->create();
    $class   = SchoolClass::factory()->create(['homeroom_teacher_id' => $teacher->id]);
    $student = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);

    // Pre-seed 5 past meetings (different dates) — max meeting_number = 5
    for ($i = 1; $i <= 5; $i++) {
        Attendance::factory()->create([
            'class_id'      => $class->id,
            'semester_id'   => $this->semester->id,
            'student_id'    => $student->id,
            'meeting_number'=> $i,
            'date'          => now()->subDays(6 - $i)->toDateString(),
            'status'        => 'hadir',
        ]);
    }

    $token = $teacher->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/teacher/classes/{$class->id}/attendance/today", [
            'entries' => [
                ['student_id' => $student->id, 'status' => 'izin'],
            ],
        ])
        ->assertOk()
        ->assertJsonPath('data.meeting_number', 6);
});

it('returns roster on GET today', function () {
    $teacher = Teacher::factory()->create();
    $class   = SchoolClass::factory()->create(['homeroom_teacher_id' => $teacher->id]);
    Student::factory()->count(4)->create(['class_id' => $class->id, 'status' => 'active']);

    $token = $teacher->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/teacher/classes/{$class->id}/attendance/today")
        ->assertOk()
        ->assertJsonStructure([
            'data' => [
                'meeting_number',
                'date',
                'class' => ['id', 'name'],
                'students',
            ],
        ])
        ->assertJsonCount(4, 'data.students');
});

it('returns 401 without token on daily attendance', function () {
    $this->getJson('/api/v1/teacher/classes/1/attendance/today')
        ->assertUnauthorized();
});

it('returns 403 for student accessing daily attendance endpoint', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/teacher/classes/1/attendance/today')
        ->assertForbidden();
});
