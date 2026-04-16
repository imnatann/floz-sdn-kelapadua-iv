<?php

use App\Models\Grade;
use App\Models\Semester;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Services\Mobile\GradingService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new GradingService();
    $this->semester = Semester::factory()->create(['is_active' => true]);
});

it('returns grade roster with students and existing grades', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);

    $s1 = Student::factory()->create(['class_id' => $ta->class_id]);
    $s2 = Student::factory()->create(['class_id' => $ta->class_id]);

    // s1 has existing grade
    Grade::factory()->create([
        'student_id' => $s1->id,
        'subject_id' => $ta->subject_id,
        'class_id' => $ta->class_id,
        'semester_id' => $this->semester->id,
        'daily_test_avg' => 80,
        'mid_test' => 85,
        'final_test' => null,
    ]);

    $result = $this->service->getRoster($ta, $user);

    expect($result)->toHaveKeys(['teaching_assignment', 'students']);
    expect($result['students'])->toHaveCount(2);

    $s1Data = collect($result['students'])->firstWhere('id', $s1->id);
    expect($s1Data['daily_test_avg'])->toBe(80.0);
    expect($s1Data['mid_test'])->toBe(85.0);
    expect($s1Data['final_test'])->toBeNull();

    $s2Data = collect($result['students'])->firstWhere('id', $s2->id);
    expect($s2Data['daily_test_avg'])->toBeNull();
});

it('returns empty students for class with no active students', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    // No students in class

    $result = $this->service->getRoster($ta, $user);

    expect($result['students'])->toBe([]);
});

it('stores grades using updateOrCreate in transaction', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $student = Student::factory()->create(['class_id' => $ta->class_id]);

    $entries = [
        ['student_id' => $student->id, 'daily_test_avg' => 80, 'mid_test' => 85, 'final_test' => 90],
    ];

    $result = $this->service->storeGrades($ta, $entries, $user);

    expect(Grade::count())->toBe(1);
    $grade = Grade::first();
    expect($grade->student_id)->toBe($student->id);
    expect($grade->subject_id)->toBe($ta->subject_id);
    expect($grade->semester_id)->toBe($this->semester->id);
    expect($grade->teacher_id)->toBe($teacher->id);
    expect((float) $grade->daily_test_avg)->toBe(80.0);
    expect((float) $grade->mid_test)->toBe(85.0);
    expect((float) $grade->final_test)->toBe(90.0);
});

it('auto-calculates final_score and predicate when all 3 scores present', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $student = Student::factory()->create(['class_id' => $ta->class_id]);

    // Formula: (80*0.3) + (85*0.3) + (90*0.4) = 24 + 25.5 + 36 = 85.5
    $this->service->storeGrades($ta, [
        ['student_id' => $student->id, 'daily_test_avg' => 80, 'mid_test' => 85, 'final_test' => 90],
    ], $user);

    $grade = Grade::first();
    expect((float) $grade->final_score)->toBe(85.5);
    expect($grade->predicate)->toBe('B');
});

it('sets final_score to null when not all 3 scores present', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $student = Student::factory()->create(['class_id' => $ta->class_id]);

    $this->service->storeGrades($ta, [
        ['student_id' => $student->id, 'daily_test_avg' => 80, 'mid_test' => null, 'final_test' => null],
    ], $user);

    $grade = Grade::first();
    expect($grade->final_score)->toBeNull();
    expect($grade->predicate)->toBeNull();
});

it('updates existing grade on second submit', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $student = Student::factory()->create(['class_id' => $ta->class_id]);

    // First submit: only Harian
    $this->service->storeGrades($ta, [
        ['student_id' => $student->id, 'daily_test_avg' => 80, 'mid_test' => null, 'final_test' => null],
    ], $user);

    // Second submit: add UTS + UAS
    $this->service->storeGrades($ta, [
        ['student_id' => $student->id, 'daily_test_avg' => 80, 'mid_test' => 85, 'final_test' => 90],
    ], $user);

    expect(Grade::count())->toBe(1); // updateOrCreate, not duplicate
    $grade = Grade::first();
    expect((float) $grade->final_score)->toBe(85.5);
    expect($grade->predicate)->toBe('B');
});
