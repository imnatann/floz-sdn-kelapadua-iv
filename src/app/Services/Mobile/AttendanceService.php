<?php

namespace App\Services\Mobile;

use App\Models\Attendance;
use App\Models\Meeting;
use App\Models\Semester;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class AttendanceService
{
    public function getRoster(Meeting $meeting, User $user): array
    {
        $ta = $meeting->teachingAssignment()->with(['subject', 'schoolClass'])->first();
        $semester = $this->getActiveSemester();

        $students = $ta->schoolClass->students()
            ->where('status', 'active')
            ->orderBy('name')
            ->get()
            ->map(function ($student) use ($ta, $semester, $meeting) {
                $att = Attendance::where('student_id', $student->id)
                    ->where('class_id', $ta->class_id)
                    ->where('semester_id', $semester->id)
                    ->where('meeting_number', $meeting->meeting_number)
                    ->first();

                return [
                    'id' => $student->id,
                    'name' => $student->name,
                    'nis' => $student->nis,
                    'status' => $att?->status,
                    'note' => $att?->notes,
                ];
            })
            ->values()
            ->all();

        return [
            'meeting' => [
                'id' => $meeting->id,
                'meeting_number' => $meeting->meeting_number,
                'title' => $meeting->title,
            ],
            'class' => [
                'id' => $ta->schoolClass->id,
                'name' => $ta->schoolClass->name,
            ],
            'teaching_assignment' => [
                'id' => $ta->id,
                'subject' => [
                    'id' => $ta->subject->id,
                    'name' => $ta->subject->name,
                ],
            ],
            'students' => $students,
        ];
    }

    public function store(Meeting $meeting, array $entries, User $user): array
    {
        $ta = $meeting->teachingAssignment;
        $semester = $this->getActiveSemester();
        $teacher = $user->teacher;

        DB::transaction(function () use ($entries, $ta, $meeting, $semester, $teacher) {
            foreach ($entries as $entry) {
                Attendance::updateOrCreate(
                    [
                        'class_id' => $ta->class_id,
                        'semester_id' => $semester->id,
                        'meeting_number' => $meeting->meeting_number,
                        'student_id' => $entry['student_id'],
                    ],
                    [
                        'status' => $entry['status'],
                        'notes' => $entry['note'] ?? null,
                        'date' => now()->toDateString(),
                        'recorded_by' => $teacher?->id,
                    ]
                );
            }
        });

        return $this->getRoster($meeting, $user);
    }

    private function getActiveSemester(): Semester
    {
        $semester = Semester::where('is_active', true)->first();
        if (! $semester) {
            throw new \RuntimeException('Tidak ada semester aktif. Hubungi admin untuk mengaktifkan semester.');
        }
        return $semester;
    }
}
