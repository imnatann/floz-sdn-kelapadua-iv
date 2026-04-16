<?php

use App\Models\Grade;
use App\Models\Student;
use App\Models\Subject;
use App\Models\User;
use App\Services\Mobile\GradeService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new GradeService();
});

it('returns grades grouped by subject with averages for student', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $subject = Subject::factory()->create();

    Grade::factory()->create([
        'student_id' => $student->id,
        'subject_id' => $subject->id,
        'class_id' => $student->class_id,
        'final_score' => 85.00,
    ]);

    $result = $this->service->listForStudent($user);

    expect($result)->toHaveCount(1);
    expect($result[0])->toHaveKeys(['subject_id', 'subject_name', 'average', 'grade_count', 'kkm']);
    expect($result[0]['subject_name'])->toBe($subject->name);
    expect($result[0]['average'])->toBe(85.0);
    expect($result[0]['grade_count'])->toBe(1);
});

it('returns empty list when student has no grades', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    $result = $this->service->listForStudent($user);

    expect($result)->toBe([]);
});

it('returns detail grades for a specific subject', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $subject = Subject::factory()->create();

    Grade::factory()->create([
        'student_id' => $student->id,
        'subject_id' => $subject->id,
        'class_id' => $student->class_id,
        'daily_test_avg' => 80.00,
        'mid_test' => 85.00,
        'final_test' => 90.00,
        'final_score' => 85.00,
        'predicate' => 'A',
    ]);

    $result = $this->service->detailForStudent($user, $subject->id);

    expect($result['subject'])->toMatchArray(['id' => $subject->id, 'name' => $subject->name]);
    expect($result['grades'])->toHaveCount(1);
    expect($result['grades'][0])->toHaveKeys([
        'id', 'daily_test_avg', 'mid_test', 'final_test',
        'final_score', 'predicate', 'semester',
    ]);
});

it('returns empty grades array when student has no grades in specified subject', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $subject = Subject::factory()->create();

    $result = $this->service->detailForStudent($user, $subject->id);

    expect($result['subject'])->toMatchArray(['id' => $subject->id, 'name' => $subject->name]);
    expect($result['grades'])->toBe([]);
});
