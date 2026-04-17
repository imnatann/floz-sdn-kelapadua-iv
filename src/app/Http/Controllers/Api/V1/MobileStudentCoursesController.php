<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Mobile\CoursesService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MobileStudentCoursesController extends Controller
{
    public function __construct(private readonly CoursesService $service) {}

    public function index(Request $request): JsonResponse
    {
        return response()->json(['data' => $this->service->listForStudent($request->user())]);
    }

    public function meetings(Request $request, int $taId): JsonResponse
    {
        return response()->json(['data' => $this->service->meetingsFor($request->user(), $taId)]);
    }

    public function meeting(Request $request, int $meetingId): JsonResponse
    {
        return response()->json(['data' => $this->service->meetingDetail($request->user(), $meetingId)]);
    }
}
