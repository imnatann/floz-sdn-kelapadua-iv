<?php

use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\StudentController;
use App\Http\Controllers\GradeController;
use App\Http\Controllers\ReportCardController;
use App\Http\Controllers\TeacherController;
use App\Http\Controllers\AnnouncementController;
use App\Http\Controllers\AttendanceController;
use App\Http\Controllers\SchoolClassController;
use App\Http\Controllers\SubjectController;
use App\Http\Controllers\TeachingAssignmentController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\ScheduleController;
use App\Http\Controllers\AuditLogController;
use App\Http\Controllers\MeetingController;
use App\Http\Controllers\OfflineAssignmentController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes — Floz SDN Kelapadua IV (Single-School System)
|--------------------------------------------------------------------------
*/

// ─── Public / Auth ───────────────────────────────────────────────────
Route::get('/', [\App\Http\Controllers\WelcomeController::class, 'index'])->name('home');
Route::get('/docs', function () {
    return inertia('Docs');
})->name('docs');

Route::controller(LoginController::class)->group(function () {
    Route::get('/login', 'showLoginForm')->name('login');
    Route::post('/login', 'login');
    Route::post('/logout', 'logout')->name('logout');
});

// ─── School Routes (auth required) ──────────────────────────────────
Route::middleware(['auth'])->group(function () {

    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

    // Notifications
    Route::get('/notifications/data', [NotificationController::class, 'data'])->name('notifications.data');
    Route::get('/notifications', [NotificationController::class, 'index'])->name('notifications.index');
    Route::post('/notifications/mark-all-read', [NotificationController::class, 'markAllRead'])->name('notifications.mark-all-read');
    Route::post('/notifications/{id}/mark-read', [NotificationController::class, 'markAsRead'])->name('notifications.mark-read');

    // Students
    Route::post('students/import', [StudentController::class, 'import'])->name('students.import');
    Route::get('students/template', [StudentController::class, 'downloadTemplate'])->name('students.template');
    Route::get('students/{student}/id-card', [StudentController::class, 'downloadIdCard'])->name('students.id-card');
    Route::resource('students', StudentController::class);

    // Staff (Teachers)
    Route::resource('staff', TeacherController::class)->parameters(['staff' => 'staff']);

    // Classes (Kelas)
    Route::resource('classes', SchoolClassController::class)->parameters(['classes' => 'class']);

    // Subjects (Mata Pelajaran)
    Route::resource('subjects', SubjectController::class);

    // Teaching Assignments (Penugasan Guru — data only, no CRUD pages)
    Route::resource('teaching-assignments', TeachingAssignmentController::class)->except(['show']);

    // Schedules (Jadwal Pelajaran)
    Route::resource('schedules', ScheduleController::class)->only(['index', 'store', 'destroy']);

    // ─── AKADEMIK ────────────────────────────────────────────────────

    // Attendance (Absensi per Pertemuan)
    Route::get('/attendance', [AttendanceController::class, 'index'])->name('attendance.index');
    Route::get('/attendance/{class}', [AttendanceController::class, 'show'])->name('attendance.show');
    Route::get('/attendance/{class}/create', [AttendanceController::class, 'create'])->name('attendance.create');
    Route::post('/attendance/{class}', [AttendanceController::class, 'store'])->name('attendance.store');
    Route::get('/attendance/{class}/meeting/{meeting}', [AttendanceController::class, 'edit'])->name('attendance.edit');
    Route::put('/attendance/{class}/meeting/{meeting}', [AttendanceController::class, 'update'])->name('attendance.update');

    // Tasks & Grades (Tugas & Nilai)
    Route::get('/tasks', [\App\Http\Controllers\TaskController::class, 'index'])->name('tasks.index');
    Route::get('/tasks/class/{class}', [\App\Http\Controllers\TaskController::class, 'classIndex'])->name('tasks.class');
    Route::get('/tasks/create/{class}', [\App\Http\Controllers\TaskController::class, 'create'])->name('tasks.create');
    Route::post('/tasks', [\App\Http\Controllers\TaskController::class, 'store'])->name('tasks.store');
    Route::get('/tasks/{task}', [\App\Http\Controllers\TaskController::class, 'show'])->name('tasks.show');
    Route::post('/tasks/{task}/scores', [\App\Http\Controllers\TaskController::class, 'storeScores'])->name('tasks.scores.store');
    Route::delete('/tasks/{task}', [\App\Http\Controllers\TaskController::class, 'destroy'])->name('tasks.destroy');

    // Exams (Ujian: Ulangan Harian, UTS, UAS)
    Route::get('/exams', [\App\Http\Controllers\ExamController::class, 'index'])->name('exams.index');
    Route::get('/exams/class/{class}', [\App\Http\Controllers\ExamController::class, 'classIndex'])->name('exams.class');
    Route::get('/exams/create/{class}', [\App\Http\Controllers\ExamController::class, 'create'])->name('exams.create');
    Route::post('/exams', [\App\Http\Controllers\ExamController::class, 'store'])->name('exams.store');
    Route::get('/exams/{exam}', [\App\Http\Controllers\ExamController::class, 'show'])->name('exams.show');
    Route::post('/exams/{exam}/scores', [\App\Http\Controllers\ExamController::class, 'storeScores'])->name('exams.scores.store');
    Route::delete('/exams/{exam}', [\App\Http\Controllers\ExamController::class, 'destroy'])->name('exams.destroy');

    // Grades (Legacy — kept for backward compatibility)
    Route::get('/grades', [GradeController::class, 'index'])->name('grades.index');
    Route::get('/grades/batch', [GradeController::class, 'batchInput'])->name('grades.batch');
    Route::post('/grades/batch', [GradeController::class, 'storeBatch'])->name('grades.storeBatch');

    // Report Cards (Rapor)
    Route::get('/report-cards', [ReportCardController::class, 'index'])->name('report-cards.index');
    Route::post('/report-cards/generate', [ReportCardController::class, 'generate'])->name('report-cards.generate');
    Route::get('/report-cards/{reportCard}', [ReportCardController::class, 'show'])->name('report-cards.show');
    Route::post('/report-cards/{reportCard}/publish', [ReportCardController::class, 'publish'])->name('report-cards.publish');
    Route::get('/report-cards/{reportCard}/pdf', [ReportCardController::class, 'downloadPdf'])->name('report-cards.pdf');

    // Audit Logs
    Route::get('/audit-logs', [AuditLogController::class, 'index'])->name('audit-logs.index');

    // Announcements (Pengumuman)
    Route::resource('announcements', AnnouncementController::class);
});
