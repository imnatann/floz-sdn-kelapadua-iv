<?php

use App\Models\Attendance;
use App\Models\Grade;
use App\Models\Semester;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Services\Mobile\RecapService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new RecapService();
    $this->semester = Semester::factory()->create(['is_active' => true]);
});

it('attendanceRecap returns mixed statuses with percentage calculation', function () {
    $teacher = Teacher::factory()->create();
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);

    $s1 = Student::factory()->create(['class_id' => $ta->class_id]);
    $s2 = Student::factory()->create(['class_id' => $ta->class_id]);

    // S1: 5 hadir, 2 sakit, 1 alpha => total 8, percentage = 5/8*100 = 62.5
    foreach (range(1, 5) as $n) {
        Attendance::factory()->create([
            'student_id' => $s1->id,
            'class_id' => $ta->class_id,
            'semester_id' => $this->semester->id,
            'meeting_number' => $n,
            'status' => 'hadir',
            'recorded_by' => $teacher->id,
        ]);
    }
    foreach ([6, 7] as $n) {
        Attendance::factory()->create([
            'student_id' => $s1->id,
            'class_id' => $ta->class_id,
            'semester_id' => $this->semester->id,
            'meeting_number' => $n,
            'status' => 'sakit',
            'recorded_by' => $teacher->id,
        ]);
    }
    Attendance::factory()->create([
        'student_id' => $s1->id,
        'class_id' => $ta->class_id,
        'semester_id' => $this->semester->id,
        'meeting_number' => 8,
        'status' => 'alpha',
        'recorded_by' => $teacher->id,
    ]);
    // S2: 0 records => all zero, percentage = 0.0

    $result = $this->service->attendanceRecap($ta);

    expect($result)->toHaveKeys(['teaching_assignment', 'students']);
    expect($result['teaching_assignment'])->toMatchArray([
        'id' => $ta->id,
        'subject_name' => $ta->subject->name,
        'class_name' => $ta->schoolClass->name,
    ]);
    expect($result['students'])->toHaveCount(2);

    $s1Data = collect($result['students'])->firstWhere('id', $s1->id);
    expect($s1Data['hadir'])->toBe(5);
    expect($s1Data['sakit'])->toBe(2);
    expect($s1Data['izin'])->toBe(0);
    expect($s1Data['alpha'])->toBe(1);
    expect($s1Data['total'])->toBe(8);
    expect($s1Data['percentage'])->toBe(62.5);
    expect($s1Data['name'])->toBe($s1->name);
    expect($s1Data['nis'])->toBe($s1->nis);

    $s2Data = collect($result['students'])->firstWhere('id', $s2->id);
    expect($s2Data['hadir'])->toBe(0);
    expect($s2Data['sakit'])->toBe(0);
    expect($s2Data['izin'])->toBe(0);
    expect($s2Data['alpha'])->toBe(0);
    expect($s2Data['total'])->toBe(0);
    expect($s2Data['percentage'])->toBe(0.0);
});

it('attendanceRecap returns empty students array when class has no students', function () {
    $teacher = Teacher::factory()->create();
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    // No students in class

    $result = $this->service->attendanceRecap($ta);

    expect($result)->toHaveKeys(['teaching_assignment', 'students']);
    expect($result['students'])->toBe([]);
});

it('gradeRecap returns scores per student', function () {
    $teacher = Teacher::factory()->create();
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);

    $s1 = Student::factory()->create(['class_id' => $ta->class_id]);
    $s2 = Student::factory()->create(['class_id' => $ta->class_id]);

    // s1 has full grade
    Grade::factory()->create([
        'student_id' => $s1->id,
        'subject_id' => $ta->subject_id,
        'class_id' => $ta->class_id,
        'semester_id' => $this->semester->id,
        'teacher_id' => $teacher->id,
        'daily_test_avg' => 80,
        'mid_test' => 85,
        'final_test' => 90,
        'final_score' => 85.5,
        'predicate' => 'B',
    ]);
    // s2 has no grade

    $result = $this->service->gradeRecap($ta);

    expect($result)->toHaveKeys(['teaching_assignment', 'students']);
    expect($result['teaching_assignment'])->toMatchArray([
        'id' => $ta->id,
        'subject_name' => $ta->subject->name,
        'class_name' => $ta->schoolClass->name,
    ]);
    expect($result['students'])->toHaveCount(2);

    $s1Data = collect($result['students'])->firstWhere('id', $s1->id);
    expect($s1Data['daily_test_avg'])->toBe(80.0);
    expect($s1Data['mid_test'])->toBe(85.0);
    expect($s1Data['final_test'])->toBe(90.0);
    expect($s1Data['final_score'])->toBe(85.5);
    expect($s1Data['predicate'])->toBe('B');
    expect($s1Data['name'])->toBe($s1->name);
    expect($s1Data['nis'])->toBe($s1->nis);

    $s2Data = collect($result['students'])->firstWhere('id', $s2->id);
    expect($s2Data['daily_test_avg'])->toBeNull();
    expect($s2Data['mid_test'])->toBeNull();
    expect($s2Data['final_test'])->toBeNull();
    expect($s2Data['final_score'])->toBeNull();
    expect($s2Data['predicate'])->toBeNull();
});

it('gradeRecap returns empty students array when class has no students', function () {
    $teacher = Teacher::factory()->create();
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    // No students in class

    $result = $this->service->gradeRecap($ta);

    expect($result)->toHaveKeys(['teaching_assignment', 'students']);
    expect($result['students'])->toBe([]);
});
