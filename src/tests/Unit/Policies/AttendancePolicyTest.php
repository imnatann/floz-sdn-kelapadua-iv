<?php

use App\Models\Attendance;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use App\Policies\AttendancePolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->policy = new AttendancePolicy;
});

it('allows a teacher to record attendance for their own meeting', function () {
    $teacher = Teacher::factory()->create();
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->first();  // observer-generated

    expect($this->policy->recordForMeeting($teacher->user, $meeting))->toBeTrue();
});

it('rejects a teacher recording for another teacher\'s meeting', function () {
    $teacherA = Teacher::factory()->create();
    $teacherB = Teacher::factory()->create();
    $taB = TeachingAssignment::factory()->create(['teacher_id' => $teacherB->id]);
    $meetingOfB = $taB->meetings()->first();

    expect($this->policy->recordForMeeting($teacherA->user, $meetingOfB))->toBeFalse();
});

it('allows a student to view their own attendance record', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $att = Attendance::factory()->create([
        'student_id' => $student->id,
        'class_id' => $student->class_id,
    ]);

    expect($this->policy->view($user, $att))->toBeTrue();
});

it('rejects a student viewing another student\'s attendance', function () {
    $a = Student::factory()->create();
    $b = Student::factory()->create();
    $userA = User::where('email', $a->email)->first();
    $attOfB = Attendance::factory()->create([
        'student_id' => $b->id,
        'class_id' => $b->class_id,
    ]);

    expect($this->policy->view($userA, $attOfB))->toBeFalse();
});
