<?php

use App\Http\Controllers\Api\V1\MobileAuthController;
use App\Http\Controllers\Api\V1\MobileDashboardController;
use App\Http\Controllers\Api\V1\MobileScheduleController;
use App\Http\Controllers\Api\V1\MobileGradeController;
use App\Http\Controllers\Api\V1\MobileNotificationsController;
use App\Http\Controllers\Api\V1\MobileAnnouncementController;
use App\Http\Controllers\Api\V1\MobileAssignmentController;
use App\Http\Controllers\Api\V1\MobileReportCardController;
use App\Http\Controllers\Api\V1\MobileStudentCoursesController;
use App\Http\Controllers\Api\V1\MobileTeacherClassController;
use App\Http\Controllers\Api\V1\MobileTeacherAttendanceController;
use App\Http\Controllers\Api\V1\MobileTeacherGradeController;
use App\Http\Controllers\Api\V1\MobileTeacherRecapController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Mobile API Routes — Floz SDN Kelapadua IV (Single-School)
|--------------------------------------------------------------------------
|
| JSON API endpoints for the FLOZ Mobile App (Flutter).
| All routes prefixed with /api/v1
| No tenant identification needed — single school system.
|
*/

Route::prefix('v1')->group(function () {

    // ─── Auth (no token yet) ───────────────────────────────────────
    Route::middleware('throttle:login')->group(function () {
        Route::post('/auth/login', [MobileAuthController::class, 'login']);
    });

    // ─── Protected (auth required) ─────────────────────────────────
    Route::middleware(['auth:sanctum', 'throttle:mobile-api'])->group(function () {

        // Auth
        Route::post('/auth/logout', [MobileAuthController::class, 'logout']);
        Route::get('/auth/me', [MobileAuthController::class, 'me']);

        // Teacher routes
        Route::middleware('role:teacher')->group(function () {
            Route::get('/teacher/teaching-assignments', [MobileTeacherClassController::class, 'index']);
            Route::get('/teacher/teaching-assignments/{id}/meetings', [MobileTeacherClassController::class, 'meetings']);
            Route::get('/teacher/meetings/{meeting}/attendance', [MobileTeacherAttendanceController::class, 'show']);
            Route::post('/teacher/meetings/{meeting}/attendance', [MobileTeacherAttendanceController::class, 'store']);
            Route::get('/teacher/teaching-assignments/{ta}/grade-roster', [MobileTeacherGradeController::class, 'roster']);
            Route::post('/teacher/teaching-assignments/{ta}/grades', [MobileTeacherGradeController::class, 'store']);
            Route::get('/teacher/teaching-assignments/{ta}/attendance-recap', [MobileTeacherRecapController::class, 'attendanceRecap']);
            Route::get('/teacher/teaching-assignments/{ta}/grade-recap', [MobileTeacherRecapController::class, 'gradeRecap']);
        });

        // Dashboard + Student routes
        Route::middleware('role:student')->group(function () {
            Route::get('/student/dashboard', [MobileDashboardController::class, 'index']);
            Route::get('/student/schedules', [MobileScheduleController::class, 'index']);
            Route::get('/student/grades', [MobileGradeController::class, 'index']);
            Route::get('/student/grades/{subjectId}', [MobileGradeController::class, 'show']);
            Route::get('/student/report-cards', [MobileReportCardController::class, 'index']);
            Route::get('/student/report-cards/{id}', [MobileReportCardController::class, 'show']);
            Route::get('/student/report-cards/{id}/pdf', [MobileReportCardController::class, 'pdf']);
            Route::get('/student/announcements', [MobileAnnouncementController::class, 'index']);
            Route::get('/student/announcements/{id}', [MobileAnnouncementController::class, 'show']);
            Route::get('/student/assignments', [MobileAssignmentController::class, 'index']);
            Route::get('/student/assignments/{id}', [MobileAssignmentController::class, 'show']);
            Route::get('/student/courses', [MobileStudentCoursesController::class, 'index']);
            Route::get('/student/courses/{ta}/meetings', [MobileStudentCoursesController::class, 'meetings']);
            Route::get('/student/meetings/{meeting}', [MobileStudentCoursesController::class, 'meeting']);
        });

        // Notifications (shared by student + teacher)
        Route::middleware('role:student,teacher')->group(function () {
            Route::get('/notifications', [MobileNotificationsController::class, 'index']);
            Route::post('/notifications/{id}/read', [MobileNotificationsController::class, 'read']);
            Route::post('/notifications/read-all', [MobileNotificationsController::class, 'readAll']);
        });
    });
});
