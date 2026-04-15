<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Schedule;
use App\Models\TeachingAssignment;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class MobileScheduleController extends Controller
{
    /**
     * GET /api/v1/schedules
     * Return weekly schedule for the authenticated user.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        $schedules = $this->getScheduleQuery($user)
            ->with(['teachingAssignment.subject', 'teachingAssignment.teacher', 'teachingAssignment.schoolClass'])
            ->orderBy('day_of_week')
            ->orderBy('start_time')
            ->get()
            ->groupBy('day_of_week')
            ->map(fn($daySchedules, $day) => [
                'day' => $day,
                'items' => $daySchedules->map(fn($s) => [
                    'id'         => $s->id,
                    'start_time' => $s->start_time,
                    'end_time'   => $s->end_time,
                    'subject'    => $s->teachingAssignment->subject->name ?? '-',
                    'teacher'    => $s->teachingAssignment->teacher->name ?? '-',
                    'class'      => $s->teachingAssignment->schoolClass->name ?? '-',
                ])->values(),
            ])
            ->values();

        return response()->json(['schedules' => $schedules]);
    }

    /**
     * GET /api/v1/schedules/today
     * Return today's schedule only.
     */
    public function today(Request $request)
    {
        $user = $request->user();
        $dayOfWeek = Carbon::today()->dayOfWeekIso;

        $schedules = $this->getScheduleQuery($user)
            ->where('day_of_week', $dayOfWeek)
            ->with(['teachingAssignment.subject', 'teachingAssignment.teacher', 'teachingAssignment.schoolClass'])
            ->orderBy('start_time')
            ->get()
            ->map(fn($s) => [
                'id'         => $s->id,
                'start_time' => $s->start_time,
                'end_time'   => $s->end_time,
                'subject'    => $s->teachingAssignment->subject->name ?? '-',
                'teacher'    => $s->teachingAssignment->teacher->name ?? '-',
                'class'      => $s->teachingAssignment->schoolClass->name ?? '-',
            ]);

        return response()->json(['schedules' => $schedules]);
    }

    /**
     * Build base schedule query depending on user role.
     */
    private function getScheduleQuery($user)
    {
        if ($user->isStudent()) {
            $student = $user->student;
            if (!$student || !$student->class_id) {
                return Schedule::whereRaw('1 = 0'); // empty result set
            }
            return Schedule::whereHas('teachingAssignment', fn($q) => $q->where('class_id', $student->class_id));
        }

        if ($user->isTeacher()) {
            $teacher = $user->teacher;
            if (!$teacher) {
                return Schedule::whereRaw('1 = 0');
            }
            return Schedule::whereHas('teachingAssignment', fn($q) => $q->where('teacher_id', $teacher->id));
        }

        // Parent — get child's class schedule
        return Schedule::whereRaw('1 = 0');
    }
}
