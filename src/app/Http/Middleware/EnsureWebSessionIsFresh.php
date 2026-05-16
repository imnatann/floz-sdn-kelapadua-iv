<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Date;
use Symfony\Component\HttpFoundation\Response;

class EnsureWebSessionIsFresh
{
    public const EXPIRES_AT_SESSION_KEY = 'auth_session_expires_at';

    public static function timeoutSeconds(): int
    {
        $seconds = config('session.auth_timeout_seconds');

        if ($seconds !== null && $seconds !== '') {
            return max(1, (int) $seconds);
        }

        return max(60, (int) config('session.auth_timeout_minutes', 15) * 60);
    }

    public static function extendGraceSeconds(): int
    {
        $seconds = config('session.auth_extend_grace_seconds');

        if ($seconds !== null && $seconds !== '') {
            return max(1, (int) $seconds);
        }

        return max(60, (int) config('session.auth_extend_grace_minutes', 5) * 60);
    }

    public static function startFreshWindow(Request $request): int
    {
        $expiresAt = Date::now()->getTimestamp() + self::timeoutSeconds();

        $request->session()->put(self::EXPIRES_AT_SESSION_KEY, $expiresAt);

        return $expiresAt;
    }

    public static function logoutExpired(Request $request): void
    {
        Auth::guard()->logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();
    }

    public function handle(Request $request, Closure $next): Response
    {
        if (! Auth::check()) {
            return $next($request);
        }

        $expiresAt = (int) $request->session()->get(self::EXPIRES_AT_SESSION_KEY, 0);

        if ($expiresAt === 0) {
            self::startFreshWindow($request);

            return $next($request);
        }

        if (Date::now()->getTimestamp() > $expiresAt) {
            self::logoutExpired($request);

            if ($request->expectsJson()) {
                return response()->json([
                    'message' => 'Sesi Anda telah berakhir. Silakan login kembali.',
                    'code' => 'SESSION_EXPIRED',
                ], 401);
            }

            return redirect()
                ->route('login')
                ->with('error', 'Sesi Anda telah berakhir. Silakan login kembali.');
        }

        return $next($request);
    }
}
