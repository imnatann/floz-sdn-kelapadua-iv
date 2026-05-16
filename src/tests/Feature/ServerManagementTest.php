<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('allows school admin to view server management page', function () {
    $admin = User::factory()->schoolAdmin()->create();

    $this->actingAs($admin)
        ->get(route('server-management.index'))
        ->assertOk()
        ->assertInertia(fn ($page) => $page
            ->component('ServerManagement/Index')
            ->has('summary.status')
            ->has('resources.partition')
            ->has('resources.php')
            ->has('database')
            ->has('services', 5)
        );
});

it('blocks non admin users from server management page', function () {
    $teacher = User::factory()->teacher()->create();

    $this->actingAs($teacher)
        ->get(route('server-management.index'))
        ->assertForbidden();
});

it('redirects guests to login for server management page', function () {
    $this->get(route('server-management.index'))
        ->assertRedirect(route('login'));
});
