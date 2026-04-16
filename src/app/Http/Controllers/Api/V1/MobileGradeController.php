<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Mobile\GradeService;
use Illuminate\Http\Request;

class MobileGradeController extends Controller
{
    public function __construct(private readonly GradeService $service) {}

    public function index(Request $request)
    {
        return response()->json([
            'data' => $this->service->listForStudent($request->user()),
        ]);
    }

    public function show(Request $request, int $subjectId)
    {
        return response()->json([
            'data' => $this->service->detailForStudent($request->user(), $subjectId),
        ]);
    }
}
