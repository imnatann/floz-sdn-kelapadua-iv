<?php

use App\Models\ReportCard;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use App\Policies\ReportCardPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(fn () => $this->policy = new ReportCardPolicy());

it('allows a student to view their own report card', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $card = ReportCard::factory()->create(['student_id' => $student->id]);

    expect($this->policy->view($user, $card))->toBeTrue();
});

it('rejects a student viewing another student\'s report card', function () {
    $a = Student::factory()->create();
    $b = Student::factory()->create();
    $userA = User::where('email', $a->email)->first();
    $card = ReportCard::factory()->create(['student_id' => $b->id]);

    expect($this->policy->view($userA, $card))->toBeFalse();
});

it('allows the homeroom teacher to view a report card of their class', function () {
    $teacher = Teacher::factory()->create();
    $class = SchoolClass::factory()->create(['homeroom_teacher_id' => $teacher->id]);
    $student = Student::factory()->create(['class_id' => $class->id]);
    $card = ReportCard::factory()->create(['student_id' => $student->id]);

    expect($this->policy->view($teacher->user, $card))->toBeTrue();
});

it('rejects a non-homeroom teacher from viewing the report card', function () {
    $teacherHomeroom = Teacher::factory()->create();
    $teacherOther = Teacher::factory()->create();
    $class = SchoolClass::factory()->create(['homeroom_teacher_id' => $teacherHomeroom->id]);
    $student = Student::factory()->create(['class_id' => $class->id]);
    $card = ReportCard::factory()->create(['student_id' => $student->id]);

    expect($this->policy->view($teacherOther->user, $card))->toBeFalse();
});
