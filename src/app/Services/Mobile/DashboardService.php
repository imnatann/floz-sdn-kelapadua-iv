<?php

namespace App\Services\Mobile;

use App\Models\Announcement;
use App\Models\Attendance;
use App\Models\Schedule;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;

class DashboardService
{
    /**
     * Build dashboard payload for an authenticated student.
     *
     * @return array{
     *     role: string,
     *     student: array{id:int,name:string,class:?string,homeroom_teacher:?string}|null,
     *     stats: array{attendance_percentage:int},
     *     todays_schedules: array<int, array<string,mixed>>,
     *     recent_announcements: array<int, array<string,mixed>>
     * }
     */
    public function forStudent(User $user): array
    {
        $student = $user->student()->with(['class.homeroomTeacher'])->first();
        $today = Carbon::today();
        $dayOfWeek = $today->dayOfWeekIso;

        $stats = ['attendance_percentage' => 0];
        $todaysSchedules = [];

        if ($student) {
            $total = Attendance::where('student_id', $student->id)->count();
            $present = Attendance::where('student_id', $student->id)
                ->where('status', 'hadir')
                ->count();
            $stats['attendance_percentage'] = $total > 0
                ? (int) round(($present / $total) * 100)
                : 0;

            if ($student->class_id) {
                $todaysSchedules = Schedule::where('day_of_week', $dayOfWeek)
                    ->whereHas('teachingAssignment', fn ($q) => $q->where('class_id', $student->class_id))
                    ->with(['teachingAssignment.subject', 'teachingAssignment.teacher'])
                    ->orderBy('start_time')
                    ->get()
                    ->map(fn ($s) => [
                        'id' => $s->id,
                        'start_time' => $s->start_time,
                        'end_time' => $s->end_time,
                        'subject' => $s->teachingAssignment->subject->name ?? '-',
                        'teacher' => $s->teachingAssignment->teacher->name ?? '-',
                    ])
                    ->toArray();
            }
        }

        $recentAnnouncements = Announcement::where('is_published', true)
            ->latest()
            ->take(5)
            ->get()
            ->map(fn ($a) => [
                'id' => $a->id,
                'title' => $a->title,
                'content' => Str::limit(strip_tags($a->content), 120),
                'created_at' => $a->created_at->toIso8601String(),
            ])
            ->toArray();

        return [
            'role' => 'student',
            'student' => $student ? [
                'id' => $student->id,
                'name' => $student->name,
                'class' => $student->class?->name,
                'homeroom_teacher' => $student->class?->homeroomTeacher?->name,
            ] : null,
            'stats' => $stats,
            'todays_schedules' => $todaysSchedules,
            'recent_announcements' => $recentAnnouncements,
        ];
    }
}
