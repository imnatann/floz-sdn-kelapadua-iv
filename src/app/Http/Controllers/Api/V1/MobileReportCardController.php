<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Mobile\ReportCardService;
use Illuminate\Http\Request;

class MobileReportCardController extends Controller
{
    public function __construct(private readonly ReportCardService $service) {}

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
            return response()->json(['message' => 'Rapor tidak ditemukan.', 'code' => 'NOT_FOUND'], 404);
        }
        return response()->json(['data' => $data]);
    }

    public function pdf(Request $request, int $id)
    {
        $url = $this->service->pdfUrlForStudent($request->user(), $id);
        if ($url === null) {
            return response()->json(['message' => 'PDF tidak tersedia.', 'code' => 'NOT_FOUND'], 404);
        }
        return response()->json(['data' => ['url' => $url]]);
    }
}
