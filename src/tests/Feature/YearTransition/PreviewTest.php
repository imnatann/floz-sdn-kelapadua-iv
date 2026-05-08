<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\User;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

function adminForTransition(): User
{
    return User::factory()->create(['role' => 'school_admin']);
}

function teacherForTransition(): User
{
    return User::factory()->create(['role' => 'teacher']);
}

it('guest cannot access preview (redirect to login)', function () {
    $this->postJson(route('year-transition.preview'), [])
        ->assertUnauthorized();
});

it('teacher cannot access preview (403)', function () {
    $teacher = teacherForTransition();
    $source  = AcademicYear::factory()->create(['is_active' => true]);
    $target  = AcademicYear::factory()->create();

    $this->actingAs($teacher)
        ->postJson(route('year-transition.preview'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
        ])
        ->assertForbidden();
});

it('preview returns 422 when source and target are the same', function () {
    $admin  = adminForTransition();
    $source = AcademicYear::factory()->create();

    $this->actingAs($admin)
        ->postJson(route('year-transition.preview'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $source->id,
        ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['target_academic_year_id']);
});

it('preview returns 200 with mutation plan structure', function () {
    $admin  = adminForTransition();
    $source = AcademicYear::factory()->create(['is_active' => true]);
    $target = AcademicYear::factory()->create();
    $class  = SchoolClass::factory()->create([
        'academic_year_id' => $source->id,
        'grade_level'      => 4,
        'name'             => 'Kelas 4A',
    ]);
    Student::factory()->count(5)->create(['class_id' => $class->id, 'status' => 'active']);

    $this->actingAs($admin)
        ->postJson(route('year-transition.preview'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
        ])
        ->assertOk()
        ->assertJsonStructure(['mutations', 'summary', 'new_classes']);
});

it('preview returns 422 when confirmation_word is missing (execute route only)', function () {
    // This test documents that confirmation_word is NOT required for preview
    $admin  = adminForTransition();
    $source = AcademicYear::factory()->create(['is_active' => true]);
    $target = AcademicYear::factory()->create();

    $this->actingAs($admin)
        ->postJson(route('year-transition.preview'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
            // no confirmation_word — should NOT be required for preview
        ])
        ->assertOk();
});
