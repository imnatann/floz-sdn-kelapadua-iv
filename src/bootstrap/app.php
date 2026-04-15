<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        channels: __DIR__.'/../routes/channels.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->web(append: [
            \App\Http\Middleware\HandleInertiaRequests::class,
        ]);

        $middleware->api(prepend: [
            \App\Http\Middleware\ForceJsonResponse::class,
        ]);

        $middleware->alias([
            'role' => \App\Http\Middleware\EnsureRole::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->reportable(function (\Illuminate\Validation\ValidationException $e) {
            \Illuminate\Support\Facades\Log::error('Validation Failed: ' . json_encode($e->errors()));
        });

        $exceptions->render(function (\Throwable $e, \Illuminate\Http\Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            return match (true) {
                $e instanceof \Illuminate\Validation\ValidationException => response()->json([
                    'message' => $e->getMessage(),
                    'errors'  => $e->errors(),
                    'code'    => 'VALIDATION_ERROR',
                ], 422),

                $e instanceof \Illuminate\Auth\AuthenticationException => response()->json([
                    'message' => 'Tidak terautentikasi.',
                    'code'    => 'UNAUTHENTICATED',
                ], 401),

                $e instanceof \Illuminate\Auth\Access\AuthorizationException => response()->json([
                    'message' => $e->getMessage() ?: 'Akses ditolak.',
                    'code'    => 'FORBIDDEN',
                ], 403),

                $e instanceof \Illuminate\Database\Eloquent\ModelNotFoundException,
                $e instanceof \Symfony\Component\HttpKernel\Exception\NotFoundHttpException => response()->json([
                    'message' => $e->getMessage() ?: 'Sumber daya tidak ditemukan.',
                    'code'    => 'NOT_FOUND',
                ], 404),

                $e instanceof \Illuminate\Http\Exceptions\ThrottleRequestsException => response()->json([
                    'message' => 'Terlalu banyak permintaan. Coba lagi nanti.',
                    'code'    => 'RATE_LIMITED',
                ], 429),

                $e instanceof \Symfony\Component\HttpKernel\Exception\HttpException => response()->json([
                    'message' => $e->getMessage() ?: 'Permintaan tidak valid.',
                    'code'    => 'HTTP_ERROR',
                ], $e->getStatusCode()),

                default => response()->json([
                    'message' => app()->isProduction() ? 'Terjadi kesalahan server.' : $e->getMessage(),
                    'code'    => 'SERVER_ERROR',
                ], 500),
            };
        });
    })->create();
