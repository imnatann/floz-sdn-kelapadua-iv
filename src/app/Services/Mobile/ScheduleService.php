<?php

namespace App\Services\Mobile;

use App\Models\Schedule;
use App\Models\User;

class ScheduleService
{
    /**
     * Indonesian day-of-week labels keyed by ISO day number (1=Mon, 7=Sun).
     */
    private const DAY_NAMES = [
        1 => 'Senin',
        2 => 'Selasa',
        3 => 'Rabu',
        4 => 'Kamis',
        5 => 'Jumat',
        6 => 'Sabtu',
        7 => 'Minggu',
    ];

    /**
     * Build weekly schedule payload for an authenticated student.
     *
     * @return array<int, array{day:int, day_name:string, items: array<int, array<string,mixed>>}>
     */
    public function forStudent(User $user): array
    {
        $student = $user->student;
        if (! $student || ! $student->class_id) {
            return [];
        }

        $grouped = Schedule::query()
            ->whereHas(
                'teachingAssignment',
                fn ($q) => $q->where('class_id', $student->class_id)
            )
            ->with(['teachingAssignment.subject', 'teachingAssignment.teacher'])
            ->orderBy('day_of_week')
            ->orderBy('start_time')
            ->get()
            ->groupBy('day_of_week');

        $result = [];
        foreach ($grouped as $day => $items) {
            $result[] = [
                'day' => (int) $day,
                'day_name' => self::DAY_NAMES[(int) $day] ?? 'Hari',
                'items' => $items
                    ->map(fn (Schedule $s) => [
                        'id' => (string) $s->id,
                        'start_time' => $this->formatTime($s->start_time),
                        'end_time' => $this->formatTime($s->end_time),
                        'subject' => $s->teachingAssignment->subject->name ?? '-',
                        'teacher' => $s->teachingAssignment->teacher->name ?? '-',
                    ])
                    ->values()
                    ->all(),
            ];
        }

        return $result;
    }

    /**
     * Normalize time values from Eloquent to a 5-char 'HH:mm' string.
     * Handles Carbon instances (from datetime:H:i cast) AND raw strings.
     */
    private function formatTime(mixed $value): string
    {
        if ($value instanceof \DateTimeInterface) {
            return $value->format('H:i');
        }
        $str = (string) $value;
        return strlen($str) >= 5 ? substr($str, 0, 5) : $str;
    }
}
