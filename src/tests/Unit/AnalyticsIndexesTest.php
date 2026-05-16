<?php

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;

uses(Tests\TestCase::class, RefreshDatabase::class);

it('analytics index exists on attendance table (student_id, semester_id)', function () {
    $indexes = DB::select("
        SELECT indexname
        FROM pg_indexes
        WHERE tablename = 'attendance'
        AND indexname = 'attendance_student_semester_idx'
    ");
    expect($indexes)->not->toBeEmpty();
});

it('analytics index exists on task_scores table (student_id)', function () {
    $indexes = DB::select("
        SELECT indexname
        FROM pg_indexes
        WHERE tablename = 'task_scores'
        AND indexname = 'task_scores_student_idx'
    ");
    expect($indexes)->not->toBeEmpty();
});

it('analytics index exists on exam_scores table (student_id)', function () {
    $indexes = DB::select("
        SELECT indexname
        FROM pg_indexes
        WHERE tablename = 'exam_scores'
        AND indexname = 'exam_scores_student_idx'
    ");
    expect($indexes)->not->toBeEmpty();
});
