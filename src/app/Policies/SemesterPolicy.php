<?php

namespace App\Policies;

use App\Models\Semester;
use App\Models\User;

class SemesterPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, Semester $semester): bool
    {
        return true;
    }

    public function create(User $user): bool
    {
        return $user->isSchoolAdmin();
    }

    public function update(User $user, Semester $semester): bool
    {
        return $user->isSchoolAdmin();
    }

    public function delete(User $user, Semester $semester): bool
    {
        return $user->isSchoolAdmin();
    }

    public function activate(User $user, Semester $semester): bool
    {
        return $user->isSchoolAdmin();
    }
}
