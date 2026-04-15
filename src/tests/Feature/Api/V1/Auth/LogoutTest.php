<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('revokes the current token on logout', function () {
    $user = User::factory()->student()->create();
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson('/api/v1/auth/logout')
        ->assertNoContent();

    expect($user->fresh()->tokens()->count())->toBe(0);
});

it('returns 401 when called without a token', function () {
    $this->postJson('/api/v1/auth/logout')->assertUnauthorized();
});
