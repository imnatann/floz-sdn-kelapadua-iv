<?php

namespace App\Policies;

use App\Models\SchoolClass;
use App\Models\TeachingAssignment;
use App\Models\User;

/**
 * Backs the `view-analytics` Gate used by AnalyticsController exports
 * (exportAttendance, exportGrades). The dashboard/reports UI that consumed
 * the widget-level rules was removed — that's why this class is reduced
 * to the single view() check.
 */
class AnalyticsPolicy
{
    /**
     * Admin always allowed. Teachers allowed if they own at least one class
     * scope (homeroom or teaching assignment). Other roles denied.
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
}
