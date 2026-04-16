<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Mobile\AnnouncementService;
use Illuminate\Http\Request;

class MobileAnnouncementController extends Controller
{
    public function __construct(private readonly AnnouncementService $service) {}

    public function index(Request $request)
    {
        return response()->json([
            'data' => $this->service->listForStudent($request->user()),
        ]);
    }

    public function show(Request $request, int $id)
    {
        $data = $this->service->detailForStudent($request->user(), $id);

        if ($data === null) {
            return response()->json(['message' => 'Pengumuman tidak ditemukan.', 'code' => 'NOT_FOUND'], 404);
        }

        return response()->json(['data' => $data]);
    }
}
