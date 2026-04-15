<?php

namespace App\Policies;

use App\Models\Announcement;
use App\Models\User;

class AnnouncementPolicy
{
    /**
     * Any authenticated user can list announcements.
     */
    public function viewAny(User $user): bool
    {
        return true;
    }

    /**
     * Determine if the user can view a specific announcement.
     *
     * School admins always have access. For role-scoped announcements
     * (target_audience = 'teachers' or 'students'), only the matching
     * role may view. 'all' is visible to everyone.
     */
    public function view(User $user, Announcement $announcement): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        $audience = $announcement->target_audience ?? 'all';

        if ($audience === 'all') {
            return true;
        }

        if ($audience === 'teachers') {
            return $user->isTeacher();
        }

        if ($audience === 'students') {
            return $user->isStudent();
        }

        return false;
    }

    /**
     * School admins and teachers may create announcements.
     */
    public function create(User $user): bool
    {
        return $user->isSchoolAdmin() || $user->isTeacher();
    }

    /**
     * School admins may update any announcement.
     * Teachers and other users may only update announcements they authored.
     */
    public function update(User $user, Announcement $announcement): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        return $user->id === $announcement->user_id;
    }

    /**
     * Delete follows the same rules as update.
     */
    public function delete(User $user, Announcement $announcement): bool
    {
        return $this->update($user, $announcement);
    }
}
