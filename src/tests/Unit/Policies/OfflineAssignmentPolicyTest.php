<?php

use App\Models\OfflineAssignment;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use App\Policies\OfflineAssignmentPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->policy = new OfflineAssignmentPolicy;
});

it('allows a teacher to view their own offline assignment', function () {
    $teacher = Teacher::factory()->create();
    $assignment = OfflineAssignment::factory()
        ->for($teacher)
        ->withClasses()
        ->create();

    expect($this->policy->view($teacher->user, $assignment))->toBeTrue();
});

it('rejects a teacher viewing another teacher\'s offline assignment', function () {
    $teacherA = Teacher::factory()->create();
    $teacherB = Teacher::factory()->create();
    $assignmentOfB = OfflineAssignment::factory()
        ->for($teacherB)
        ->withClasses()
        ->create();

    expect($this->policy->view($teacherA->user, $assignmentOfB))->toBeFalse();
});

it('allows a student to view an assignment targeting their class', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $teacher = Teacher::factory()->create();
    $assignment = OfflineAssignment::factory()
        ->for($teacher)
        ->withClasses($student->class_id)
        ->create();

    expect($this->policy->view($user, $assignment))->toBeTrue();
});

it('rejects a student viewing an assignment not targeting their class', function () {
    $studentA = Student::factory()->create();
    $userA = User::where('email', $studentA->email)->first();
    $differentClass = SchoolClass::factory()->create();
    $teacher = Teacher::factory()->create();
    $assignmentForOtherClass = OfflineAssignment::factory()
        ->for($teacher)
        ->withClasses($differentClass->id)
        ->create();

    expect($this->policy->view($userA, $assignmentForOtherClass))->toBeFalse();
});

it('applies before hook to allow school admin to view any offline assignment', function () {
    $admin = User::factory()->schoolAdmin()->create();
    $teacher = Teacher::factory()->create();
    $assignment = OfflineAssignment::factory()
        ->for($teacher)
        ->withClasses()
        ->create();

    // Test that the before hook returns true for admins
    expect($this->policy->before($admin, 'view'))->toBeTrue();
});

it('allows teachers to view any assignment in viewAny', function () {
    $teacher = Teacher::factory()->create();

    expect($this->policy->viewAny($teacher->user))->toBeTrue();
});

it('allows students to view any assignment in viewAny', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    expect($this->policy->viewAny($user))->toBeTrue();
});
