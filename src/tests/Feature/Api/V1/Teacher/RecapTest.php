<?php

use App\Models\Attendance;
use App\Models\Grade;
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

it('returns attendance recap for a teaching assignment', function () {
    $teacher = Teacher::factory()->create();
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $students = Student::factory()->count(2)->create(['class_id' => $ta->class_id]);

    Attendance::factory()->create([
        'student_id' => $students[0]->id,
        'class_id' => $ta->class_id,
        'semester_id' => $this->semester->id,
        'meeting_number' => 1,
        'status' => 'hadir',
    ]);
    Attendance::factory()->create([
        'student_id' => $students[0]->id,
        'class_id' => $ta->class_id,
        'semester_id' => $this->semester->id,
        'meeting_number' => 2,
        'status' => 'sakit',
    ]);

    $token = $teacher->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/teacher/teaching-assignments/{$ta->id}/attendance-recap")
        ->assertOk()
        ->assertJsonStructure([
            'data' => [
                'teaching_assignment' => ['id', 'subject_name', 'class_name'],
                'students' => [
                    '*' => ['id', 'name', 'nis', 'hadir', 'sakit', 'izin', 'alpha', 'total', 'percentage'],
                ],
            ],
        ])
        ->assertJsonCount(2, 'data.students');
});

it('returns grade recap for a teaching assignment', function () {
    $teacher = Teacher::factory()->create();
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    Student::factory()->count(2)->create(['class_id' => $ta->class_id]);

    $token = $teacher->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/teacher/teaching-assignments/{$ta->id}/grade-recap")
        ->assertOk()
        ->assertJsonStructure([
            'data' => [
                'teaching_assignment' => ['id', 'subject_name', 'class_name'],
                'students' => [
                    '*' => ['id', 'name', 'nis', 'daily_test_avg', 'mid_test', 'final_test', 'final_score', 'predicate'],
                ],
            ],
        ])
        ->assertJsonCount(2, 'data.students');
});

it('returns 403 when another teacher requests the recap', function () {
    $teacherA = Teacher::factory()->create();
    $teacherB = Teacher::factory()->create();
    $taB = TeachingAssignment::factory()->create(['teacher_id' => $teacherB->id]);
    $tokenA = $teacherA->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$tokenA}")
        ->getJson("/api/v1/teacher/teaching-assignments/{$taB->id}/attendance-recap")
        ->assertForbidden();
});

it('returns 403 for student accessing teacher recap endpoint', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/teacher/teaching-assignments/1/attendance-recap')
        ->assertForbidden();
});

it('returns 401 without token on recap endpoint', function () {
    $this->getJson('/api/v1/teacher/teaching-assignments/1/attendance-recap')
        ->assertUnauthorized();
});
