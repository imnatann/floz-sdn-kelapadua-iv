<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Attendance\StoreAttendanceRequest;
use App\Models\Meeting;
use App\Services\Mobile\AttendanceService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\Request;

class MobileTeacherAttendanceController extends Controller
{
    public function __construct(private readonly AttendanceService $service) {}

    public function show(Request $request, int $meetingId)
    {
        $meeting = Meeting::findOrFail($meetingId);
        $this->authorizeTeacher($request->user(), $meeting);

        return response()->json([
            'data' => $this->service->getRoster($meeting, $request->user()),
        ]);
    }

    public function store(StoreAttendanceRequest $request, int $meetingId)
    {
        $meeting = Meeting::findOrFail($meetingId);
        $this->authorizeTeacher($request->user(), $meeting);

        $roster = $this->service->store(
            $meeting,
            $request->validated('entries'),
            $request->user()
        );

        return response()->json(['data' => $roster]);
    }

    private function authorizeTeacher(mixed $user, Meeting $meeting): void
    {
        if (! $user->teacher ||
            $meeting->teachingAssignment->teacher_id !== $user->teacher->id) {
            throw new AuthorizationException('Anda tidak memiliki akses ke pertemuan ini.');
        }
    }
}
