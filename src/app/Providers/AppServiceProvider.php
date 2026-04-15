<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Gate;
use App\Models\Student;
use App\Models\Grade;
use App\Models\Teacher;
use App\Policies\StudentPolicy;
use App\Policies\GradePolicy;
use App\Policies\TeacherPolicy;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        RateLimiter::for('login', function (Request $request) {
            return Limit::perMinute(5)->by($request->ip());
        });

        RateLimiter::for('mobile-api', function (Request $request) {
            return Limit::perMinute(60)->by(optional($request->user())->id ?: $request->ip());
        });

        Gate::policy(Student::class, StudentPolicy::class);
        Gate::policy(Grade::class, GradePolicy::class);
        Gate::policy(Teacher::class, TeacherPolicy::class);
        Gate::policy(\App\Models\SchoolClass::class, \App\Policies\SchoolClassPolicy::class);
        Gate::policy(\App\Models\TeachingAssignment::class, \App\Policies\TeachingAssignmentPolicy::class);

        try { $queryLoggingEnabled = \Illuminate\Support\Facades\Cache::get('query_logging_enabled'); } catch (\Throwable) { $queryLoggingEnabled = false; }
        if ($queryLoggingEnabled) {
            \Illuminate\Support\Facades\DB::listen(function ($query) {
                $location = collect(debug_backtrace())->filter(function ($trace) {
                    return isset($trace['file']) && !str_contains($trace['file'], 'vendor/');
                })->first();

                $log = sprintf(
                    "[%s] [%s] %s [%s] (File: %s:%s)",
                    now()->format('Y-m-d H:i:s'),
                    $query->time . 'ms',
                    $query->sql,
                    implode(', ', $query->bindings),
                    $location['file'] ?? 'unknown',
                    $location['line'] ?? 'unknown'
                );

                \Illuminate\Support\Facades\File::append(
                    storage_path('logs/query-' . now()->format('Y-m-d') . '.log'),
                    $log . PHP_EOL
                );
            });
        }
    }
}
