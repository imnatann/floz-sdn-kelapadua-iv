<?php

namespace App\Services\Mobile;

use App\Models\ReportCard;
use App\Models\User;

class ReportCardService
{
    public function listForStudent(User $user): array
    {
        $student = $user->student;
        if (! $student) {
            return [];
        }

        return ReportCard::where('student_id', $student->id)
            ->where('status', 'published')
            ->with('semester.academicYear')
            ->latest('published_at')
            ->get()
            ->map(fn (ReportCard $rc) => [
                'id' => $rc->id,
                'semester_name' => $rc->semester?->name ?? 'Semester',
                'academic_year' => $rc->semester?->academicYear?->name ?? '-',
                'average_score' => (float) ($rc->average_score ?? 0),
                'rank' => $rc->rank,
                'published_at' => $rc->published_at?->toIso8601String(),
            ])
            ->all();
    }

    public function detailForStudent(User $user, int $id): ?array
    {
        $student = $user->student;
        if (! $student) {
            return null;
        }

        $rc = ReportCard::where('id', $id)
            ->where('student_id', $student->id)
            ->where('status', 'published')
            ->with(['semester.academicYear', 'schoolClass'])
            ->first();

        if (! $rc) {
            return null;
        }

        return [
            'id' => $rc->id,
            'semester_name' => $rc->semester?->name ?? '-',
            'academic_year' => $rc->semester?->academicYear?->name ?? '-',
            'class_name' => $rc->schoolClass?->name ?? '-',
            'average_score' => (float) ($rc->average_score ?? 0),
            'total_score' => (float) ($rc->total_score ?? 0),
            'rank' => $rc->rank,
            'attendance_present' => (int) ($rc->attendance_present ?? 0),
            'attendance_sick' => (int) ($rc->attendance_sick ?? 0),
            'attendance_permit' => (int) ($rc->attendance_permit ?? 0),
            'attendance_absent' => (int) ($rc->attendance_absent ?? 0),
            'achievements' => $rc->achievements,
            'notes' => $rc->notes,
            'behavior_notes' => $rc->behavior_notes,
            'homeroom_comment' => $rc->homeroom_comment,
            'principal_comment' => $rc->principal_comment,
            'pdf_url' => $rc->pdf_url,
            'published_at' => $rc->published_at?->toIso8601String(),
        ];
    }

    public function pdfUrlForStudent(User $user, int $id): ?string
    {
        $student = $user->student;
        if (! $student) {
            return null;
        }

        $rc = ReportCard::where('id', $id)
            ->where('student_id', $student->id)
            ->where('status', 'published')
            ->first();

        return $rc?->pdf_url;
    }
}
