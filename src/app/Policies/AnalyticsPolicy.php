<?php

namespace App\Policies;

use App\Models\User;

class AnalyticsPolicy
{
    public function view(User $user): bool
    {
        return $user->isSchoolAdmin();
    }
}
