<?php

namespace App\Services\Mobile;

use App\Models\OfflineAssignment;
use App\Models\OfflineAssignmentSubmission;
use App\Models\User;
use Illuminate\Support\Str;

class AssignmentService
{
    public function listForStudent(User $user, string $status = 'upcoming'): array
    {
        $student = $user->student;

        if (! $student || ! $student->class_id) {
            return [];
        }

        $classId = $student->class_id;

        $query = OfflineAssignment::whereHas('classes', fn ($q) => $q->where('class_id', $classId))
            ->where('status', 'active')
            ->with(['subject', 'teacher']);

        if ($status === 'completed') {
            $query->whereHas('submissions', fn ($q) => $q->where('student_id', $student->id))
                  ->orderByDesc('due_date');
        } else {
            $query->whereDoesntHave('submissions', fn ($q) => $q->where('student_id', $student->id))
                  ->orderBy('due_date');
        }

        return $query->get()
            ->map(fn (OfflineAssignment $a) => [
                'id'          => $a->id,
                'title'       => $a->title,
                'description' => Str::limit(strip_tags($a->description ?? ''), 100),
                'due_date'    => $a->due_date ? $a->due_date->toISOString() : null,
                'subject'     => $a->subject->name ?? '-',
                'teacher'     => $a->teacher->name ?? '-',
                'type'        => $a->type,
            ])
            ->all();
    }

    public function detailForStudent(User $user, int $id): ?array
    {
        $student = $user->student;

        if (! $student || ! $student->class_id) {
            return null;
        }

        $assignment = OfflineAssignment::whereHas('classes', fn ($q) => $q->where('class_id', $student->class_id))
            ->where('status', 'active')
            ->with(['subject', 'teacher', 'files'])
            ->find($id);

        if (! $assignment) {
            return null;
        }

        $submission = OfflineAssignmentSubmission::where('offline_assignment_id', $assignment->id)
            ->where('student_id', $student->id)
            ->first();

        return [
            'id'          => $assignment->id,
            'title'       => $assignment->title,
            'description' => $assignment->description,
            'due_date'    => $assignment->due_date ? $assignment->due_date->toISOString() : null,
            'subject'     => $assignment->subject->name ?? '-',
            'teacher'     => $assignment->teacher->name ?? '-',
            'type'        => $assignment->type,
            'files'       => $assignment->files->map(fn ($f) => [
                'id'        => $f->id,
                'file_name' => $f->file_name,
                'file_url'  => asset('storage/' . $f->file_path),
            ])->all(),
            'submission'  => $submission ? [
                'id'           => $submission->id,
                'status'       => $submission->grade !== null ? 'graded' : 'submitted',
                'submitted_at' => $submission->submitted_at ? $submission->submitted_at->toISOString() : null,
                'score'        => $submission->grade !== null ? (int) $submission->grade : null,
                'teacher_notes' => $submission->correction_note,
            ] : null,
        ];
    }
}
