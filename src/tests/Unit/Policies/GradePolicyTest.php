<?php

use App\Models\Grade;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use App\Policies\GradePolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->policy = new GradePolicy();
});

it('allows a student to view their own grade', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    expect($user)->not->toBeNull();

    $grade = Grade::factory()->create(['student_id' => $student->id]);

    expect($this->policy->view($user, $grade))->toBeTrue();
});

it('rejects a student viewing another student\'s grade', function () {
    $a = Student::factory()->create();
    $b = Student::factory()->create();
    $userA = User::where('email', $a->email)->first();
    $gradeOfB = Grade::factory()->create(['student_id' => $b->id]);

    expect($this->policy->view($userA, $gradeOfB))->toBeFalse();
});

it('allows a teacher to view a grade in their teaching assignment', function () {
    $teacher = Teacher::factory()->create();
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $student = Student::factory()->create(['class_id' => $ta->class_id]);
    $grade = Grade::factory()->create([
        'student_id' => $student->id,
        'subject_id' => $ta->subject_id,
    ]);

    expect($this->policy->view($teacher->user, $grade))->toBeTrue();
});

it('rejects a teacher viewing a grade outside their teaching assignment', function () {
    $teacherA = Teacher::factory()->create();
    $teacherB = Teacher::factory()->create();
    $taB = TeachingAssignment::factory()->create(['teacher_id' => $teacherB->id]);
    $student = Student::factory()->create(['class_id' => $taB->class_id]);
    $grade = Grade::factory()->create([
        'student_id' => $student->id,
        'subject_id' => $taB->subject_id,
    ]);

    expect($this->policy->view($teacherA->user, $grade))->toBeFalse();
});
