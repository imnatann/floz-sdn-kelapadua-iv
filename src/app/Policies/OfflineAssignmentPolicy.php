<?php

namespace App\Policies;

use App\Models\OfflineAssignment;
use App\Models\User;
use Illuminate\Auth\Access\Response;

class OfflineAssignmentPolicy
{
    /**
     * Determine whether the user is a school admin, granting all access.
     */
    public function before(User $user, string $ability): ?bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        return null;
    }

    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        return $user->isTeacher() || $user->isStudent();
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User $user, OfflineAssignment $offlineAssignment): bool
    {
        if ($user->isTeacher()) {
            return true;
        }

        if ($user->isStudent() && $user->student) {
            return $offlineAssignment->classes->pluck('id')->contains($user->student->class_id);
        }

        return false;
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        return $user->isTeacher();
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, OfflineAssignment $offlineAssignment): bool
    {
        return $user->isTeacher();
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, OfflineAssignment $offlineAssignment): bool
    {
        return $user->isTeacher();
    }

    /**
     * Determine whether the user can restore the model.
     */
    public function restore(User $user, OfflineAssignment $offlineAssignment): bool
    {
        return $user->isTeacher();
    }

    /**
     * Determine whether the user can permanently delete the model.
     */
    public function forceDelete(User $user, OfflineAssignment $offlineAssignment): bool
    {
        return $user->isTeacher();
    }
    
    /**
     * Determine whether the user can submit the assignment
     */
    public function submit(User $user, OfflineAssignment $offlineAssignment): bool
    {
        if (!$user->isStudent() || !$user->student) {
            return false;
        }
        
        return $offlineAssignment->classes->pluck('id')->contains($user->student->class_id);
    }
}
