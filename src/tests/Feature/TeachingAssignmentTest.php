<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('allows school admin to edit a teaching assignment', function () {
    $admin = User::factory()->schoolAdmin()->create();
    $assignment = TeachingAssignment::factory()->create();

    $this->actingAs($admin)
        ->get(route('teaching-assignments.edit', $assignment))
        ->assertOk()
        ->assertInertia(fn ($page) => $page
            ->component('TeachingAssignments/Edit')
            ->where('assignment.id', $assignment->id)
        );
});

it('allows school admin to update a teaching assignment', function () {
    $admin = User::factory()->schoolAdmin()->create();
    $assignment = TeachingAssignment::factory()->create();
    $academicYear = AcademicYear::factory()->create();
    $schoolClass = SchoolClass::factory()->create(['academic_year_id' => $academicYear->id]);
    $subject = Subject::factory()->create();
    $teacher = Teacher::factory()->create();

    $this->actingAs($admin)
        ->put(route('teaching-assignments.update', $assignment), [
            'teacher_id' => $teacher->id,
            'subject_id' => $subject->id,
            'class_id' => $schoolClass->id,
            'academic_year_id' => $academicYear->id,
        ])
        ->assertRedirect(route('teaching-assignments.index'));

    expect($assignment->fresh())
        ->teacher_id->toBe($teacher->id)
        ->subject_id->toBe($subject->id)
        ->class_id->toBe($schoolClass->id)
        ->academic_year_id->toBe($academicYear->id);
});

it('keeps teachers unauthorized from editing teaching assignments', function () {
    $teacherUser = User::factory()->teacher()->create();
    $assignment = TeachingAssignment::factory()->create();

    $this->actingAs($teacherUser)
        ->get(route('teaching-assignments.edit', $assignment))
        ->assertForbidden();
});
