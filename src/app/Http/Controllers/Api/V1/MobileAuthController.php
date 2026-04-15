<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\LoginRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Services\Mobile\AuthService;
use Illuminate\Http\Request;

class MobileAuthController extends Controller
{
    public function __construct(private readonly AuthService $service) {}

    /**
     * POST /api/v1/auth/login
     */
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

    /**
     * POST /api/v1/auth/logout
     */
    public function logout(Request $request)
    {
        $this->service->logout($request->user());

        return response()->noContent();
    }

    /**
     * GET /api/v1/auth/me
     */
    public function me(Request $request)
    {
        return response()->json([
            'data' => (new UserResource($request->user()))->resolve(),
        ]);
    }
}
