<?php

namespace App\Services\Mobile;

use App\Models\Meeting;
use App\Models\TeachingAssignment;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;

class CoursesService
{
    /** @return array<int, array<string, mixed>> */
    public function listForStudent(User $user): array
    {
        $student = $user->student;
        if (! $student || ! $student->class_id) {
            return [];
        }

        return TeachingAssignment::where('class_id', $student->class_id)
            ->with(['subject', 'teacher'])
            ->withCount('meetings')
            ->get()
            ->map(fn (TeachingAssignment $ta) => [
                'id' => $ta->id,
                'subject_name' => $ta->subject->name ?? '-',
                'teacher_name' => $ta->teacher->name ?? '-',
                'meeting_count' => $ta->meetings_count,
                'material_count' => Meeting::where('teaching_assignment_id', $ta->id)
                    ->withCount('materials')
                    ->get()
                    ->sum('materials_count'),
            ])
            ->values()
            ->all();
    }

    public function meetingsFor(User $user, int $teachingAssignmentId): array
    {
        $student = $user->student;
        $ta = TeachingAssignment::with(['subject', 'teacher', 'schoolClass'])->findOrFail($teachingAssignmentId);
        $this->authorize($student, $ta);

        $meetings = Meeting::where('teaching_assignment_id', $ta->id)
            ->withCount('materials')
            ->orderBy('meeting_number')
            ->get()
            ->map(fn (Meeting $m) => [
                'id' => $m->id,
                'meeting_number' => $m->meeting_number,
                'title' => $m->title,
                'description' => $m->description,
                'is_locked' => (bool) $m->is_locked,
                'material_count' => $m->materials_count,
            ])
            ->all();

        return [
            'teaching_assignment' => [
                'id' => $ta->id,
                'subject_name' => $ta->subject->name ?? '-',
                'teacher_name' => $ta->teacher->name ?? '-',
                'class_name' => $ta->schoolClass->name ?? '-',
            ],
            'meetings' => $meetings,
        ];
    }

    public function meetingDetail(User $user, int $meetingId): array
    {
        $meeting = Meeting::with(['materials', 'teachingAssignment.subject', 'teachingAssignment.schoolClass'])
            ->findOrFail($meetingId);
        $this->authorize($user->student, $meeting->teachingAssignment);

        return [
            'meeting' => [
                'id' => $meeting->id,
                'meeting_number' => $meeting->meeting_number,
                'title' => $meeting->title,
                'description' => $meeting->description,
                'is_locked' => (bool) $meeting->is_locked,
                'subject_name' => $meeting->teachingAssignment->subject->name ?? '-',
                'class_name' => $meeting->teachingAssignment->schoolClass->name ?? '-',
            ],
            'materials' => $meeting->materials
                ->sortBy('sort_order')
                ->values()
                ->map(fn ($m) => [
                    'id' => $m->id,
                    'title' => $m->title,
                    'type' => $m->type,
                    'content' => $m->content,
                    'file_name' => $m->file_name,
                    'file_size' => $m->file_size,
                    'file_url' => $m->file_path ? asset('storage/'.$m->file_path) : null,
                    'url' => $m->url,
                    'sort_order' => $m->sort_order,
                ])
                ->all(),
        ];
    }

    private function authorize($student, TeachingAssignment $ta): void
    {
        if (! $student || $ta->class_id !== $student->class_id) {
            throw new AuthorizationException('Anda tidak memiliki akses ke mata pelajaran ini.');
        }
    }
}
