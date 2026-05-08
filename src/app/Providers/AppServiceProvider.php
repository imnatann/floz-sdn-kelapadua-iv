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

        // Gate definition for analytics (model-less policy — WARN-4: use Gate::define, not Gate::policy)
        Gate::define('view-analytics', fn (User $user) => $user->isSchoolAdmin());

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
