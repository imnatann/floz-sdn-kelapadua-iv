<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\User;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

// ── helpers ──────────────────────────────────────────────────────────

function adminUser(): User
{
    return User::factory()->create(['role' => 'school_admin']);
}

function teacherUser(): User
{
    return User::factory()->create(['role' => 'teacher']);
}

// ── index ─────────────────────────────────────────────────────────────

it('admin can view academic years index', function () {
    $admin = adminUser();
    AcademicYear::factory()->count(3)->create();

    $this->actingAs($admin)
        ->get(route('academic-years.index'))
        ->assertOk()
        ->assertInertia(fn ($page) => $page
            ->component('AcademicYears/Index')
            ->has('academicYears.data', 3)
        );
});

it('teacher can view academic years index (read-only)', function () {
    $teacher = teacherUser();
    $this->actingAs($teacher)
        ->get(route('academic-years.index'))
        ->assertOk();
});

it('guest is redirected to login', function () {
    $this->get(route('academic-years.index'))
        ->assertRedirect(route('login'));
});

// ── store ─────────────────────────────────────────────────────────────

it('admin can create an academic year', function () {
    $admin = adminUser();

    $this->actingAs($admin)
        ->post(route('academic-years.store'), [
            'name'       => '2026/2027',
            'start_date' => '2026-07-13',
            'end_date'   => '2027-06-18',
            'is_active'  => false,
        ])
        ->assertRedirect(route('academic-years.index'));

    $this->assertDatabaseHas('academic_years', ['name' => '2026/2027']);
});

it('teacher cannot create an academic year (403)', function () {
    $teacher = teacherUser();

    $this->actingAs($teacher)
        ->post(route('academic-years.store'), [
            'name'       => '2026/2027',
            'start_date' => '2026-07-13',
            'end_date'   => '2027-06-18',
        ])
        ->assertForbidden();
});

it('store validates required fields', function () {
    $admin = adminUser();

    $this->actingAs($admin)
        ->post(route('academic-years.store'), [])
        ->assertSessionHasErrors(['name', 'start_date', 'end_date']);
});

it('store validates end_date must be after start_date', function () {
    $admin = adminUser();

    $this->actingAs($admin)
        ->post(route('academic-years.store'), [
            'name'       => '2026/2027',
            'start_date' => '2026-12-01',
            'end_date'   => '2026-07-01', // before start
        ])
        ->assertSessionHasErrors(['end_date']);
});

it('store validates name uniqueness', function () {
    $admin = adminUser();
    AcademicYear::factory()->create(['name' => '2026/2027']);

    $this->actingAs($admin)
        ->post(route('academic-years.store'), [
            'name'       => '2026/2027',
            'start_date' => '2026-07-13',
            'end_date'   => '2027-06-18',
        ])
        ->assertSessionHasErrors(['name']);
});

it('enforces unique name on create', function () {
    $admin = adminUser();
    AcademicYear::factory()->create(['name' => '2024/2025 - Ganjil']);

    $this->actingAs($admin)
        ->post(route('academic-years.store'), [
            'name'       => '2024/2025 - Ganjil',
            'start_date' => '2024-07-15',
            'end_date'   => '2025-01-10',
        ])
        ->assertSessionHasErrors(['name']);
});

it('enforces unique name on update rejects another row name', function () {
    $admin = adminUser();
    AcademicYear::factory()->create(['name' => '2024/2025 - Ganjil']);
    $ay2 = AcademicYear::factory()->create(['name' => '2024/2025 - Genap']);

    $this->actingAs($admin)
        ->put(route('academic-years.update', $ay2), [
            'name'       => '2024/2025 - Ganjil', // taken by ay1
            'start_date' => $ay2->start_date->toDateString(),
            'end_date'   => $ay2->end_date->toDateString(),
        ])
        ->assertSessionHasErrors(['name']);
});

it('allows update keeping own name', function () {
    $admin = adminUser();
    $ay = AcademicYear::factory()->create(['name' => '2024/2025 - Ganjil']);

    $this->actingAs($admin)
        ->put(route('academic-years.update', $ay), [
            'name'       => '2024/2025 - Ganjil', // same name, same row — OK
            'start_date' => $ay->start_date->toDateString(),
            'end_date'   => $ay->end_date->toDateString(),
        ])
        ->assertRedirect(route('academic-years.index'));
});

// ── update ────────────────────────────────────────────────────────────

it('admin can update an academic year', function () {
    $admin = adminUser();
    $ay = AcademicYear::factory()->create(['name' => 'Old Name']);

    $this->actingAs($admin)
        ->put(route('academic-years.update', $ay), [
            'name'       => 'New Name',
            'start_date' => $ay->start_date->toDateString(),
            'end_date'   => $ay->end_date->toDateString(),
        ])
        ->assertRedirect(route('academic-years.index'));

    $this->assertDatabaseHas('academic_years', ['id' => $ay->id, 'name' => 'New Name']);
});

it('teacher cannot update an academic year (403)', function () {
    $teacher = teacherUser();
    $ay = AcademicYear::factory()->create();

    $this->actingAs($teacher)
        ->put(route('academic-years.update', $ay), ['name' => 'Hack'])
        ->assertForbidden();
});

// ── destroy ───────────────────────────────────────────────────────────

it('admin can delete an academic year with no dependents', function () {
    $admin = adminUser();
    $ay = AcademicYear::factory()->create();

    $this->actingAs($admin)
        ->delete(route('academic-years.destroy', $ay))
        ->assertRedirect(route('academic-years.index'));

    $this->assertDatabaseMissing('academic_years', ['id' => $ay->id]);
});

it('delete returns 422 with message when academic year has classes', function () {
    $admin = adminUser();
    $ay = AcademicYear::factory()->create();
    SchoolClass::factory()->create(['academic_year_id' => $ay->id]);

    $this->actingAs($admin)
        ->delete(route('academic-years.destroy', $ay))
        ->assertStatus(422)
        ->assertSessionHasErrors(['message']);
});

// ── activate ──────────────────────────────────────────────────────────

it('activate sets target year active and deactivates all others atomically', function () {
    $admin = adminUser();
    $ay1 = AcademicYear::factory()->create(['is_active' => true]);
    $ay2 = AcademicYear::factory()->create(['is_active' => false]);

    $this->actingAs($admin)
        ->post(route('academic-years.activate', $ay2))
        ->assertRedirect(route('academic-years.index'));

    expect($ay1->fresh()->is_active)->toBeFalse();
    expect($ay2->fresh()->is_active)->toBeTrue();
});

it('teacher cannot activate an academic year (403)', function () {
    $teacher = teacherUser();
    $ay = AcademicYear::factory()->create(['is_active' => false]);

    $this->actingAs($teacher)
        ->post(route('academic-years.activate', $ay))
        ->assertForbidden();
});
