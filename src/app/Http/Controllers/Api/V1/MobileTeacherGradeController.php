<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Grade\StoreGradeRequest;
use App\Models\TeachingAssignment;
use App\Services\Mobile\GradingService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\Request;

class MobileTeacherGradeController extends Controller
{
    public function __construct(private readonly GradingService $service) {}

    public function roster(Request $request, int $taId)
    {
        $ta = TeachingAssignment::findOrFail($taId);
        $this->authorizeTeacher($request->user(), $ta);

        return response()->json([
            'data' => $this->service->getRoster($ta, $request->user()),
        ]);
    }

    public function store(StoreGradeRequest $request, int $taId)
    {
        $ta = TeachingAssignment::findOrFail($taId);
        $this->authorizeTeacher($request->user(), $ta);

        $result = $this->service->storeGrades(
            $ta,
            $request->validated('entries'),
            $request->user()
        );

        return response()->json(['data' => $result]);
    }

    private function authorizeTeacher(mixed $user, TeachingAssignment $ta): void
    {
        if (! $user->teacher || $ta->teacher_id !== $user->teacher->id) {
            throw new AuthorizationException('Anda tidak memiliki akses ke penugasan ini.');
        }
    }
}
