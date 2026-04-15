<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class MobileAuthController extends Controller
{
    /**
     * POST /api/v1/auth/login
     * Login and issue a Sanctum token.
     */
    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Email atau password salah.',
            ], 401);
        }

        if (!$user->is_active) {
            return response()->json([
                'message' => 'Akun Anda tidak aktif. Hubungi administrator.',
            ], 403);
        }

        // Revoke old tokens (single-device policy for mobile)
        $user->tokens()->where('name', 'mobile')->delete();

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user'  => $this->formatUser($user),
        ]);
    }

    /**
     * POST /api/v1/auth/logout
     * Revoke the current token.
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Berhasil logout.',
        ]);
    }

    /**
     * GET /api/v1/auth/me
     * Return the authenticated user's profile.
     */
    public function me(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'user' => $this->formatUser($user),
        ]);
    }

    /**
     * Format user data for API response.
     */
    private function formatUser(User $user): array
    {
        $data = [
            'id'         => $user->id,
            'name'       => $user->name,
            'email'      => $user->email,
            'role'       => $user->role->value,
            'avatar_url' => $user->avatar_url,
            'is_active'  => $user->is_active,
        ];

        // Attach role-specific data
        if ($user->isStudent()) {
            $student = $user->student()->with(['class.homeroomTeacher'])->first();
            $data['student'] = $student ? [
                'id'       => $student->id,
                'nis'      => $student->nis,
                'nisn'     => $student->nisn,
                'class'    => $student->class ? [
                    'id'   => $student->class->id,
                    'name' => $student->class->name,
                    'homeroom_teacher' => $student->class->homeroomTeacher?->name,
                ] : null,
            ] : null;
        }

        if ($user->isTeacher()) {
            $teacher = $user->teacher;
            $data['teacher'] = $teacher ? [
                'id'   => $teacher->id,
                'nip'  => $teacher->nip ?? null,
                'name' => $teacher->name,
            ] : null;
        }

        return $data;
    }
}
