<?php

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\RateLimiter;

uses(RefreshDatabase::class);

beforeEach(function () {
    // Clear rate limit state between tests to avoid leakage
    RateLimiter::clear('login|127.0.0.1');
});

it('rate limits login after 5 attempts per minute', function () {
    // 5 attempts should all return 401 (wrong creds) — NOT 429
    for ($i = 0; $i < 5; $i++) {
        $this->postJson('/api/v1/auth/login', [
            'email' => 'nope@example.com',
            'password' => 'wrongpassword',
        ])->assertStatus(401);
    }

    // 6th attempt should be rate-limited
    $this->postJson('/api/v1/auth/login', [
        'email' => 'nope@example.com',
        'password' => 'wrongpassword',
    ])->assertStatus(429);
});
