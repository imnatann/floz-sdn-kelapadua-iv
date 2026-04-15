<?php

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

it('creates a user with all required fields', function () {
    $user = User::factory()->create();

    expect($user->name)->not->toBeEmpty();
    expect($user->email)->toContain('@');
    expect($user->role)->toBeInstanceOf(UserRole::class);
    expect($user->is_active)->toBeTrue();
});

it('can create a student via state', function () {
    $user = User::factory()->student()->create();
    expect($user->role)->toBe(UserRole::Student);
});

it('can create a teacher via state', function () {
    $user = User::factory()->teacher()->create();
    expect($user->role)->toBe(UserRole::Teacher);
});

it('can create an inactive user via state', function () {
    $user = User::factory()->inactive()->create();
    expect($user->is_active)->toBeFalse();
});

it('can create a parent via state', function () {
    $user = User::factory()->parent()->create();
    expect($user->role)->toBe(UserRole::Parent);
});
