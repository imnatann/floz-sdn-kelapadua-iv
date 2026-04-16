<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Mobile\TeacherClassService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MobileTeacherClassController extends Controller
{
    public function __construct(private readonly TeacherClassService $service) {}

    /**
     * @OA\Get(
     *     path="/api/v1/teacher/teaching-assignments",
     *     tags={"Teacher"},
     *     summary="Daftar kelas yang diampu oleh guru",
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(response=200, description="List of teaching assignments"),
     *     @OA\Response(response=401, description="Token tidak valid"),
     *     @OA\Response(response=403, description="Bukan guru"),
     * )
     */
    public function index(Request $request): JsonResponse
    {
        $data = $this->service->listForTeacher($request->user());

        return response()->json(['data' => $data]);
    }

    /**
     * @OA\Get(
     *     path="/api/v1/teacher/teaching-assignments/{id}/meetings",
     *     tags={"Teacher"},
     *     summary="Daftar pertemuan untuk teaching assignment tertentu",
     *     security={{"bearerAuth":{}}},
     *     @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\Response(response=200, description="Meetings for the teaching assignment"),
     *     @OA\Response(response=401, description="Token tidak valid"),
     *     @OA\Response(response=403, description="Bukan guru"),
     *     @OA\Response(response=404, description="Teaching assignment tidak ditemukan atau bukan milik guru ini"),
     * )
     */
    public function meetings(Request $request, int $id): JsonResponse
    {
        $data = $this->service->meetingsForTeachingAssignment($request->user(), $id);

        if ($data === null) {
            return response()->json(['message' => 'Teaching assignment tidak ditemukan.'], 404);
        }

        return response()->json(['data' => $data]);
    }
}
