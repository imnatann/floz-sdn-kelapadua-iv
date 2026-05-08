<?php

namespace App\Policies;

use App\Models\User;

class YearTransitionPolicy
{
    /**
     * WARN-1 fix: SuperAdmin is also allowed to manage year transitions.
     */
    public function manage(User $user): bool
    {
        return $user->isSchoolAdmin() || $user->isSuperAdmin();
    }
}
