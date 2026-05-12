<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Attendance\StoreAttendanceRequest;
use App\Models\SchoolClass;
use App\Services\Mobile\AttendanceService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\Request;

/**
 * Daily class attendance for wali kelas (homeroom teachers) on mobile.
 *
 * Endpoints:
 *   GET  /api/v1/teacher/classes/{classId}/attendance/today
 *   POST /api/v1/teacher/classes/{classId}/attendance/today
 *
 * Authorization: only the homeroom teacher of the class may access.
 */
class MobileTeacherDailyAttendanceController extends Controller
{
    public function __construct(private readonly AttendanceService $service) {}

    public function show(Request $request, int $classId)
    {
        $class = SchoolClass::findOrFail($classId);
        $this->authorizeHomeroomTeacher($request->user(), $class);

        return response()->json([
            'data' => $this->service->getDailyRosterForClass($class),
        ]);
    }

    public function store(StoreAttendanceRequest $request, int $classId)
    {
        $class = SchoolClass::findOrFail($classId);
        $this->authorizeHomeroomTeacher($request->user(), $class);

        $roster = $this->service->storeDailyForClass(
            $class,
            $request->validated('entries'),
            $request->user()
        );

        return response()->json(['data' => $roster]);
    }

    private function authorizeHomeroomTeacher(mixed $user, SchoolClass $class): void
    {
        if (! $user->teacher ||
            (int) $class->homeroom_teacher_id !== (int) $user->teacher->id) {
            throw new AuthorizationException('Hanya wali kelas yang dapat mengelola absensi harian kelas ini.');
        }
    }
}
