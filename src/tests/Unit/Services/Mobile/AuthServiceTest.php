<?php

use App\Enums\UserRole;
use App\Models\User;
use App\Services\Mobile\AuthService;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new AuthService();
});

it('returns user + token on valid credentials', function () {
    $user = User::factory()->student()->create([
        'email' => 'siswa@example.com',
        'password' => bcrypt('rahasia123'),
    ]);

    $result = $this->service->login('siswa@example.com', 'rahasia123');

    expect($result)->toHaveKeys(['user', 'token']);
    expect($result['user']->id)->toBe($user->id);
    expect($result['token'])->toBeString()->not->toBeEmpty();
});

it('throws AuthenticationException on wrong password', function () {
    User::factory()->student()->create([
        'email' => 'siswa@example.com',
        'password' => bcrypt('rahasia123'),
    ]);

    $this->service->login('siswa@example.com', 'salah');
})->throws(AuthenticationException::class);

it('throws AuthenticationException on unknown email', function () {
    $this->service->login('nobody@example.com', 'whatever');
})->throws(AuthenticationException::class);

it('throws AuthorizationException for inactive user', function () {
    User::factory()->student()->inactive()->create([
        'email' => 'inactive@example.com',
        'password' => bcrypt('rahasia123'),
    ]);

    $this->service->login('inactive@example.com', 'rahasia123');
})->throws(AuthorizationException::class);

it('throws AuthorizationException for parent role with specific message', function () {
    User::factory()->parent()->create([
        'email' => 'ortu@example.com',
        'password' => bcrypt('rahasia123'),
    ]);

    try {
        $this->service->login('ortu@example.com', 'rahasia123');
        expect(false)->toBeTrue('Should have thrown');
    } catch (AuthorizationException $e) {
        expect($e->getMessage())->toBe('Akun parent belum didukung di mobile saat ini.');
    }
});

it('revokes existing mobile tokens on new login (single device)', function () {
    $user = User::factory()->student()->create([
        'email' => 'siswa@example.com',
        'password' => bcrypt('rahasia123'),
    ]);

    $first = $this->service->login('siswa@example.com', 'rahasia123');
    $second = $this->service->login('siswa@example.com', 'rahasia123');

    expect($user->fresh()->tokens()->where('name', 'mobile')->count())->toBe(1);
    expect($first['token'])->not->toBe($second['token']);
});
