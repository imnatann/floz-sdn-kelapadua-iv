<?php

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

it('returns grade roster for a teaching assignment', function () {
    $teacher = Teacher::factory()->create();
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    Student::factory()->count(3)->create(['class_id' => $ta->class_id]);
    $token = $teacher->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/teacher/teaching-assignments/{$ta->id}/grade-roster")
        ->assertOk()
        ->assertJsonStructure([
            'data' => [
                'teaching_assignment' => ['id', 'subject_name', 'class_name'],
                'students' => ['*' => ['id', 'name', 'nis', 'daily_test_avg', 'mid_test', 'final_test', 'final_score', 'predicate']],
            ],
        ])
        ->assertJsonCount(3, 'data.students');
});

it('stores grades and returns updated roster', function () {
    $teacher = Teacher::factory()->create();
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $student = Student::factory()->create(['class_id' => $ta->class_id]);
    $token = $teacher->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/teacher/teaching-assignments/{$ta->id}/grades", [
            'entries' => [
                ['student_id' => $student->id, 'daily_test_avg' => 80, 'mid_test' => 85, 'final_test' => 90],
            ],
        ])
        ->assertOk()
        ->assertJsonPath('data.students.0.daily_test_avg', 80);

    expect(Grade::count())->toBe(1);
});

it('returns 422 for score above 100', function () {
    $teacher = Teacher::factory()->create();
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $student = Student::factory()->create(['class_id' => $ta->class_id]);
    $token = $teacher->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/teacher/teaching-assignments/{$ta->id}/grades", [
            'entries' => [
                ['student_id' => $student->id, 'daily_test_avg' => 150],
            ],
        ])
        ->assertStatus(422)
        ->assertJsonStructure(['message', 'errors']);
});

it('returns 403 for wrong teacher', function () {
    $teacherA = Teacher::factory()->create();
    $teacherB = Teacher::factory()->create();
    $taB = TeachingAssignment::factory()->create(['teacher_id' => $teacherB->id]);
    $tokenA = $teacherA->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$tokenA}")
        ->getJson("/api/v1/teacher/teaching-assignments/{$taB->id}/grade-roster")
        ->assertForbidden();
});

it('returns 401 without token', function () {
    $this->getJson('/api/v1/teacher/teaching-assignments/1/grade-roster')
        ->assertUnauthorized();
});
