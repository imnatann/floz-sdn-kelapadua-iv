<?php

use App\Models\AcademicYear;
use App\Models\Semester;
use App\Models\User;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

function semesterAdmin(): User
{
    return User::factory()->create(['role' => 'school_admin']);
}

function semesterTeacher(): User
{
    return User::factory()->create(['role' => 'teacher']);
}

// ── index ─────────────────────────────────────────────────────────────

it('admin can view semesters for an academic year', function () {
    $admin = semesterAdmin();
    $ay = AcademicYear::factory()->create();
    Semester::factory()->create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => false]);
    Semester::factory()->create(['academic_year_id' => $ay->id, 'semester_number' => 2, 'is_active' => false]);

    $this->actingAs($admin)
        ->get(route('academic-years.semesters.index', $ay))
        ->assertOk()
        ->assertInertia(fn ($page) => $page
            ->component('Semesters/Index')
            ->has('semesters', 2)
            ->has('academicYear')
        );
});


// ── store ─────────────────────────────────────────────────────────────

it('admin can create a semester', function () {
    $admin = semesterAdmin();
    $ay = AcademicYear::factory()->create([
        'start_date' => '2026-07-01',
        'end_date'   => '2027-06-30',
    ]);

    $this->actingAs($admin)
        ->post(route('academic-years.semesters.store', $ay), [
            'semester_number' => 1,
            'start_date'      => '2026-07-01',
            'end_date'        => '2026-12-20',
        ])
        ->assertRedirect(route('academic-years.semesters.index', $ay));

    $this->assertDatabaseHas('semesters', [
        'academic_year_id' => $ay->id,
        'semester_number'  => 1,
    ]);
});

it('teacher cannot create a semester (403)', function () {
    $teacher = semesterTeacher();
    $ay = AcademicYear::factory()->create();

    $this->actingAs($teacher)
        ->post(route('academic-years.semesters.store', $ay), [
            'semester_number' => 1,
            'start_date'      => '2026-07-01',
            'end_date'        => '2026-12-20',
        ])
        ->assertForbidden();
});

it('store validates semester_number is 1 or 2', function () {
    $admin = semesterAdmin();
    $ay = AcademicYear::factory()->create();

    $this->actingAs($admin)
        ->post(route('academic-years.semesters.store', $ay), [
            'semester_number' => 3,
            'start_date'      => '2026-07-01',
            'end_date'        => '2026-12-20',
        ])
        ->assertSessionHasErrors(['semester_number']);
});

it('store validates uniqueness of semester_number within academic year', function () {
    $admin = semesterAdmin();
    $ay = AcademicYear::factory()->create();
    Semester::factory()->create(['academic_year_id' => $ay->id, 'semester_number' => 1]);

    $this->actingAs($admin)
        ->post(route('academic-years.semesters.store', $ay), [
            'semester_number' => 1,
            'start_date'      => '2026-07-01',
            'end_date'        => '2026-12-20',
        ])
        ->assertSessionHasErrors(['semester_number']);
});

it('store validates end_date must be after start_date', function () {
    $admin = semesterAdmin();
    $ay = AcademicYear::factory()->create();

    $this->actingAs($admin)
        ->post(route('academic-years.semesters.store', $ay), [
            'semester_number' => 1,
            'start_date'      => '2026-12-01',
            'end_date'        => '2026-07-01',
        ])
        ->assertSessionHasErrors(['end_date']);
});

// ── update ────────────────────────────────────────────────────────────

it('admin can update a semester', function () {
    $admin = semesterAdmin();
    $ay = AcademicYear::factory()->create();
    $sem = Semester::factory()->create([
        'academic_year_id' => $ay->id,
        'semester_number'  => 1,
        'start_date'       => '2026-07-01',
        'end_date'         => '2026-12-20',
    ]);

    $this->actingAs($admin)
        ->put(route('semesters.update', $sem), [
            'semester_number' => 1,
            'start_date'      => '2026-07-01',
            'end_date'        => '2026-12-31',
        ])
        ->assertRedirect(route('academic-years.semesters.index', $ay));

    expect($sem->fresh()->end_date->toDateString())->toBe('2026-12-31');
});

// ── destroy ───────────────────────────────────────────────────────────

it('admin can delete a semester with no dependents', function () {
    $admin = semesterAdmin();
    $ay = AcademicYear::factory()->create();
    $sem = Semester::factory()->create(['academic_year_id' => $ay->id, 'semester_number' => 1]);

    $this->actingAs($admin)
        ->delete(route('semesters.destroy', $sem))
        ->assertRedirect(route('academic-years.semesters.index', $ay));

    $this->assertDatabaseMissing('semesters', ['id' => $sem->id]);
});

// ── activate ──────────────────────────────────────────────────────────

it('activate sets semester active and deactivates siblings', function () {
    $admin = semesterAdmin();
    $ay = AcademicYear::factory()->create();
    $sem1 = Semester::factory()->create([
        'academic_year_id' => $ay->id,
        'semester_number'  => 1,
        'is_active'        => true,
    ]);
    $sem2 = Semester::factory()->create([
        'academic_year_id' => $ay->id,
        'semester_number'  => 2,
        'is_active'        => false,
    ]);

    $this->actingAs($admin)
        ->post(route('semesters.activate', $sem2))
        ->assertRedirect(route('academic-years.semesters.index', $ay));

    expect($sem1->fresh()->is_active)->toBeFalse();
    expect($sem2->fresh()->is_active)->toBeTrue();
});

it('teacher cannot activate a semester (403)', function () {
    $teacher = semesterTeacher();
    $ay = AcademicYear::factory()->create();
    $sem = Semester::factory()->create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => false]);

    $this->actingAs($teacher)
        ->post(route('semesters.activate', $sem))
        ->assertForbidden();
});
