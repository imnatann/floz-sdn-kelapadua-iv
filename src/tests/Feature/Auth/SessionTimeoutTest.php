<?php

use App\Http\Middleware\EnsureWebSessionIsFresh;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;

uses(RefreshDatabase::class);

beforeEach(function () {
    config([
        'session.auth_timeout_minutes' => 15,
        'session.auth_extend_grace_minutes' => 5,
        'session.auth_timeout_seconds' => null,
        'session.auth_extend_grace_seconds' => null,
    ]);

    Route::middleware(['web', 'auth', EnsureWebSessionIsFresh::class])
        ->get('/__test__/session-protected', fn () => response('ok'));
});

it('allows protected web requests before the auth session expires', function () {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->withSession([
            EnsureWebSessionIsFresh::EXPIRES_AT_SESSION_KEY => now()->addMinute()->timestamp,
        ])
        ->get('/__test__/session-protected')
        ->assertOk()
        ->assertSee('ok');
});

it('initializes the auth session window when the timestamp is missing', function () {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->get('/__test__/session-protected')
        ->assertOk()
        ->assertSessionHas(EnsureWebSessionIsFresh::EXPIRES_AT_SESSION_KEY);
});

it('redirects protected web requests to login after the auth session expires', function () {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->withSession([
            EnsureWebSessionIsFresh::EXPIRES_AT_SESSION_KEY => now()->subSecond()->timestamp,
        ])
        ->get('/__test__/session-protected')
        ->assertRedirect(route('login'))
        ->assertSessionHas('error', 'Sesi Anda telah berakhir. Silakan login kembali.');

    $this->assertGuest();
});

it('extends an expired session during the five minute grace window', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)
        ->withSession([
            EnsureWebSessionIsFresh::EXPIRES_AT_SESSION_KEY => now()->subMinute()->timestamp,
        ])
        ->postJson(route('session.extend'));

    $response
        ->assertOk()
        ->assertJson([
            'message' => 'Sesi berhasil diperpanjang.',
            'timeout_seconds' => 900,
            'extend_grace_seconds' => 300,
        ]);

    expect($response->json('expires_at'))->toBeGreaterThan(now()->timestamp);
});

it('logs out instead of extending after the grace window passes', function () {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->withSession([
            EnsureWebSessionIsFresh::EXPIRES_AT_SESSION_KEY => now()->subMinutes(6)->timestamp,
        ])
        ->postJson(route('session.extend'))
        ->assertUnauthorized()
        ->assertJson([
            'code' => 'SESSION_EXPIRED',
        ]);

    $this->assertGuest();
});

it('allows second-level overrides for fast local timeout testing', function () {
    config([
        'session.auth_timeout_seconds' => 5,
        'session.auth_extend_grace_seconds' => 5,
    ]);

    expect(EnsureWebSessionIsFresh::timeoutSeconds())->toBe(5)
        ->and(EnsureWebSessionIsFresh::extendGraceSeconds())->toBe(5);
});
