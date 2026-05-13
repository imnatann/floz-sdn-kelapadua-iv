<?php

use App\Models\YearTransitionLog;
use App\Models\AcademicYear;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

it('creates a log with correct relationships', function () {
    $log = YearTransitionLog::factory()->create([
        'promoted_count'  => 20,
        'graduated_count' => 5,
        'retained_count'  => 2,
    ]);

    expect($log->executor)->toBeInstanceOf(User::class);
    expect($log->sourceAcademicYear)->toBeInstanceOf(AcademicYear::class);
    expect($log->targetAcademicYear)->toBeInstanceOf(AcademicYear::class);
});

it('totalMutations sums promoted + graduated + retained', function () {
    $log = new YearTransitionLog([
        'promoted_count'  => 20,
        'graduated_count' => 5,
        'retained_count'  => 2,
        'excluded_count'  => 1,
    ]);

    expect($log->totalMutations())->toBe(27);
});

it('casts plan_snapshot as array', function () {
    $log = YearTransitionLog::factory()->create([
        'plan_snapshot' => ['mutations' => [['student_id' => 1, 'action' => 'promote']]],
    ]);

    expect($log->fresh()->plan_snapshot)->toBeArray();
    expect($log->fresh()->plan_snapshot['mutations'][0]['action'])->toBe('promote');
});
