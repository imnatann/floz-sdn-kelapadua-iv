<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\Request;

class EnsureRole
{
    /**
     * @param  string  ...$roles  Allowed roles, e.g. 'teacher', 'teacher', 'school_admin'
     */
    public function handle(Request $request, Closure $next, string ...$roles)
    {
        $user = $request->user();

        if (! $user) {
            throw new AuthenticationException();
        }

        $userRole = $user->role->value;
        if (! in_array($userRole, $roles, true)) {
            throw new AuthorizationException(
                "Akses ditolak. Endpoint ini memerlukan role: " . implode(', ', $roles)
            );
        }

        return $next($request);
    }
}
