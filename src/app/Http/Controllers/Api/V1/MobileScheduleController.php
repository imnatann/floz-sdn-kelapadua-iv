<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ScheduleResource;
use App\Services\Mobile\ScheduleService;
use Illuminate\Http\Request;

class MobileScheduleController extends Controller
{
    public function __construct(private readonly ScheduleService $service) {}

    /**
     * @OA\Get(
     *     path="/api/v1/student/schedules",
     *     tags={"Student"},
     *     summary="Jadwal mingguan siswa",
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(response=200, description="Schedule grouped by day"),
     *     @OA\Response(response=401, description="Token tidak valid"),
     *     @OA\Response(response=403, description="Bukan siswa"),
     * )
     */
    public function index(Request $request)
    {
        $data = $this->service->forStudent($request->user());

        return response()->json([
            'data' => $data,
        ]);
    }
}
