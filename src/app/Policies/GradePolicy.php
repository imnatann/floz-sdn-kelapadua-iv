<?php

namespace App\Policies;

use App\Models\Grade;
use App\Models\User;

class GradePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isSchoolAdmin() || $user->isTeacher() || $user->isStudent();
    }

    public function view(User $user, Grade $grade): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        if ($user->isStudent() && $user->student) {
            return $grade->student_id === $user->student->id;
        }

        if ($user->isTeacher() && $user->teacher) {
            return $user->teacher->teachingAssignments()
                ->where('subject_id', $grade->subject_id)
                ->whereHas('schoolClass.students', fn ($q) => $q->where('students.id', $grade->student_id)
                )
                ->exists();
        }

        return false;
    }

    public function create(User $user): bool
    {
        return $user->isSchoolAdmin() || $user->isTeacher();
    }

    public function update(User $user, Grade $grade): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        if ($user->isTeacher() && $user->teacher) {
            return $user->teacher->teachingAssignments()
                ->where('subject_id', $grade->subject_id)
                ->whereHas('schoolClass.students', fn ($q) => $q->where('students.id', $grade->student_id)
                )
                ->exists();
        }

        return false;
    }

    public function delete(User $user, Grade $grade): bool
    {
        return $user->isSchoolAdmin();
    }
}
