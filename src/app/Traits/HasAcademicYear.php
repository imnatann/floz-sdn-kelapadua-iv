<?php

namespace App\Traits;

use App\Models\AcademicYear;

trait HasAcademicYear
{
    /**
     * Scope query to active academic year.
     */
    public function scopeCurrentAcademicYear($query)
    {
        $activeYear = AcademicYear::where('is_active', true)->first();

        if ($activeYear) {
            return $query->where('academic_year_id', $activeYear->id);
        }

        return $query;
    }

    /**
     * Get the current active academic year.
     */
    public static function getActiveAcademicYear(): ?AcademicYear
    {
        return AcademicYear::where('is_active', true)->first();
    }
}
