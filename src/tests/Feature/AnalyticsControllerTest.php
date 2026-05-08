<?php

use App\Models\AcademicYear;
use App\Models\Semester;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

function analyticsAdmin(): User
{
    return User::factory()->create(['role' => 'school_admin']);
}

function analyticsTeacher(): User
{
    return User::factory()->create(['role' => 'teacher']);
}

it('teacher cannot access analytics index (403)', function () {
    Semester::factory()->create(['is_active' => true]);
    $this->actingAs(analyticsTeacher())
        ->get(route('analytics.index'))
        ->assertForbidden();
});

it('guest is redirected to login from analytics', function () {
    $this->get(route('analytics.index'))
        ->assertRedirect(route('login'));
});

it('admin can access analytics dashboard', function () {
    Semester::factory()->create(['is_active' => true]);
    $this->actingAs(analyticsAdmin())
        ->get(route('analytics.index'))
        ->assertOk()
        ->assertInertia(fn ($page) => $page->component('Analytics/Dashboard')
            ->has('todaysAttendance')
            ->has('missingAttendance')
            ->has('classAvgComparison')
        );
});

it('admin can access analytics reports page', function () {
    Semester::factory()->create(['is_active' => true]);
    $this->actingAs(analyticsAdmin())
        ->get(route('analytics.reports'))
        ->assertOk()
        ->assertInertia(fn ($page) => $page->component('Analytics/Reports'));
});

it('data endpoint returns JSON for at-risk-students widget', function () {
    $sem = Semester::factory()->create(['is_active' => true]);
    $this->actingAs(analyticsAdmin())
        ->getJson(route('analytics.data', 'at-risk-students') . "?semester_id={$sem->id}")
        ->assertOk()
        ->assertJsonStructure(['data', 'meta']);
});

it('data endpoint returns 404 for unknown widget', function () {
    Semester::factory()->create(['is_active' => true]);
    $this->actingAs(analyticsAdmin())
        ->getJson(route('analytics.data', 'nonexistent-widget'))
        ->assertNotFound();
});

it('export attendance requires semester_id', function () {
    $this->actingAs(analyticsAdmin())
        ->get(route('analytics.export.attendance'))
        ->assertSessionHasErrors(['semester_id']);
});

it('teacher cannot access analytics data endpoint (403)', function () {
    $sem = Semester::factory()->create(['is_active' => true]);
    $this->actingAs(analyticsTeacher())
        ->getJson(route('analytics.data', 'at-risk-students') . "?semester_id={$sem->id}")
        ->assertForbidden();
});
