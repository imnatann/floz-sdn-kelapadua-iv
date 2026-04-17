<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Mobile\NotificationsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MobileNotificationsController extends Controller
{
    public function __construct(private readonly NotificationsService $service) {}

    public function index(Request $request): JsonResponse
    {
        return response()->json($this->service->listForUser($request->user()));
    }

    public function read(Request $request, string $id): JsonResponse
    {
        $this->service->markAsRead($request->user(), $id);
        return response()->json(null, 204);
    }

    public function readAll(Request $request): JsonResponse
    {
        $count = $this->service->markAllAsRead($request->user());
        return response()->json(['data' => ['marked' => $count]]);
    }
}
