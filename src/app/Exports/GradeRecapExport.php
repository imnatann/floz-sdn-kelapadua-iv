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
    /**
     * @param int     $classId
     * @param int     $semesterId
     * @param int[]   $subjectIds  Empty array means "all subjects taught in this class"
     * @param ?User   $scope
     */
    public function __construct(
        private readonly int $classId,
        private readonly int $semesterId,
        private readonly array $subjectIds = [],
        private readonly ?User $scope = null,
    ) {}

    public function sheets(): array
    {
        $class    = SchoolClass::findOrFail($this->classId);
        $semester = Semester::findOrFail($this->semesterId);

        if (! empty($this->subjectIds)) {
            $subjects = Subject::whereIn('id', $this->subjectIds)
                ->where('status', 'active')
                ->orderBy('name')
                ->get();
        } else {
            // All subjects taught in this class (via teaching assignments)
            $subjectIds = TeachingAssignment::where('class_id', $this->classId)
                ->pluck('subject_id')
                ->unique();
            $subjects = Subject::whereIn('id', $subjectIds)
                ->where('status', 'active')
                ->orderBy('name')
                ->get();
        }

        return $subjects->map(fn ($subject) =>
            new ClassGradeSheet($class, $semester, $subject)
        )->all();
    }
}
