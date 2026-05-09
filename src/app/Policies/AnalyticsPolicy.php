<?php

namespace App\Policies;

use App\Models\SchoolClass;
use App\Models\TeachingAssignment;
use App\Models\User;

class AnalyticsPolicy
{
    /**
     * Any user with at least 1 owned class scope can view analytics.
     * Admin always allowed. Non-teacher always denied.
     */
    public function view(User $user): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        if (! $user->isTeacher()) {
            return false;
        }

        $teacher = $user->teacher;

        if (! $teacher) {
            return false;
        }

        $hasHomeroom = SchoolClass::where('homeroom_teacher_id', $teacher->id)->exists();
        $hasTA       = TeachingAssignment::where('teacher_id', $teacher->id)->exists();

        return $hasHomeroom || $hasTA;
    }

    /**
     * Widget-level gate — admin-only widgets: classesMissingAttendance, teacherWorkload.
     *
     * @param  User    $user
     * @param  string  $widget  Widget key (kebab-case, matches route param)
     */
    public function viewWidget(User $user, string $widget): bool
    {
        $adminOnly = ['classes-missing-attendance', 'teacher-workload'];

        if (in_array($widget, $adminOnly, true)) {
            return $user->isSchoolAdmin();
        }

        return true; // other widgets gated only by view()
    }
}
