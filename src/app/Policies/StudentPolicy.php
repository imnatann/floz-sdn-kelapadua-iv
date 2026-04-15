<?php

namespace App\Policies;

use App\Models\Student;
use App\Models\User;

class StudentPolicy
{
    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        // Admin and Teacher can list students.
        // Student/Parent cannot list ALL students.
        return $user->isSchoolAdmin() || $user->isTeacher();
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User $user, Student $student): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        if ($user->isTeacher()) {
            // Teacher can generally view any student in the school
            // Or restrict to classes they teach? For now, allow all teachers to see students.
            return true;
        }

        if ($user->isStudent()) {
            // Check if the user's email matches the student's email
            // This links the User account to the Student record via email
            return $user->email === $student->email;
        }

        // Parents logic here (later)
        return false;
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        return $user->isSchoolAdmin();
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, Student $student): bool
    {
        return $user->isSchoolAdmin();
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, Student $student): bool
    {
        return $user->isSchoolAdmin();
    }
}
