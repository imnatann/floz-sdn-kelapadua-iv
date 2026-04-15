<?php

namespace App\Policies;

use App\Models\TeachingAssignment;
use App\Models\User;

class TeachingAssignmentPolicy
{
    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        return $user->isSchoolAdmin();
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        return $user->isSchoolAdmin();
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, TeachingAssignment $teachingAssignment): bool
    {
        return $user->isSchoolAdmin();
    }
}
