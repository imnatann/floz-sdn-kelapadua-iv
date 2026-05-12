<?php

namespace App\Exports;

use App\Exports\Sheets\ClassGradeSheet;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Subject;
use App\Models\TeachingAssignment;
use App\Models\User;
use Maatwebsite\Excel\Concerns\WithMultipleSheets;

class GradeRecapExport implements WithMultipleSheets
{
    public function __construct(
        private readonly int $classId,
        private readonly int $semesterId,
        private readonly ?int $subjectId = null,
        private readonly ?User $scope = null,
    ) {}

    public function sheets(): array
    {
        $class    = SchoolClass::findOrFail($this->classId);
        $semester = Semester::findOrFail($this->semesterId);

        if ($this->subjectId !== null) {
            $subjects = Subject::where('id', $this->subjectId)->where('status', 'active')->get();
        } else {
            // All subjects taught in this class (via teaching assignments)
            $subjectIds = TeachingAssignment::where('class_id', $this->classId)
                ->pluck('subject_id')
                ->unique();
            $subjects = Subject::whereIn('id', $subjectIds)->where('status', 'active')->orderBy('name')->get();
        }

        return $subjects->map(fn ($subject) =>
            new ClassGradeSheet($class, $semester, $subject)
        )->all();
    }
}
