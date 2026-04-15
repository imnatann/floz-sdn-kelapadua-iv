<?php

namespace App\Policies;

use App\Models\ReportCard;
use App\Models\User;

class ReportCardPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isSchoolAdmin() || $user->isTeacher() || $user->isStudent();
    }

    public function view(User $user, ReportCard $card): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        if ($user->isStudent() && $user->student) {
            return $card->student_id === $user->student->id;
        }

        if ($user->isTeacher() && $user->teacher) {
            $student = $card->student;

            return $student
                && $student->class
                && $student->class->homeroom_teacher_id === $user->teacher->id;
        }

        return false;
    }

    public function download(User $user, ReportCard $card): bool
    {
        return $this->view($user, $card);
    }

    public function publish(User $user, ReportCard $card): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        if ($user->isTeacher() && $user->teacher) {
            return $card->student
                && $card->student->class
                && $card->student->class->homeroom_teacher_id === $user->teacher->id;
        }

        return false;
    }
}
