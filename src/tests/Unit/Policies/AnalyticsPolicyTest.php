<?php

use App\Models\SchoolClass;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use App\Policies\AnalyticsPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

// ── view() ────────────────────────────────────────────────────────────────────

it('view returns true for admin', function () {
    $admin  = User::factory()->create(['role' => 'school_admin']);
    $policy = new AnalyticsPolicy;

    expect($policy->view($admin))->toBeTrue();
});

it('view returns false for teacher with no homeroom and no TA', function () {
    // Teacher user with no Teacher record (orphan)
    $user   = User::factory()->create(['role' => 'teacher']);
    $policy = new AnalyticsPolicy;

    expect($policy->view($user))->toBeFalse();
});

it('view returns true for teacher with homeroom', function () {
    $ay      = \App\Models\AcademicYear::factory()->create(['is_active' => true]);
    $teacher = Teacher::factory()->create();
    $user    = User::where('email', $teacher->email)->firstOrFail();
    SchoolClass::factory()->create([
        'academic_year_id'    => $ay->id,
        'homeroom_teacher_id' => $teacher->id,
    ]);

    $policy = new AnalyticsPolicy;
    expect($policy->view($user))->toBeTrue();
});

it('view returns true for teacher with TA', function () {
    $ay      = \App\Models\AcademicYear::factory()->create(['is_active' => true]);
    $teacher = Teacher::factory()->create();
    $user    = User::where('email', $teacher->email)->firstOrFail();
    $class   = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    TeachingAssignment::factory()->create([
        'teacher_id'       => $teacher->id,
        'class_id'         => $class->id,
        'academic_year_id' => $ay->id,
    ]);

    $policy = new AnalyticsPolicy;
    expect($policy->view($user))->toBeTrue();
});

it('view returns false for student', function () {
    $student = User::factory()->create(['role' => 'student']);
    $policy  = new AnalyticsPolicy;

    expect($policy->view($student))->toBeFalse();
});

// viewWidget() removed along with the analytics dashboard/reports UI.
