<?php

namespace App\Policies;

use App\Models\Meeting;
use App\Models\User;
use App\Models\TeachingAssignment;

class MeetingPolicy
{
    /**
     * Can the user view the course page (all meetings for a teaching assignment)?
     */
    public function viewCourse(User $user, TeachingAssignment $teachingAssignment): bool
    {
        if ($user->isTeacher()) {
            // Teachers can view their own teaching assignments
            return $user->teacher && $user->teacher->id === $teachingAssignment->teacher_id;
        }

        if ($user->isStudent() && $user->student) {
            // Students can view courses assigned to their class
            return $teachingAssignment->class_id === $user->student->class_id;
        }

        return false;
    }

    /**
     * Can the user view a specific meeting?
     */
    public function view(User $user, Meeting $meeting): bool
    {
        $ta = $meeting->teachingAssignment;

        if ($user->isTeacher()) {
            return $user->teacher && $user->teacher->id === $ta->teacher_id;
        }

        if ($user->isStudent() && $user->student) {
            // Student must be in the right class AND meeting must be unlocked
            return $ta->class_id === $user->student->class_id && !$meeting->is_locked;
        }

        return false;
    }

    /**
     * Can the user update a meeting (title, description, lock/unlock)?
     */
    public function update(User $user, Meeting $meeting): bool
    {
        if (!$user->isTeacher() || !$user->teacher) {
            return false;
        }

        return $user->teacher->id === $meeting->teachingAssignment->teacher_id;
    }

    /**
     * Can the user manage materials (add/delete) in a meeting?
     */
    public function manageMaterial(User $user, Meeting $meeting): bool
    {
        return $this->update($user, $meeting);
    }

    /**
     * Can the user create an assignment inside a meeting?
     */
    public function createAssignment(User $user, Meeting $meeting): bool
    {
        return $this->update($user, $meeting);
    }
}
