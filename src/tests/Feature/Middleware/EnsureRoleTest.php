<?php

use App\Http\Middleware\EnsureRole;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;

uses(RefreshDatabase::class);

beforeEach(function () {
    // Define temporary routes under api/ so ForceJsonResponse middleware applies
    Route::middleware(['api', 'auth:sanctum', EnsureRole::class.':teacher'])
        ->get('/api/__test__/teacher-only', fn () => response()->json(['ok' => true]));

    Route::middleware(['api', 'auth:sanctum', EnsureRole::class.':teacher,school_admin'])
        ->get('/api/__test__/staff-only', fn () => response()->json(['ok' => true]));
});

it('allows access when user has the required role', function () {
    $teacher = User::factory()->teacher()->create();
    $this->actingAs($teacher, 'sanctum')
        ->getJson('/api/__test__/teacher-only')
        ->assertOk()
        ->assertJson(['ok' => true]);
});

it('rejects with 403 when user has the wrong role', function () {
    $student = User::factory()->student()->create();
    $this->actingAs($student, 'sanctum')
        ->getJson('/api/__test__/teacher-only')
        ->assertForbidden();
});

it('allows any role in a comma list', function () {
    $admin = User::factory()->schoolAdmin()->create();
    $this->actingAs($admin, 'sanctum')
        ->getJson('/api/__test__/staff-only')
        ->assertOk();
});

it('rejects unauthenticated requests with 401', function () {
    $this->getJson('/api/__test__/teacher-only')
        ->assertUnauthorized();
});
