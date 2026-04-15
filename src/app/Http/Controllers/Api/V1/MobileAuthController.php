<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\LoginRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Services\Mobile\AuthService;
use Illuminate\Http\Request;
use OpenApi\Attributes as OA;

class MobileAuthController extends Controller
{
    public function __construct(private readonly AuthService $service) {}

    #[OA\Post(
        path: "/api/v1/auth/login",
        tags: ["Auth"],
        summary: "Login dan dapatkan Sanctum token",
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ["email", "password"],
                properties: [
                    new OA\Property(property: "email", type: "string", format: "email"),
                    new OA\Property(property: "password", type: "string", format: "password")
                ]
            )
        ),
        responses: [
            new OA\Response(response: 200, description: "Login berhasil"),
            new OA\Response(response: 401, description: "Email atau password salah"),
            new OA\Response(response: 403, description: "Akun tidak aktif atau parent"),
            new OA\Response(response: 422, description: "Validasi gagal"),
            new OA\Response(response: 429, description: "Rate limit exceeded")
        ]
    )]
    public function login(LoginRequest $request)
    {
        $result = $this->service->login(
            $request->validated('email'),
            $request->validated('password'),
        );

        return response()->json([
            'data' => [
                'token' => $result['token'],
                'user'  => (new UserResource($result['user']))->resolve(),
            ],
        ]);
    }

    #[OA\Post(
        path: "/api/v1/auth/logout",
        tags: ["Auth"],
        summary: "Logout (revoke current token)",
        security: [["bearerAuth" => []]],
        responses: [
            new OA\Response(response: 204, description: "Logout berhasil"),
            new OA\Response(response: 401, description: "Token tidak valid")
        ]
    )]
    public function logout(Request $request)
    {
        $this->service->logout($request->user());

        return response()->noContent();
    }

    #[OA\Get(
        path: "/api/v1/auth/me",
        tags: ["Auth"],
        summary: "Profil user yang sedang login",
        security: [["bearerAuth" => []]],
        responses: [
            new OA\Response(response: 200, description: "Profile data"),
            new OA\Response(response: 401, description: "Token tidak valid")
        ]
    )]
    public function me(Request $request)
    {
        return response()->json([
            'data' => (new UserResource($request->user()))->resolve(),
        ]);
    }
}
