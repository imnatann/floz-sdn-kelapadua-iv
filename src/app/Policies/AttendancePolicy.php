<?php

namespace App\Policies;

use App\Models\Attendance;
use App\Models\Meeting;
use App\Models\User;

class AttendancePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isSchoolAdmin() || $user->isTeacher() || $user->isStudent();
    }

    public function view(User $user, Attendance $attendance): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        if ($user->isStudent() && $user->student) {
            return $attendance->student_id === $user->student->id;
        }

        if ($user->isTeacher() && $user->teacher) {
            return $user->teacher->teachingAssignments()
                ->where('class_id', $attendance->class_id)
                ->exists();
        }

        return false;
    }

    /**
     * Can the user record attendance for this meeting?
     */
    public function recordForMeeting(User $user, Meeting $meeting): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        if ($user->isTeacher() && $user->teacher) {
            return $meeting->teachingAssignment->teacher_id === $user->teacher->id;
        }

        return false;
    }
}
