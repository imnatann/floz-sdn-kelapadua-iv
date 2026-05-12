<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Gate;
use App\Models\Announcement;
use App\Models\Attendance;
use App\Models\Grade;
use App\Models\OfflineAssignment;
use App\Models\ReportCard;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use App\Models\TeachingAssignment;
use App\Policies\AnnouncementPolicy;
use App\Policies\AttendancePolicy;
use App\Policies\GradePolicy;
use App\Policies\OfflineAssignmentPolicy;
use App\Policies\ReportCardPolicy;
use App\Policies\SchoolClassPolicy;
use App\Policies\StudentPolicy;
use App\Policies\TeacherPolicy;
use App\Policies\TeachingAssignmentPolicy;
use App\Models\Meeting;
use App\Policies\MeetingPolicy;
use App\Models\AcademicYear;
use App\Policies\AcademicYearPolicy;
use App\Models\Semester;
use App\Policies\SemesterPolicy;
use App\Models\YearTransitionLog;
use App\Policies\YearTransitionPolicy;
use App\Policies\AnalyticsPolicy;

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
        // Force HTTPS scheme when request arrives via reverse proxy/tunnel
        // (ngrok, Cloudflare, etc.) which forwards X-Forwarded-Proto=https.
        // This makes Vite asset URLs use https:// and avoids browser
        // mixed-content blocks on the login page.
        $forwardedProto = request()->headers->get('X-Forwarded-Proto');
        if ($forwardedProto === 'https' || str_ends_with((string) request()->getHost(), '.ngrok-free.app')) {
            \Illuminate\Support\Facades\URL::forceScheme('https');
        }

        RateLimiter::for('login', function (Request $request) {
            return Limit::perMinute(5)->by($request->ip());
        });

        RateLimiter::for('mobile-api', function (Request $request) {
            return Limit::perMinute(60)->by(optional($request->user())->id ?: $request->ip());
        });

        Gate::policy(Student::class, StudentPolicy::class);
        Gate::policy(Grade::class, GradePolicy::class);
        Gate::policy(Teacher::class, TeacherPolicy::class);
        Gate::policy(SchoolClass::class, SchoolClassPolicy::class);
        Gate::policy(TeachingAssignment::class, TeachingAssignmentPolicy::class);
        Gate::policy(Announcement::class, AnnouncementPolicy::class);
        Gate::policy(Attendance::class, AttendancePolicy::class);
        Gate::policy(ReportCard::class, ReportCardPolicy::class);
        Gate::policy(OfflineAssignment::class, OfflineAssignmentPolicy::class);
        Gate::policy(Meeting::class, MeetingPolicy::class);
        Gate::policy(AcademicYear::class, AcademicYearPolicy::class);
        Gate::policy(Semester::class, SemesterPolicy::class);
        Gate::policy(YearTransitionLog::class, YearTransitionPolicy::class);

        // Gate definition for year transition management (used in controller + FormRequests)
        Gate::define('manage_year_transition', function (User $user) {
            return $user->isSchoolAdmin() || $user->isSuperAdmin();
        });

        // Analytics policy — registered for model-less authorization via Gate::define
        // view-analytics: used by controller $this->authorize('view-analytics')
        Gate::define('view-analytics', fn (User $user) => (new AnalyticsPolicy)->view($user));

        // viewWidget gate: controller uses Gate::allows('viewWidget', $widget)
        Gate::define('viewWidget', fn (User $user, string $widget) => (new AnalyticsPolicy)->viewWidget($user, $widget));

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
