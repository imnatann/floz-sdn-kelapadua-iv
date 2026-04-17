<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\TeachingAssignment;
use App\Services\Mobile\RecapService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MobileTeacherRecapController extends Controller
{
    public function __construct(private readonly RecapService $service) {}

    public function attendanceRecap(Request $request, int $taId): JsonResponse
    {
        $ta = TeachingAssignment::findOrFail($taId);
        $this->authorizeTeacher($request->user(), $ta);

        return response()->json([
            'data' => $this->service->attendanceRecap($ta),
        ]);
    }

    public function gradeRecap(Request $request, int $taId): JsonResponse
    {
        $ta = TeachingAssignment::findOrFail($taId);
        $this->authorizeTeacher($request->user(), $ta);

        return response()->json([
            'data' => $this->service->gradeRecap($ta),
        ]);
    }

    private function authorizeTeacher(mixed $user, TeachingAssignment $ta): void
    {
        if (! $user->teacher || $ta->teacher_id !== $user->teacher->id) {
            throw new AuthorizationException('Anda tidak memiliki akses ke penugasan ini.');
        }
    }
}
