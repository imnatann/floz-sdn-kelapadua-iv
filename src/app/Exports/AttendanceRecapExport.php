<?php

namespace App\Exports;

use App\Exports\Sheets\ClassAttendanceSheet;
use App\Models\SchoolClass;
use App\Models\Semester;
use Maatwebsite\Excel\Concerns\WithMultipleSheets;

class AttendanceRecapExport implements WithMultipleSheets
{
    public function __construct(private readonly int $semesterId) {}

    public function sheets(): array
    {
        $sem     = Semester::with('academicYear')->findOrFail($this->semesterId);
        $ayId    = $sem->academicYear->id;
        $classes = SchoolClass::where('academic_year_id', $ayId)->orderBy('name')->get();

        return $classes->map(fn ($class) =>
            new ClassAttendanceSheet($class, $this->semesterId)
        )->all();
    }
}
