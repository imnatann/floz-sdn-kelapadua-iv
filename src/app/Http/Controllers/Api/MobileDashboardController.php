<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Student;
use App\Models\SchoolClass;
use App\Models\Teacher;
use App\Models\Announcement;
use App\Models\Attendance;
use App\Models\TeachingAssignment;
use App\Models\Schedule;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class MobileDashboardController extends Controller
{
    /**
     * GET /api/v1/dashboard
     * Return role-based dashboard data.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $today = Carbon::today();
        $dayOfWeek = $today->dayOfWeekIso;

        $recentAnnouncements = Announcement::where('is_published', true)
            ->latest()
            ->take(5)
            ->get()
            ->map(fn($a) => [
                'id'         => $a->id,
                'title'      => $a->title,
                'content'    => \Illuminate\Support\Str::limit(strip_tags($a->content), 120),
                'created_at' => $a->created_at->toISOString(),
            ]);

        if ($user->isStudent()) {
            return $this->studentDashboard($user, $today, $dayOfWeek, $recentAnnouncements);
        }

        if ($user->isTeacher()) {
            return $this->teacherDashboard($user, $today, $dayOfWeek, $recentAnnouncements);
        }

        // Parent role
        if ($user->isParent()) {
            return $this->parentDashboard($user, $today, $dayOfWeek, $recentAnnouncements);
        }

        return response()->json(['message' => 'Role not supported for mobile dashboard.'], 403);
    }

    private function studentDashboard($user, $today, $dayOfWeek, $announcements)
    {
        $student = $user->student()->with(['class.homeroomTeacher'])->first();

        $stats = ['attendance_percentage' => 0];
        $todaysSchedules = [];

        if ($student) {
            $totalAttendance = Attendance::where('student_id', $student->id)->count();
            $presentAttendance = Attendance::where('student_id', $student->id)->where('status', 'present')->count();
            $stats['attendance_percentage'] = $totalAttendance > 0
                ? round(($presentAttendance / $totalAttendance) * 100)
                : 0;

            if ($student->class_id) {
                $todaysSchedules = Schedule::where('day_of_week', $dayOfWeek)
                    ->whereHas('teachingAssignment', fn($q) => $q->where('class_id', $student->class_id))
                    ->with(['teachingAssignment.subject', 'teachingAssignment.teacher'])
                    ->orderBy('start_time')
                    ->get()
                    ->map(fn($s) => [
                        'id'         => $s->id,
                        'start_time' => $s->start_time,
                        'end_time'   => $s->end_time,
                        'subject'    => $s->teachingAssignment->subject->name ?? '-',
                        'teacher'    => $s->teachingAssignment->teacher->name ?? '-',
                    ]);
            }
        }

        return response()->json([
            'role'    => 'student',
            'student' => $student ? [
                'id'    => $student->id,
                'name'  => $student->name,
                'class' => $student->class?->name,
                'homeroom_teacher' => $student->class?->homeroomTeacher?->name,
            ] : null,
            'stats'               => $stats,
            'todays_schedules'    => $todaysSchedules,
            'recent_announcements' => $announcements,
        ]);
    }

    private function teacherDashboard($user, $today, $dayOfWeek, $announcements)
    {
        $teacher = $user->teacher;

        $stats = [
            'my_classes_count'  => 0,
            'my_students_count' => 0,
        ];
        $todaysSchedules = [];

        if ($teacher) {
            $classIds = TeachingAssignment::where('teacher_id', $teacher->id)->pluck('class_id')
                ->merge(SchoolClass::where('homeroom_teacher_id', $teacher->id)->pluck('id'))
                ->unique();

            $stats['my_classes_count'] = $classIds->count();
            $stats['my_students_count'] = Student::whereIn('class_id', $classIds)->active()->count();

            $todaysSchedules = Schedule::where('day_of_week', $dayOfWeek)
                ->whereHas('teachingAssignment', fn($q) => $q->where('teacher_id', $teacher->id))
                ->with(['teachingAssignment.subject', 'teachingAssignment.schoolClass'])
                ->orderBy('start_time')
                ->get()
                ->map(fn($s) => [
                    'id'         => $s->id,
                    'start_time' => $s->start_time,
                    'end_time'   => $s->end_time,
                    'subject'    => $s->teachingAssignment->subject->name ?? '-',
                    'class'      => $s->teachingAssignment->schoolClass->name ?? '-',
                ]);
        }

        return response()->json([
            'role'    => 'teacher',
            'teacher' => $teacher ? [
                'id'   => $teacher->id,
                'name' => $teacher->name,
            ] : null,
            'stats'               => $stats,
            'todays_schedules'    => $todaysSchedules,
            'recent_announcements' => $announcements,
        ]);
    }

    private function parentDashboard($user, $today, $dayOfWeek, $announcements)
    {
        // Parent: find child (student) linked by parent_phone or parent_email
        // For now, return a placeholder — parent linking logic depends on DB schema
        return response()->json([
            'role'                 => 'parent',
            'stats'                => [],
            'todays_schedules'     => [],
            'recent_announcements' => $announcements,
        ]);
    }
}
