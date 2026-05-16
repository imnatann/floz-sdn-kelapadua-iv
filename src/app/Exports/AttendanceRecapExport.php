<?php

namespace App\Exports;

use App\Exports\Sheets\ClassAttendanceSheet;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\TeachingAssignment;
use App\Models\User;
use Maatwebsite\Excel\Concerns\WithMultipleSheets;

class AttendanceRecapExport implements WithMultipleSheets
{
    public function __construct(
        private readonly int $semesterId,
        private readonly ?User $scope = null,
    ) {}

    public function sheets(): array
    {
        $sem   = Semester::with('academicYear')->findOrFail($this->semesterId);
        $ayId  = $sem->academicYear->id;

        $query = SchoolClass::where('academic_year_id', $ayId)->orderBy('name');

        if ($this->scope !== null && ! $this->scope->isSchoolAdmin()) {
            $teacher  = $this->scope->teacher;
            if ($teacher) {
                $homeroom = SchoolClass::where('homeroom_teacher_id', $teacher->id)->pluck('id');
                $taught   = TeachingAssignment::where('teacher_id', $teacher->id)->pluck('class_id');
                $visible  = $homeroom->merge($taught)->unique()->values()->all();
                $query->whereIn('id', $visible);
            } else {
                // Teacher with no Teacher record — return no sheets
                return [];
            }
        }

        $classes = $query->get();

        return $classes->map(fn ($class) =>
            new ClassAttendanceSheet($class, $this->semesterId)
        )->all();
    }
}
