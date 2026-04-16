<?php

namespace App\Services\Mobile;

use App\Models\TeachingAssignment;
use App\Models\User;

class TeacherClassService
{
    /**
     * Return all teaching assignments for the authenticated teacher.
     *
     * @return array<int, array{id:int, subject_name:string, class_name:string, academic_year:string, student_count:int, meeting_count:int}>
     */
    public function listForTeacher(User $user): array
    {
        $teacher = $user->teacher;

        if (! $teacher) {
            return [];
        }

        $assignments = TeachingAssignment::query()
            ->where('teacher_id', $teacher->id)
            ->with(['subject', 'schoolClass', 'academicYear'])
            ->withCount('meetings')
            ->get();

        return $assignments->map(function (TeachingAssignment $ta) {
            return [
                'id'            => $ta->id,
                'subject_name'  => $ta->subject->name ?? '-',
                'class_name'    => $ta->schoolClass->name ?? '-',
                'academic_year' => $ta->academicYear->name ?? '-',
                'student_count' => $ta->schoolClass ? $ta->schoolClass->students()->count() : 0,
                'meeting_count' => $ta->meetings_count,
            ];
        })->all();
    }

    /**
     * Return meetings for a teaching assignment, with teacher ownership check.
     *
     * Returns null if the TA does not belong to the authenticated teacher.
     *
     * @return array{teaching_assignment:array, meetings:array}|null
     */
    public function meetingsForTeachingAssignment(User $user, int $taId): ?array
    {
        $teacher = $user->teacher;

        if (! $teacher) {
            return null;
        }

        $ta = TeachingAssignment::with([
            'subject',
            'schoolClass',
            'meetings' => fn ($q) => $q->withCount(['materials', 'assignments'])->orderBy('meeting_number'),
        ])->find($taId);

        if (! $ta || $ta->teacher_id !== $teacher->id) {
            return null;
        }

        return [
            'teaching_assignment' => [
                'id'           => $ta->id,
                'subject_name' => $ta->subject->name ?? '-',
                'class_name'   => $ta->schoolClass->name ?? '-',
            ],
            'meetings' => $ta->meetings->map(function ($meeting) {
                return [
                    'id'               => $meeting->id,
                    'meeting_number'   => $meeting->meeting_number,
                    'title'            => $meeting->title,
                    'description'      => $meeting->description,
                    'is_locked'        => (bool) $meeting->is_locked,
                    'material_count'   => $meeting->materials_count,
                    'assignment_count' => $meeting->assignments_count,
                ];
            })->all(),
        ];
    }
}
