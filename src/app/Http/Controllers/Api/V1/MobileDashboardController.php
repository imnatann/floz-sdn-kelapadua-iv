<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\DashboardResource;
use App\Services\Mobile\DashboardService;
use Illuminate\Http\Request;

class MobileDashboardController extends Controller
{
    public function __construct(private readonly DashboardService $service) {}

    /**
     * @OA\Get(
     *     path="/api/v1/student/dashboard",
     *     tags={"Student"},
     *     summary="Dashboard siswa",
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(response=200, description="Dashboard data"),
     *     @OA\Response(response=401, description="Token tidak valid"),
     *     @OA\Response(response=403, description="Bukan siswa"),
     * )
     */
    public function index(Request $request)
    {
        $data = $this->service->forStudent($request->user());

        return response()->json([
            'data' => (new DashboardResource($data))->resolve(),
        ]);
    }
}
