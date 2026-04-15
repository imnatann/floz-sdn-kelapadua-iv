<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Inertia\Inertia;

use OpenApi\Attributes as OA;

class LoginController extends Controller
{
    public function showLoginForm()
    {
        return Inertia::render('Auth/Login');
    }

    #[OA\Post(
        path: "/login",
        tags: ["Auth"],
        summary: "User Login",
        description: "Authenticate user and return redirect"
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["email", "password"],
            properties: [
                new OA\Property(property: "email", type: "string", format: "email", example: "admin@sekolah.id"),
                new OA\Property(property: "password", type: "string", format: "password", example: "secret"),
                new OA\Property(property: "remember", type: "boolean", example: false),
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Login Successful",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Login successful")
            ]
        )
    )]
    #[OA\Response(response: 401, description: "Invalid credentials")]
    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email'    => 'required|email',
            'password' => 'required',
        ]);

        $remember = $request->boolean('remember');

        if (Auth::attempt($credentials, $remember)) {
            $request->session()->regenerate();
            return \Inertia\Inertia::location(url('/dashboard'));
        }

        return back()->withErrors([
            'email' => 'Email atau password salah.',
        ]);
    }

    #[OA\Post(
        path: "/logout",
        tags: ["Auth"],
        summary: "User Logout",
        description: "Logout the authenticated user"
    )]
    #[OA\Response(response: 302, description: "Redirect to home")]
    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect('/');
    }
}
