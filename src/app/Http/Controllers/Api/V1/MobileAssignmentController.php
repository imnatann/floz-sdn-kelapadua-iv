<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Mobile\AssignmentService;
use Illuminate\Http\Request;

class MobileAssignmentController extends Controller
{
    public function __construct(private readonly AssignmentService $service) {}

    public function index(Request $request)
    {
        $status = $request->query('status', 'upcoming');

        return response()->json([
            'data' => $this->service->listForStudent($request->user(), $status),
        ]);
    }

    public function show(Request $request, int $id)
    {
        $data = $this->service->detailForStudent($request->user(), $id);

        if ($data === null) {
            return response()->json(['message' => 'Tugas tidak ditemukan.', 'code' => 'NOT_FOUND'], 404);
        }

        return response()->json(['data' => $data]);
    }
}
