<?php

use App\Models\Announcement;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use App\Policies\AnnouncementPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(fn () => $this->policy = new AnnouncementPolicy());

it('allows any authenticated user to view a school-wide announcement', function () {
    $a = Announcement::factory()->create(['target_audience' => 'all']);
    $student = Student::factory()->create();
    $studentUser = User::where('email', $student->email)->first();
    $teacher = Teacher::factory()->create();

    expect($this->policy->view($studentUser, $a))->toBeTrue();
    expect($this->policy->view($teacher->user, $a))->toBeTrue();
});

it('allows school admin and teachers to create', function () {
    $admin = User::factory()->schoolAdmin()->create();
    $teacher = Teacher::factory()->create();
    $student = Student::factory()->create();
    $studentUser = User::where('email', $student->email)->first();

    expect($this->policy->create($admin))->toBeTrue();
    expect($this->policy->create($teacher->user))->toBeTrue();
    expect($this->policy->create($studentUser))->toBeFalse();
});

it('allows viewAny for all authenticated users', function () {
    $student = Student::factory()->create();
    $studentUser = User::where('email', $student->email)->first();
    expect($this->policy->viewAny($studentUser))->toBeTrue();
});

it('allows only students to view a students-only announcement', function () {
    $a = Announcement::factory()->create(['target_audience' => 'students']);
    $student = Student::factory()->create();
    $studentUser = User::where('email', $student->email)->first();
    $teacher = Teacher::factory()->create();
    $admin = User::factory()->schoolAdmin()->create();

    expect($this->policy->view($studentUser, $a))->toBeTrue();
    expect($this->policy->view($teacher->user, $a))->toBeFalse();
    expect($this->policy->view($admin, $a))->toBeTrue(); // admins always see all
});

it('allows only teachers to view a teachers-only announcement', function () {
    $a = Announcement::factory()->create(['target_audience' => 'teachers']);
    $teacher = Teacher::factory()->create();
    $student = Student::factory()->create();
    $studentUser = User::where('email', $student->email)->first();
    $admin = User::factory()->schoolAdmin()->create();

    expect($this->policy->view($teacher->user, $a))->toBeTrue();
    expect($this->policy->view($studentUser, $a))->toBeFalse();
    expect($this->policy->view($admin, $a))->toBeTrue(); // admins always see all
});

it('allows the author to update their own announcement', function () {
    $admin = User::factory()->schoolAdmin()->create();
    $a = Announcement::factory()->create(['user_id' => $admin->id]);

    expect($this->policy->update($admin, $a))->toBeTrue();
});

it('allows school admin to update any announcement', function () {
    $admin = User::factory()->schoolAdmin()->create();
    $otherAdmin = User::factory()->schoolAdmin()->create();
    $a = Announcement::factory()->create(['user_id' => $otherAdmin->id]);

    expect($this->policy->update($admin, $a))->toBeTrue();
});

it('prevents a non-author teacher from updating another teachers announcement', function () {
    $teacher1 = Teacher::factory()->create();
    $teacher2 = Teacher::factory()->create();
    $a = Announcement::factory()->create(['user_id' => $teacher1->user->id]);

    expect($this->policy->update($teacher2->user, $a))->toBeFalse();
});

it('mirrors update logic for delete', function () {
    $admin = User::factory()->schoolAdmin()->create();
    $a = Announcement::factory()->create(['user_id' => $admin->id]);
    $student = Student::factory()->create();
    $studentUser = User::where('email', $student->email)->first();

    expect($this->policy->delete($admin, $a))->toBeTrue();
    expect($this->policy->delete($studentUser, $a))->toBeFalse();
});
