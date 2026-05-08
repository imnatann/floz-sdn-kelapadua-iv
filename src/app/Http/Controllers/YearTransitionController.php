<?php

namespace App\Http\Controllers;

use App\Http\Requests\YearTransition\ExecuteRequest;
use App\Http\Requests\YearTransition\PreviewRequest;
use App\Models\YearTransitionLog;
use App\Services\YearTransitionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Gate;
use Inertia\Inertia;
use Inertia\Response;

class YearTransitionController extends Controller
{
    public function __construct(private YearTransitionService $service)
    {
        //
    }

    public function index(): Response
    {
        Gate::authorize('manage_year_transition');

        return Inertia::render('YearTransition/Wizard', [
            'academicYears' => \App\Models\AcademicYear::orderByDesc('start_date')->get(),
        ]);
    }

    public function preview(PreviewRequest $request): JsonResponse
    {
        $sourceAyId = $request->integer('source_academic_year_id');
        $targetAyId = $request->integer('target_academic_year_id');

        $plan = $this->service->previewTransition(
            $sourceAyId,
            $targetAyId,
            (array) $request->input('overrides', []),
        );

        // W-04: compute server-side fingerprint and store snapshot in cache (30-min TTL)
        $planHash = $this->service->computePlanHash($plan, $sourceAyId, $targetAyId);
        $cacheKey = "year-transition:preview:{$request->user()->id}:{$sourceAyId}:{$targetAyId}";
        Cache::put($cacheKey, $planHash, now()->addMinutes(30));

        return response()->json(array_merge($plan, ['plan_hash' => $planHash]));
    }

    public function execute(ExecuteRequest $request): JsonResponse
    {
        // W-04: Verify plan_hash against cached snapshot before executing
        $sourceAyId = $request->integer('source_academic_year_id');
        $targetAyId = $request->integer('target_academic_year_id');
        $submittedHash = $request->string('plan_hash')->toString();
        $cacheKey = "year-transition:preview:{$request->user()->id}:{$sourceAyId}:{$targetAyId}";

        $cachedHash = Cache::get($cacheKey);

        if ($cachedHash === null) {
            return response()->json([
                'message' => 'Pratinjau telah kedaluwarsa. Silakan muat ulang dan tinjau kembali.',
            ], 409);
        }

        if (!hash_equals($cachedHash, $submittedHash)) {
            return response()->json([
                'message' => 'Data telah berubah sejak Anda meninjau pratinjau. Silakan muat ulang dan tinjau kembali.',
            ], 409);
        }

        try {
            $log = $this->service->executeTransition(
                $request->integer('source_academic_year_id'),
                $request->integer('target_academic_year_id'),
                (array) $request->input('overrides', []),
                $request->user(),
            );

            return response()->json([
                'log_id'  => $log->id,
                'summary' => [
                    'promoted'  => $log->promoted_count,
                    'graduated' => $log->graduated_count,
                    'retained'  => $log->retained_count,
                    'excluded'  => $log->excluded_count,
                ],
            ]);
        } catch (\RuntimeException $e) {
            // BLOCK-1/BLOCK-5: Double-execute or lock conflict returns 409
            $isIdempotencyConflict = str_contains($e->getMessage(), 'sudah memiliki kelas')
                || str_contains($e->getMessage(), 'sedang berjalan');

            if ($isIdempotencyConflict) {
                return response()->json(['message' => $e->getMessage()], 409);
            }

            return response()->json(['message' => $e->getMessage()], 500);
        }
    }

    public function logs(): Response
    {
        Gate::authorize('manage_year_transition');

        return Inertia::render('YearTransition/Logs', [
            'logs' => YearTransitionLog::with(['executor', 'sourceAcademicYear', 'targetAcademicYear'])
                ->orderByDesc('executed_at')
                ->paginate(20),
        ]);
    }

    public function showLog(YearTransitionLog $log): Response
    {
        Gate::authorize('manage_year_transition');

        return Inertia::render('YearTransition/LogDetail', [
            'log' => $log->load(['executor', 'sourceAcademicYear', 'targetAcademicYear']),
        ]);
    }
}
