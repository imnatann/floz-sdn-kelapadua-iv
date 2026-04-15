<?php

namespace App\Services\Mobile;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\Hash;

class AuthService
{
    /**
     * @return array{user: User, token: string}
     */
    public function login(string $email, string $password): array
    {
        $user = User::where('email', $email)->first();

        if (! $user || ! Hash::check($password, $user->password)) {
            throw new AuthenticationException('Email atau password salah.');
        }

        if (! $user->is_active) {
            throw new AuthorizationException('Akun Anda tidak aktif. Hubungi administrator.');
        }

        if ($user->role === UserRole::Parent) {
            throw new AuthorizationException('Akun parent belum didukung di mobile saat ini.');
        }

        // Single-device policy: revoke prior mobile tokens
        $user->tokens()->where('name', 'mobile')->delete();

        $token = $user->createToken('mobile')->plainTextToken;

        return ['user' => $user, 'token' => $token];
    }

    public function logout(User $user): void
    {
        $user->currentAccessToken()?->delete();
    }
}
