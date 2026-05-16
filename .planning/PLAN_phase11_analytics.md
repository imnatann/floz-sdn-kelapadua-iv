# Plan: Phase 11 — Reporting & Analytics Dashboard

## Goal

Deliver a two-page analytics system (`/analytics` and `/analytics/reports`) for SDN Kelapadua IV's school admin
and principal. The dashboard aggregates attendance and grade data already in the DB into 7 widgets, backed by
`AnalyticsService` (orchestrating `ReportCardService` + `GradeCalculationService`), and generates a
Dinas-ready Excel attendance recap via `maatwebsite/excel`. All queries stay in `AnalyticsService` using
`DB::table()` for GROUP BY work and Eloquent for pre-aggregated reads from `report_cards` and `grades`.

---

## Locked Decisions (condensed)

| # | Decision |
|---|----------|
| D-1 | ApexCharts v5.11 + vue3-apexcharts v1.11; SSR-safe via `defineAsyncComponent({ ssr: false })` |
| D-2 | `/analytics` = Principal Dashboard (W1 W2 W3 W8); `/analytics/reports` = Admin Reports (W4 W5 W6 W7 + export) |
| D-3 | 7 widgets as specified; W8 = top + at-risk class card pair |
| D-4 | Excel export: attendance recap per semester per class, H/S/I/A columns, one sheet per kelas, % column. **Format must match Dinas template — request real sample from school in Phase 11.5 if unavailable.** |
| D-5 | Wave 0: 5 missing indexes added before any service code |
| D-6 | `App\Services\AnalyticsService` orchestrates; one method per widget; each returns `{ data, meta }` |
| D-7 | `App\Http\Controllers\AnalyticsController` with `index()`, `reports()`, `data()`, `exportAttendance()` |
| D-8 | Routes under `auth` + `role:school_admin` middleware |
| D-9 | `AnalyticsPolicy::view` → `$user->isSchoolAdmin()`; registered in AppServiceProvider |
| D-10 | `App\Exports\AttendanceRecapExport` implements `FromCollection, WithHeadings, WithMultipleSheets, WithStyles`; `App\Exports\Sheets\ClassAttendanceSheet` per kelas |
| D-11 | KKTP default 70; config-driven via `KKTP_DEFAULT=70` in `.env.example` + `config/floz.php` |
| D-12 | No raw SQL in models; aggregations in `AnalyticsService` via `DB::table()`; Eloquent for pre-aggregated reads |

---

## Wave 0: Index Migration

**File:** `src/database/migrations/YYYY_MM_DD_000000_add_analytics_indexes.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('attendance', function (Blueprint $table) {
            $table->index(['student_id', 'semester_id'], 'attendance_student_semester_idx');
        });
        Schema::table('task_scores', function (Blueprint $table) {
            $table->index('student_id', 'task_scores_student_idx');
        });
        Schema::table('exam_scores', function (Blueprint $table) {
            $table->index('student_id', 'exam_scores_student_idx');
        });
        Schema::table('exams', function (Blueprint $table) {
            $table->index(['class_id', 'semester_id', 'exam_type'], 'exams_class_semester_type_idx');
        });
        Schema::table('tasks', function (Blueprint $table) {
            $table->index(['class_id', 'semester_id'], 'tasks_class_semester_idx');
        });
    }

    public function down(): void
    {
        Schema::table('attendance',   fn ($t) => $t->dropIndex('attendance_student_semester_idx'));
        Schema::table('task_scores',  fn ($t) => $t->dropIndex('task_scores_student_idx'));
        Schema::table('exam_scores',  fn ($t) => $t->dropIndex('exam_scores_student_idx'));
        Schema::table('exams',        fn ($t) => $t->dropIndex('exams_class_semester_type_idx'));
        Schema::table('tasks',        fn ($t) => $t->dropIndex('tasks_class_semester_idx'));
    }
};
```

**Run before all other tasks:**
```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan migrate
```

Also add to `config/floz.php`:
```php
'kktp_default' => (int) env('KKTP_DEFAULT', 70),
```

And to `.env.example`:
```
KKTP_DEFAULT=70
```

---

## Wave 1: AnalyticsService (TDD per method)

**Files created:**
- `src/app/Services/AnalyticsService.php`
- `src/tests/Unit/AnalyticsServiceTest.php`

**Dependencies injected:** `ReportCardService` (for pattern reference; not called directly — read `report_cards` table instead), `GradeCalculationService` (call `::determinePredicate()` and `::meetsKkm()` statically).

**Constructor:**
```php
public function __construct(
    private readonly GradeCalculationService $gradeCalc,
) {}
```

---

### Task 1: `todaysAttendance()` — TDD

**Test (write first, run → RED):**

```php
it('todaysAttendance returns school-wide H/S/I/A counts for today', function () {
    $class    = SchoolClass::factory()->create();
    $sem      = Semester::factory()->create(['is_active' => true]);
    $students = Student::factory()->count(3)->create(['class_id' => $class->id, 'status' => 'active']);

    $statuses = ['present', 'sick', 'absent'];
    foreach ($students as $i => $s) {
        Attendance::factory()->create([
            'student_id'  => $s->id,
            'class_id'    => $class->id,
            'semester_id' => $sem->id,
            'date'        => today(),
            'status'      => $statuses[$i],
        ]);
    }

    $result = app(AnalyticsService::class)->todaysAttendance();

    expect($result['data']['present'])->toBe(1)
        ->and($result['data']['sick'])->toBe(1)
        ->and($result['data']['absent'])->toBe(1)
        ->and($result['data']['permit'])->toBe(0)
        ->and($result['data']['percentage'])->toBe(33.0) // 1/3 present
        ->and($result['meta'])->toHaveKey('generated_at');
});
```

**Implementation hint:**
```php
public function todaysAttendance(): array
{
    $rows = DB::table('attendance')
        ->whereDate('date', today())
        ->selectRaw('status, COUNT(*) as total')
        ->groupBy('status')
        ->pluck('total', 'status');

    $present = (int) ($rows['present'] ?? 0);
    $sick    = (int) ($rows['sick']    ?? 0);
    $permit  = (int) ($rows['permit']  ?? 0);
    $absent  = (int) ($rows['absent']  ?? 0);
    $grand   = $present + $sick + $permit + $absent;

    return [
        'data' => [
            'present'    => $present,
            'sick'       => $sick,
            'permit'     => $permit,
            'absent'     => $absent,
            'percentage' => $grand > 0 ? round($present / $grand * 100, 1) : 0.0,
        ],
        'meta' => ['generated_at' => now()->toIso8601String()],
    ];
}
```

**Acceptance:** Single GROUP BY replaces 2 Eloquent queries in DashboardController. Test GREEN.

---

### Task 2: `classesMissingAttendance()` — TDD

**Test:**
```php
it('classesMissingAttendance returns classes with no attendance record today', function () {
    $ay       = AcademicYear::factory()->create(['is_active' => true]);
    $teacher  = Teacher::factory()->create();
    $classA   = SchoolClass::factory()->create(['academic_year_id' => $ay->id, 'homeroom_teacher_id' => $teacher->id]);
    $classB   = SchoolClass::factory()->create(['academic_year_id' => $ay->id, 'homeroom_teacher_id' => $teacher->id]);
    $student  = Student::factory()->create(['class_id' => $classA->id, 'status' => 'active']);

    // classA has attendance today; classB does not
    Attendance::factory()->create(['class_id' => $classA->id, 'date' => today()]);

    $result = app(AnalyticsService::class)->classesMissingAttendance();

    $missingIds = collect($result['data'])->pluck('class_id');
    expect($missingIds)->toContain($classB->id)
        ->and($missingIds)->not->toContain($classA->id);
});
```

**Implementation hint:**
```php
public function classesMissingAttendance(): array
{
    $activeAyId = AcademicYear::where('is_active', true)->value('id');

    $classesWithAttendance = DB::table('attendance')
        ->whereDate('date', today())
        ->distinct()
        ->pluck('class_id');

    $missing = SchoolClass::with('homeroomTeacher:id,name')
        ->where('academic_year_id', $activeAyId)
        ->whereNotIn('id', $classesWithAttendance)
        ->get(['id', 'name', 'homeroom_teacher_id']);

    return [
        'data' => $missing->map(fn ($c) => [
            'class_id'       => $c->id,
            'class_name'     => $c->name,
            'homeroom_teacher' => $c->homeroomTeacher?->name ?? '–',
        ])->all(),
        'meta' => ['generated_at' => now()->toIso8601String(), 'date' => today()->toDateString()],
    ];
}
```

---

### Task 3: `classAvgComparison(int $semesterId)` — TDD

**Test:**
```php
it('classAvgComparison returns average_score per class for the semester', function () {
    $sem   = Semester::factory()->create();
    $classA = SchoolClass::factory()->create();
    $classB = SchoolClass::factory()->create();
    $sA = Student::factory()->create(['class_id' => $classA->id]);
    $sB = Student::factory()->create(['class_id' => $classB->id]);

    ReportCard::factory()->create([
        'student_id'   => $sA->id,
        'class_id'     => $classA->id,
        'semester_id'  => $sem->id,
        'report_type'  => 'final',
        'average_score' => 85.0,
    ]);
    ReportCard::factory()->create([
        'student_id'   => $sB->id,
        'class_id'     => $classB->id,
        'semester_id'  => $sem->id,
        'report_type'  => 'final',
        'average_score' => 72.0,
    ]);

    $result = app(AnalyticsService::class)->classAvgComparison($sem->id);

    $byClass = collect($result['data'])->keyBy('class_id');
    expect($byClass[$classA->id]['avg'])->toBe(85.0)
        ->and($byClass[$classB->id]['avg'])->toBe(72.0);
});
```

**Implementation hint:** Read from `report_cards` (pre-computed), use Eloquent `avg()` — covered by `(class_id, semester_id)` index on `report_cards`.

```php
public function classAvgComparison(int $semesterId): array
{
    $rows = DB::table('report_cards')
        ->join('classes', 'report_cards.class_id', '=', 'classes.id')
        ->where('report_cards.semester_id', $semesterId)
        ->where('report_cards.report_type', 'final')
        ->selectRaw('report_cards.class_id, classes.name as class_name, ROUND(AVG(report_cards.average_score), 2) as avg')
        ->groupBy('report_cards.class_id', 'classes.name')
        ->orderByDesc('avg')
        ->get();

    return [
        'data' => $rows->map(fn ($r) => [
            'class_id'   => $r->class_id,
            'class_name' => $r->class_name,
            'avg'        => (float) $r->avg,
        ])->all(),
        'meta' => ['semester_id' => $semesterId, 'generated_at' => now()->toIso8601String()],
    ];
}
```

---

### Task 4: `subjectGradeDistribution(int $classId, int $semesterId)` — TDD

**Test:**
```php
it('subjectGradeDistribution returns A/B/C/D counts per subject for the class', function () {
    $class = SchoolClass::factory()->create();
    $sem   = Semester::factory()->create();
    $subj  = Subject::factory()->create(['status' => 'active']);
    $students = Student::factory()->count(4)->create(['class_id' => $class->id]);

    $predicates = ['A', 'B', 'C', 'D'];
    foreach ($students as $i => $s) {
        Grade::factory()->create([
            'student_id'  => $s->id,
            'class_id'    => $class->id,
            'semester_id' => $sem->id,
            'subject_id'  => $subj->id,
            'predicate'   => $predicates[$i],
        ]);
    }

    $result = app(AnalyticsService::class)->subjectGradeDistribution($class->id, $sem->id);

    $row = collect($result['data'])->firstWhere('subject_id', $subj->id);
    expect($row['counts']['A'])->toBe(1)
        ->and($row['counts']['D'])->toBe(1);
});
```

**Implementation:**
```php
public function subjectGradeDistribution(int $classId, int $semesterId): array
{
    $rows = DB::table('grades')
        ->join('subjects', 'grades.subject_id', '=', 'subjects.id')
        ->where('grades.class_id', $classId)
        ->where('grades.semester_id', $semesterId)
        ->selectRaw('grades.subject_id, subjects.name as subject_name, grades.predicate, COUNT(*) as cnt')
        ->groupBy('grades.subject_id', 'subjects.name', 'grades.predicate')
        ->get();

    $grouped = $rows->groupBy('subject_id')->map(function ($items, $subjId) {
        $counts = ['A' => 0, 'B' => 0, 'C' => 0, 'D' => 0];
        foreach ($items as $item) {
            $counts[$item->predicate] = (int) $item->cnt;
        }
        return [
            'subject_id'   => $subjId,
            'subject_name' => $items->first()->subject_name,
            'counts'       => $counts,
        ];
    })->values()->all();

    return [
        'data' => $grouped,
        'meta' => ['class_id' => $classId, 'semester_id' => $semesterId, 'generated_at' => now()->toIso8601String()],
    ];
}
```

---

### Task 5: `attendanceTrend(int $classId, int $semesterId, int $weeks = 12)` — TDD

**Test:**
```php
it('attendanceTrend returns weekly present-% for last N weeks for a class', function () {
    $class = SchoolClass::factory()->create();
    $sem   = Semester::factory()->create(['is_active' => true]);
    $s     = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);

    // 2 records this week: 1 present, 1 absent
    Attendance::factory()->create(['class_id' => $class->id, 'student_id' => $s->id,
        'semester_id' => $sem->id, 'date' => now()->startOfWeek(), 'status' => 'present']);
    Attendance::factory()->create(['class_id' => $class->id, 'student_id' => $s->id,
        'semester_id' => $sem->id, 'date' => now()->startOfWeek()->addDay(), 'status' => 'absent']);

    $result = app(AnalyticsService::class)->attendanceTrend($class->id, $sem->id, 4);

    $thisWeek = collect($result['data'])->last(); // most recent week
    expect($thisWeek['percentage'])->toBe(50.0);
    expect($result['data'])->toHaveCount(4);
});
```

**Implementation hint:** Use `YEARWEEK(date, 1)` (MySQL/MariaDB) or `strftime('%Y-%W', date)` (SQLite for tests).
Wrap in `DB::raw()` with a DB driver check via `config('database.default')`.

```php
public function attendanceTrend(int $classId, int $semesterId, int $weeks = 12): array
{
    $since  = now()->subWeeks($weeks)->startOfWeek();
    $driver = config('database.default');
    $weekExpr = $driver === 'sqlite'
        ? "strftime('%Y-%W', date)"
        : "YEARWEEK(date, 1)";

    $rows = DB::table('attendance')
        ->where('class_id', $classId)
        ->where('semester_id', $semesterId)
        ->where('date', '>=', $since)
        ->selectRaw("{$weekExpr} as week_key, status, COUNT(*) as cnt")
        ->groupByRaw("{$weekExpr}, status")
        ->orderBy('week_key')
        ->get();

    $byWeek = $rows->groupBy('week_key');
    $data = $byWeek->map(function ($items, $week) {
        $present = $items->where('status', 'present')->sum('cnt');
        $total   = $items->sum('cnt');
        return [
            'week'       => $week,
            'present'    => (int) $present,
            'total'      => (int) $total,
            'percentage' => $total > 0 ? round($present / $total * 100, 1) : 0.0,
        ];
    })->values()->all();

    return [
        'data' => $data,
        'meta' => ['class_id' => $classId, 'semester_id' => $semesterId, 'weeks' => $weeks],
    ];
}
```

---

### Task 6: `atRiskStudents(int $semesterId, float $kktp = null)` — TDD

**Test:**
```php
it('atRiskStudents returns students below KKTP and below 85% attendance', function () {
    config(['floz.kktp_default' => 70]);
    $sem   = Semester::factory()->create(['is_active' => true]);
    $class = SchoolClass::factory()->create();

    $atRisk  = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);
    $safe    = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);

    // at-risk: avg_score < 70 AND attendance < 85%
    ReportCard::factory()->create([
        'student_id'   => $atRisk->id, 'class_id' => $class->id,
        'semester_id'  => $sem->id, 'report_type' => 'final',
        'average_score' => 60.0,
        'attendance_present' => 10, 'attendance_sick' => 0,
        'attendance_permit' => 0,  'attendance_absent' => 5,
    ]);
    // safe: avg_score >= 70
    ReportCard::factory()->create([
        'student_id'   => $safe->id, 'class_id' => $class->id,
        'semester_id'  => $sem->id, 'report_type' => 'final',
        'average_score' => 80.0,
        'attendance_present' => 14, 'attendance_sick' => 0,
        'attendance_permit' => 0,  'attendance_absent' => 1,
    ]);

    $result = app(AnalyticsService::class)->atRiskStudents($sem->id);

    $ids = collect($result['data'])->pluck('student_id');
    expect($ids)->toContain($atRisk->id)
        ->and($ids)->not->toContain($safe->id);
});
```

**Implementation:** Read from `report_cards` (pre-computed) — no JOIN needed for grade part. Attendance % derived from stored `attendance_present / (present+sick+permit+absent)`.

```php
public function atRiskStudents(int $semesterId, float $kktp = null): array
{
    $kktp ??= config('floz.kktp_default', 70);

    $rows = DB::table('report_cards')
        ->join('students', 'report_cards.student_id', '=', 'students.id')
        ->join('classes',  'report_cards.class_id',   '=', 'classes.id')
        ->where('report_cards.semester_id', $semesterId)
        ->where('report_cards.report_type', 'final')
        ->where('students.status', 'active')
        ->where('report_cards.average_score', '<', $kktp)
        ->selectRaw('
            report_cards.student_id,
            students.name as student_name,
            report_cards.class_id,
            classes.name as class_name,
            report_cards.average_score,
            report_cards.attendance_present,
            report_cards.attendance_sick,
            report_cards.attendance_permit,
            report_cards.attendance_absent
        ')
        ->get();

    $data = $rows->filter(function ($r) {
        $total = $r->attendance_present + $r->attendance_sick
               + $r->attendance_permit + $r->attendance_absent;
        if ($total === 0) return false;
        return ($r->attendance_present / $total * 100) < 85;
    })->map(fn ($r) => [
        'student_id'   => $r->student_id,
        'student_name' => $r->student_name,
        'class_id'     => $r->class_id,
        'class_name'   => $r->class_name,
        'avg_score'    => (float) $r->average_score,
        'attendance_%' => $r->attendance_present + $r->attendance_sick
                        + $r->attendance_permit + $r->attendance_absent > 0
            ? round($r->attendance_present
                / ($r->attendance_present + $r->attendance_sick
                   + $r->attendance_permit + $r->attendance_absent) * 100, 1)
            : 0.0,
    ])->values()->all();

    return [
        'data' => $data,
        'meta' => ['semester_id' => $semesterId, 'kktp' => $kktp, 'attendance_threshold' => 85],
    ];
}
```

---

### Task 7: `teacherWorkload(int $academicYearId)` — TDD

**Test:**
```php
it('teacherWorkload returns teacher name, TA count, and weekly hours', function () {
    $ay      = AcademicYear::factory()->create(['is_active' => true]);
    $teacher = Teacher::factory()->create();
    $class   = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $subj    = Subject::factory()->create();

    TeachingAssignment::factory()->create([
        'teacher_id'       => $teacher->id,
        'class_id'         => $class->id,
        'subject_id'       => $subj->id,
        'academic_year_id' => $ay->id,
    ]);
    // Create 2 schedules for this TA (each = 1 jam pelajaran = 35 min)
    $ta = TeachingAssignment::where('teacher_id', $teacher->id)->first();
    Schedule::factory()->count(2)->create(['teaching_assignment_id' => $ta->id]);

    $result = app(AnalyticsService::class)->teacherWorkload($ay->id);

    $row = collect($result['data'])->firstWhere('teacher_id', $teacher->id);
    expect($row['ta_count'])->toBe(1)
        ->and($row['weekly_sessions'])->toBe(2);
});
```

**Implementation:**
```php
public function teacherWorkload(int $academicYearId): array
{
    $rows = DB::table('teaching_assignments as ta')
        ->join('teachers', 'ta.teacher_id', '=', 'teachers.id')
        ->leftJoin('schedules', 'schedules.teaching_assignment_id', '=', 'ta.id')
        ->where('ta.academic_year_id', $academicYearId)
        ->selectRaw('ta.teacher_id, teachers.name as teacher_name, COUNT(DISTINCT ta.id) as ta_count, COUNT(schedules.id) as weekly_sessions')
        ->groupBy('ta.teacher_id', 'teachers.name')
        ->orderBy('teachers.name')
        ->get();

    return [
        'data' => $rows->map(fn ($r) => [
            'teacher_id'      => $r->teacher_id,
            'teacher_name'    => $r->teacher_name,
            'ta_count'        => (int) $r->ta_count,
            'weekly_sessions' => (int) $r->weekly_sessions,
        ])->all(),
        'meta' => ['academic_year_id' => $academicYearId, 'generated_at' => now()->toIso8601String()],
    ];
}
```

---

## Wave 2: AnalyticsController + Routes + Policy

**Files created:**
- `src/app/Http/Controllers/AnalyticsController.php`
- `src/app/Policies/AnalyticsPolicy.php`
- `src/tests/Feature/AnalyticsControllerTest.php`

**Files modified:**
- `src/routes/web.php`
- `src/app/Providers/AppServiceProvider.php`
- `src/app/Http/Middleware/HandleInertiaRequests.php`

---

### Task 8: `AnalyticsPolicy` + AppServiceProvider registration

```php
// src/app/Policies/AnalyticsPolicy.php
namespace App\Policies;

use App\Models\User;

class AnalyticsPolicy
{
    public function view(User $user): bool
    {
        return $user->isSchoolAdmin();
    }
}
```

Register in `AppServiceProvider::boot()` (follow existing pattern — check Gate::getPolicyFor first):
```php
Gate::policy(\App\Models\User::class . '@analytics', \App\Policies\AnalyticsPolicy::class);
// Or use Gate::define for model-less policies:
Gate::define('view-analytics', fn (User $user) => $user->isSchoolAdmin());
```

**HandleInertiaRequests** — add to shared permissions array:
```php
'view_analytics' => $user->isSchoolAdmin(),
```

---

### Task 9: `AnalyticsController` + routes + feature tests

**Controller (`src/app/Http/Controllers/AnalyticsController.php`):**

```php
<?php

namespace App\Http\Controllers;

use App\Services\AnalyticsService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Inertia\Inertia;
use Inertia\Response;

class AnalyticsController extends Controller
{
    public function __construct(private readonly AnalyticsService $analytics) {}

    public function index(): Response
    {
        $this->authorize('view-analytics');

        $semester = \App\Models\Semester::where('is_active', true)->firstOrFail();
        $ay       = $semester->academicYear;

        return Inertia::render('Analytics/Dashboard', [
            'todaysAttendance'       => $this->analytics->todaysAttendance(),
            'missingAttendance'      => $this->analytics->classesMissingAttendance(),
            'classAvgComparison'     => $this->analytics->classAvgComparison($semester->id),
            'teacherWorkload'        => $this->analytics->teacherWorkload($ay->id),
            'activeSemester'         => $semester,
        ]);
    }

    public function reports(): Response
    {
        $this->authorize('view-analytics');

        $semester = \App\Models\Semester::where('is_active', true)->firstOrFail();

        return Inertia::render('Analytics/Reports', [
            'activeSemester' => $semester,
            'classes'        => \App\Models\SchoolClass::where('academic_year_id', $semester->academicYear->id)
                                    ->orderBy('name')->get(['id', 'name']),
        ]);
    }

    public function data(Request $request, string $widget): JsonResponse
    {
        $this->authorize('view-analytics');

        $semesterId = (int) $request->input('semester_id',
            \App\Models\Semester::where('is_active', true)->value('id'));
        $classId    = (int) $request->input('class_id', 0);

        $result = match ($widget) {
            'subject-grade-distribution' => $this->analytics->subjectGradeDistribution($classId, $semesterId),
            'attendance-trend'           => $this->analytics->attendanceTrend($classId, $semesterId),
            'at-risk-students'           => $this->analytics->atRiskStudents($semesterId),
            'teacher-workload'           => $this->analytics->teacherWorkload(
                                               \App\Models\Semester::findOrFail($semesterId)->academicYear->id
                                           ),
            default => abort(404, "Widget {$widget} not found"),
        };

        return response()->json($result);
    }

    public function exportAttendance(Request $request)
    {
        $this->authorize('view-analytics');

        $request->validate(['semester_id' => 'required|integer|exists:semesters,id']);
        $semester   = \App\Models\Semester::with('academicYear')->findOrFail($request->semester_id);
        $schoolName = config('app.school_name', 'Sekolah');
        $filename   = "Rekap_Absensi_{$schoolName}_{$semester->academicYear->name}_Sem{$semester->semester_number}_" . now()->format('Ymd') . '.xlsx';

        return \Maatwebsite\Excel\Facades\Excel::download(
            new \App\Exports\AttendanceRecapExport($semester->id),
            $filename
        );
    }
}
```

**Routes (`src/routes/web.php`)** — inside `auth` + `role:school_admin` middleware group:
```php
use App\Http\Controllers\AnalyticsController;

Route::prefix('analytics')->middleware(['auth', 'role:school_admin'])->group(function () {
    Route::get('/',               [AnalyticsController::class, 'index'])->name('analytics.index');
    Route::get('/reports',        [AnalyticsController::class, 'reports'])->name('analytics.reports');
    Route::get('/data/{widget}',  [AnalyticsController::class, 'data'])->name('analytics.data');
    Route::get('/export/attendance', [AnalyticsController::class, 'exportAttendance'])->name('analytics.export.attendance');
});
```

**Feature tests (`src/tests/Feature/AnalyticsControllerTest.php`):**

```php
<?php

use App\Models\Semester;
use App\Models\User;

uses(Illuminate\Foundation\Testing\RefreshDatabase::class);

function analyticsAdmin(): User
{
    return User::factory()->create(['role' => 'school_admin']);
}

function analyticsTeacher(): User
{
    return User::factory()->create(['role' => 'teacher']);
}

it('teacher cannot access analytics index (403)', function () {
    $sem = Semester::factory()->create(['is_active' => true]);
    $this->actingAs(analyticsTeacher())->get(route('analytics.index'))->assertForbidden();
});

it('guest is redirected to login from analytics', function () {
    $this->get(route('analytics.index'))->assertRedirect(route('login'));
});

it('admin can access analytics dashboard', function () {
    Semester::factory()->create(['is_active' => true]);
    $this->actingAs(analyticsAdmin())
        ->get(route('analytics.index'))
        ->assertOk()
        ->assertInertia(fn ($page) => $page->component('Analytics/Dashboard')
            ->has('todaysAttendance')
            ->has('missingAttendance')
            ->has('classAvgComparison')
        );
});

it('admin can access analytics reports page', function () {
    Semester::factory()->create(['is_active' => true]);
    $this->actingAs(analyticsAdmin())
        ->get(route('analytics.reports'))
        ->assertOk()
        ->assertInertia(fn ($page) => $page->component('Analytics/Reports'));
});

it('data endpoint returns JSON for at-risk-students widget', function () {
    $sem = Semester::factory()->create(['is_active' => true]);
    $this->actingAs(analyticsAdmin())
        ->getJson(route('analytics.data', 'at-risk-students') . "?semester_id={$sem->id}")
        ->assertOk()
        ->assertJsonStructure(['data', 'meta']);
});

it('data endpoint returns 404 for unknown widget', function () {
    Semester::factory()->create(['is_active' => true]);
    $this->actingAs(analyticsAdmin())
        ->getJson(route('analytics.data', 'nonexistent-widget'))
        ->assertNotFound();
});

it('export attendance requires semester_id', function () {
    $this->actingAs(analyticsAdmin())
        ->get(route('analytics.export.attendance'))
        ->assertSessionHasErrors(['semester_id']);
});
```

---

## Wave 3: Excel Export

**Files created:**
- `src/app/Exports/AttendanceRecapExport.php`
- `src/app/Exports/Sheets/ClassAttendanceSheet.php`
- `src/tests/Feature/AttendanceExportTest.php`

---

### Task 11: `AttendanceRecapExport` + `ClassAttendanceSheet` + tests

**`src/app/Exports/AttendanceRecapExport.php`:**
```php
<?php

namespace App\Exports;

use App\Exports\Sheets\ClassAttendanceSheet;
use App\Models\SchoolClass;
use App\Models\Semester;
use Maatwebsite\Excel\Concerns\WithMultipleSheets;

class AttendanceRecapExport implements WithMultipleSheets
{
    public function __construct(private readonly int $semesterId) {}

    public function sheets(): array
    {
        $sem     = Semester::with('academicYear')->findOrFail($this->semesterId);
        $ayId    = $sem->academicYear->id;
        $classes = SchoolClass::where('academic_year_id', $ayId)->orderBy('name')->get();

        return $classes->map(fn ($class) =>
            new ClassAttendanceSheet($class, $this->semesterId)
        )->all();
    }
}
```

**`src/app/Exports/Sheets/ClassAttendanceSheet.php`:**
```php
<?php

namespace App\Exports\Sheets;

use App\Models\Attendance;
use App\Models\SchoolClass;
use App\Models\Student;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithTitle;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class ClassAttendanceSheet implements FromCollection, WithHeadings, WithTitle, WithStyles
{
    public function __construct(
        private readonly SchoolClass $class,
        private readonly int $semesterId,
    ) {}

    public function title(): string
    {
        return substr($this->class->name, 0, 31); // Excel sheet name max 31 chars
    }

    public function headings(): array
    {
        return ['No', 'NIS', 'Nama Siswa', 'Hadir', 'Sakit', 'Izin', 'Alpha', '% Kehadiran'];
    }

    public function collection(): Collection
    {
        // NOTE: Format must match Dinas template.
        // Request real Dinas sample from school in Phase 11.5 if not yet obtained.
        // Current layout: per-student aggregate (H/S/I/A total per semester).
        // When monthly sub-columns are confirmed, add [Month: H S I A] columns.

        $students = Student::where('class_id', $this->class->id)
            ->where('status', 'active')
            ->orderBy('name')
            ->get(['id', 'nis', 'name']);

        return $students->map(function ($student, $idx) {
            $counts = Attendance::where('student_id', $student->id)
                ->where('semester_id', $this->semesterId)
                ->selectRaw('status, COUNT(*) as cnt')
                ->groupBy('status')
                ->pluck('cnt', 'status');

            $h = (int) ($counts['present'] ?? 0);
            $s = (int) ($counts['sick']    ?? 0);
            $i = (int) ($counts['permit']  ?? 0);
            $a = (int) ($counts['absent']  ?? 0);
            $total = $h + $s + $i + $a;
            $pct   = $total > 0 ? round($h / $total * 100, 1) : 0.0;

            return [$idx + 1, $student->nis, $student->name, $h, $s, $i, $a, "{$pct}%"];
        });
    }

    public function styles(Worksheet $sheet): array
    {
        return [
            1 => ['font' => ['bold' => true]],
        ];
    }
}
```

**Test (`src/tests/Feature/AttendanceExportTest.php`):**
```php
<?php

use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\User;
use App\Models\Attendance;
use Maatwebsite\Excel\Facades\Excel;

uses(Illuminate\Foundation\Testing\RefreshDatabase::class);

it('export attendance returns an xlsx download for admin', function () {
    Excel::fake();

    $ay    = \App\Models\AcademicYear::factory()->create(['is_active' => true]);
    $sem   = Semester::factory()->create(['academic_year_id' => $ay->id, 'is_active' => true]);
    $admin = User::factory()->create(['role' => 'school_admin']);

    $this->actingAs($admin)
        ->get(route('analytics.export.attendance', ['semester_id' => $sem->id]))
        ->assertOk();

    Excel::assertDownloaded(fn (string $filename) => str_contains($filename, 'Rekap_Absensi'));
});

it('export attendance is forbidden for teacher', function () {
    $sem = Semester::factory()->create(['is_active' => true]);
    $teacher = User::factory()->create(['role' => 'teacher']);

    $this->actingAs($teacher)
        ->get(route('analytics.export.attendance', ['semester_id' => $sem->id]))
        ->assertForbidden();
});

it('ClassAttendanceSheet produces correct H/S/I/A row for a student', function () {
    $ay      = \App\Models\AcademicYear::factory()->create(['is_active' => true]);
    $sem     = Semester::factory()->create(['academic_year_id' => $ay->id, 'is_active' => true]);
    $class   = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $student = Student::factory()->create(['class_id' => $class->id, 'status' => 'active', 'nis' => '12345']);

    Attendance::factory()->count(10)->create([
        'student_id' => $student->id, 'class_id' => $class->id,
        'semester_id' => $sem->id, 'status' => 'present',
    ]);
    Attendance::factory()->count(2)->create([
        'student_id' => $student->id, 'class_id' => $class->id,
        'semester_id' => $sem->id, 'status' => 'absent',
    ]);

    $sheet = new \App\Exports\Sheets\ClassAttendanceSheet($class, $sem->id);
    $row   = $sheet->collection()->first();

    expect($row[3])->toBe(10)  // Hadir
        ->and($row[6])->toBe(2)   // Alpha
        ->and($row[7])->toBe('83.3%'); // % Kehadiran
});
```

---

## Wave 4: Frontend (Vue + ApexCharts)

**Files created:**
- `src/resources/js/Components/Charts/BaseChart.vue`
- `src/resources/js/Pages/Analytics/Dashboard.vue`
- `src/resources/js/Pages/Analytics/Reports.vue`

**Files modified:**
- `src/resources/js/Layouts/AppLayout.vue`
- `package.json` (via npm install)

---

### Task 12: Install ApexCharts + SSR wrapper

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
npm install apexcharts@5.11 vue3-apexcharts@1.11
```

No changes to `vite.config.js` needed.

---

### Task 13 + 15: `BaseChart.vue` + `Dashboard.vue`

**`src/resources/js/Components/Charts/BaseChart.vue`:**

```vue
<script setup>
/**
 * BaseChart — SSR-safe ApexCharts wrapper.
 * All chart components use defineAsyncComponent + ssr:false.
 * Import this instead of vue3-apexcharts directly.
 */
import { defineAsyncComponent } from 'vue';

const ApexChart = defineAsyncComponent({
    loader: () => import('vue3-apexcharts'),
    ssr: false,
});

defineProps({
    type:    { type: String, required: true },
    options: { type: Object, default: () => ({}) },
    series:  { type: Array,  default: () => [] },
    height:  { type: [String, Number], default: 300 },
});
</script>

<template>
    <ApexChart :type="type" :options="options" :series="series" :height="height" />
</template>
```

**`src/resources/js/Pages/Analytics/Dashboard.vue`:**

```vue
<script setup>
import AppLayout from '@/Layouts/AppLayout.vue';
import BaseChart from '@/Components/Charts/BaseChart.vue';
import { computed } from 'vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    todaysAttendance:   Object,
    missingAttendance:  Object,
    classAvgComparison: Object,
    teacherWorkload:    Object,
    activeSemester:     Object,
});

// W1 — Attendance stat card
const attendance = computed(() => props.todaysAttendance.data);

// W3 — Class avg comparison horizontal bar
const classAvgOptions = computed(() => ({
    chart: { type: 'bar', toolbar: { show: false } },
    plotOptions: { bar: { horizontal: true } },
    xaxis: { categories: props.classAvgComparison.data.map(r => r.class_name) },
    colors: ['#f97316'],
    dataLabels: { enabled: true, formatter: v => `${v}` },
}));
const classAvgSeries = computed(() => [{
    name: 'Rata-rata Nilai',
    data: props.classAvgComparison.data.map(r => r.avg),
}]);

// W8 — Top + at-risk class pair
const sortedClasses = computed(() =>
    [...props.classAvgComparison.data].sort((a, b) => b.avg - a.avg)
);
const topClass    = computed(() => sortedClasses.value[0] ?? null);
const atRiskClass = computed(() => sortedClasses.value[sortedClasses.value.length - 1] ?? null);
</script>

<template>
    <Head title="Dashboard Analitik" />
    <div class="p-6 space-y-6">
        <h1 class="text-2xl font-semibold text-slate-800">Dashboard Pagi — Kepala Sekolah</h1>
        <p class="text-sm text-slate-500">Semester aktif: {{ activeSemester?.name }}</p>

        <!-- W1: Today's Attendance -->
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div class="rounded-xl border p-4 bg-white text-center">
                <p class="text-3xl font-bold" :class="attendance.percentage >= 95 ? 'text-green-600' : attendance.percentage >= 85 ? 'text-yellow-500' : 'text-red-600'">
                    {{ attendance.percentage }}%
                </p>
                <p class="text-xs text-slate-500 mt-1">Kehadiran Hari Ini</p>
            </div>
            <div v-for="(label, key) in { present: 'Hadir', sick: 'Sakit', permit: 'Izin', absent: 'Alpha' }"
                 :key="key" class="rounded-xl border p-4 bg-white text-center">
                <p class="text-2xl font-bold text-slate-700">{{ attendance[key] }}</p>
                <p class="text-xs text-slate-500 mt-1">{{ label }}</p>
            </div>
        </div>

        <!-- W2: Classes Missing Attendance -->
        <div class="rounded-xl border bg-white p-4">
            <h2 class="font-semibold text-slate-700 mb-3">Kelas Belum Isi Absensi Hari Ini</h2>
            <div v-if="missingAttendance.data.length === 0" class="text-green-600 text-sm">
                Semua kelas sudah mengisi absensi.
            </div>
            <ul v-else class="divide-y divide-slate-100">
                <li v-for="item in missingAttendance.data" :key="item.class_id"
                    class="py-2 flex justify-between text-sm">
                    <span class="font-medium text-slate-800">{{ item.class_name }}</span>
                    <span class="text-slate-500">Wali: {{ item.homeroom_teacher }}</span>
                </li>
            </ul>
        </div>

        <!-- W3: Class Avg Comparison -->
        <div class="rounded-xl border bg-white p-4">
            <h2 class="font-semibold text-slate-700 mb-3">Perbandingan Rata-rata Nilai per Kelas</h2>
            <BaseChart type="bar" :options="classAvgOptions" :series="classAvgSeries" :height="280" />
        </div>

        <!-- W8: Top + At-Risk Class Pair -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="rounded-xl border border-green-200 bg-green-50 p-4">
                <p class="text-xs font-semibold uppercase text-green-600 mb-1">Kelas Terbaik</p>
                <p class="text-lg font-bold text-slate-800">{{ topClass?.class_name ?? '–' }}</p>
                <p class="text-sm text-slate-600">Rata-rata: {{ topClass?.avg ?? '–' }}</p>
            </div>
            <div class="rounded-xl border border-red-200 bg-red-50 p-4">
                <p class="text-xs font-semibold uppercase text-red-600 mb-1">Perlu Perhatian</p>
                <p class="text-lg font-bold text-slate-800">{{ atRiskClass?.class_name ?? '–' }}</p>
                <p class="text-sm text-slate-600">Rata-rata: {{ atRiskClass?.avg ?? '–' }}</p>
            </div>
        </div>
    </div>
</template>
```

---

### Task 14: `Reports.vue` (filter panel + 3 charts + export)

**`src/resources/js/Pages/Analytics/Reports.vue`:**

```vue
<script setup>
import AppLayout from '@/Layouts/AppLayout.vue';
import BaseChart from '@/Components/Charts/BaseChart.vue';
import { ref, computed, watch } from 'vue';
import { usePage, router } from '@inertiajs/vue3';

defineOptions({ layout: AppLayout });

const props = defineProps({
    activeSemester: Object,
    classes:        Array,
});

// Filter state
const selectedClassId = ref(props.classes[0]?.id ?? null);

// Lazy-loaded widget data
const gradeDistribution = ref(null);
const attendanceTrend   = ref(null);
const atRiskStudents    = ref(null);
const loading           = ref(false);

async function fetchWidgets() {
    if (!selectedClassId.value) return;
    loading.value = true;

    const semId   = props.activeSemester.id;
    const classId = selectedClassId.value;
    const base    = route('analytics.data', '');

    const [gradeRes, trendRes, riskRes] = await Promise.all([
        fetch(`${base}subject-grade-distribution?semester_id=${semId}&class_id=${classId}`).then(r => r.json()),
        fetch(`${base}attendance-trend?semester_id=${semId}&class_id=${classId}`).then(r => r.json()),
        fetch(`${base}at-risk-students?semester_id=${semId}`).then(r => r.json()),
    ]);

    gradeDistribution.value = gradeRes;
    attendanceTrend.value   = trendRes;
    atRiskStudents.value    = riskRes;
    loading.value           = false;
}

watch(selectedClassId, fetchWidgets, { immediate: true });

// W4 — Subject grade distribution stacked bar
const gradeOptions = computed(() => {
    if (!gradeDistribution.value) return {};
    const categories = gradeDistribution.value.data.map(r => r.subject_name);
    return {
        chart: { type: 'bar', stacked: true, toolbar: { show: false } },
        xaxis: { categories },
        colors: ['#22c55e', '#86efac', '#fbbf24', '#ef4444'],
        dataLabels: { enabled: false },
        legend: { position: 'bottom' },
    };
});
const gradeSeries = computed(() => {
    if (!gradeDistribution.value) return [];
    return ['A', 'B', 'C', 'D'].map(pred => ({
        name: `Predikat ${pred}`,
        data: gradeDistribution.value.data.map(r => r.counts[pred] ?? 0),
    }));
});

// W5 — Attendance trend line
const trendOptions = computed(() => {
    if (!attendanceTrend.value) return {};
    return {
        chart: { type: 'line', toolbar: { show: false } },
        xaxis: { categories: attendanceTrend.value.data.map(r => r.week) },
        yaxis: { min: 0, max: 100, labels: { formatter: v => `${v}%` } },
        colors: ['#f97316'],
        stroke: { curve: 'smooth', width: 2 },
    };
});
const trendSeries = computed(() => attendanceTrend.value ? [{
    name: '% Kehadiran',
    data: attendanceTrend.value.data.map(r => r.percentage),
}] : []);

function downloadExcel() {
    window.location.href = route('analytics.export.attendance') + `?semester_id=${props.activeSemester.id}`;
}
</script>

<template>
    <Head title="Laporan Analitik" />
    <div class="p-6 space-y-6">
        <div class="flex items-center justify-between">
            <h1 class="text-2xl font-semibold text-slate-800">Laporan — Admin</h1>
            <button @click="downloadExcel"
                class="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700">
                Unduh Rekap Absensi (.xlsx)
            </button>
        </div>

        <!-- Filter -->
        <div class="flex items-center gap-3">
            <label class="text-sm font-medium text-slate-600">Kelas:</label>
            <select v-model="selectedClassId" class="rounded-md border border-slate-300 px-3 py-1.5 text-sm">
                <option v-for="cls in classes" :key="cls.id" :value="cls.id">{{ cls.name }}</option>
            </select>
        </div>

        <div v-if="loading" class="text-slate-500 text-sm">Memuat data...</div>

        <!-- W4: Subject grade distribution -->
        <div class="rounded-xl border bg-white p-4">
            <h2 class="font-semibold text-slate-700 mb-3">Distribusi Nilai per Mata Pelajaran (Predikat A/B/C/D)</h2>
            <BaseChart v-if="gradeDistribution" type="bar" :options="gradeOptions" :series="gradeSeries" :height="280" />
        </div>

        <!-- W5: Attendance trend -->
        <div class="rounded-xl border bg-white p-4">
            <h2 class="font-semibold text-slate-700 mb-3">Tren Kehadiran 12 Minggu Terakhir</h2>
            <BaseChart v-if="attendanceTrend" type="line" :options="trendOptions" :series="trendSeries" :height="240" />
        </div>

        <!-- W6 (At-Risk) + W7 (Teacher Workload) are tables; no chart component needed -->

        <!-- W6: At-risk students -->
        <div class="rounded-xl border bg-white p-4">
            <h2 class="font-semibold text-slate-700 mb-3">
                Siswa Berisiko (Nilai &lt; KKTP dan Kehadiran &lt; 85%)
            </h2>
            <table v-if="atRiskStudents" class="min-w-full text-sm divide-y divide-slate-100">
                <thead class="bg-slate-50 text-xs uppercase text-slate-500">
                    <tr>
                        <th class="px-3 py-2 text-left">Nama</th>
                        <th class="px-3 py-2 text-left">Kelas</th>
                        <th class="px-3 py-2 text-right">Rata-rata Nilai</th>
                        <th class="px-3 py-2 text-right">% Kehadiran</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    <tr v-for="s in atRiskStudents.data" :key="s.student_id">
                        <td class="px-3 py-2 font-medium text-slate-800">{{ s.student_name }}</td>
                        <td class="px-3 py-2 text-slate-600">{{ s.class_name }}</td>
                        <td class="px-3 py-2 text-right text-red-600 font-semibold">{{ s.avg_score }}</td>
                        <td class="px-3 py-2 text-right text-red-600">{{ s['attendance_%'] }}%</td>
                    </tr>
                    <tr v-if="atRiskStudents.data.length === 0">
                        <td colspan="4" class="px-3 py-6 text-center text-slate-400">Tidak ada siswa berisiko.</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>
```

---

### Task 16: AppLayout nav entry

**Modify `src/resources/js/Layouts/AppLayout.vue`** — add under existing RINGKASAN divider (or add divider if absent):

```javascript
// In navigation computed array, under RINGKASAN group:
{ name: 'Analitik', href: route('analytics.index'), icon: 'chart-bar', show: permissions.view_analytics },
{ name: 'Laporan',  href: route('analytics.reports'), icon: 'document-report', show: permissions.view_analytics },
```

Check existing SVG icon keys in AppLayout's switch block; use closest matching keys or add new SVG cases.

---

## Wave 5: Smoke + Tag

### Task 17: Manual smoke checklist

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan migrate
php artisan serve &
npm run dev &
```

- [ ] Login as school_admin → sidebar shows "Analitik" and "Laporan" nav items
- [ ] `/analytics` renders W1 stat cards (attendance %) with correct color coding
- [ ] `/analytics` renders W2 missing-attendance list (or "semua sudah isi" message)
- [ ] `/analytics` renders W3 horizontal bar chart (class avg comparison)
- [ ] `/analytics` renders W8 top class / at-risk class card pair
- [ ] `/analytics/reports` renders class filter dropdown
- [ ] Changing class dropdown triggers live fetch + chart update (W4, W5)
- [ ] W6 at-risk table loads and shows empty state if no at-risk students
- [ ] "Unduh Rekap Absensi" button downloads an `.xlsx` file
- [ ] Opened Excel file: one sheet per kelas, headers: No, NIS, Nama, Hadir, Sakit, Izin, Alpha, % Kehadiran
- [ ] Login as teacher → no "Analitik" nav item; direct GET `/analytics` returns 403
- [ ] Login as student → same 403

### Task 18: Regression + tag

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest
git tag phase11-analytics-complete
```

---

## Service Contract Reference

| Method | Signature | Returns |
|--------|-----------|---------|
| `todaysAttendance` | `(): array` | `{ data: {present, sick, permit, absent, percentage}, meta: {generated_at} }` |
| `classesMissingAttendance` | `(): array` | `{ data: [{class_id, class_name, homeroom_teacher}], meta: {date} }` |
| `classAvgComparison` | `(int $semesterId): array` | `{ data: [{class_id, class_name, avg}], meta: {semester_id} }` |
| `subjectGradeDistribution` | `(int $classId, int $semesterId): array` | `{ data: [{subject_id, subject_name, counts: {A,B,C,D}}], meta }` |
| `attendanceTrend` | `(int $classId, int $semesterId, int $weeks=12): array` | `{ data: [{week, present, total, percentage}], meta }` |
| `atRiskStudents` | `(int $semesterId, float $kktp=null): array` | `{ data: [{student_id, student_name, class_id, class_name, avg_score, attendance_%}], meta }` |
| `teacherWorkload` | `(int $academicYearId): array` | `{ data: [{teacher_id, teacher_name, ta_count, weekly_sessions}], meta }` |

---

## Test Count Target

| Layer | Tests | Description |
|-------|-------|-------------|
| Unit — AnalyticsServiceTest | 10 | 1–2 per method; cover happy path + empty state |
| Feature — AnalyticsControllerTest | 7 | auth gate, index render, reports render, data endpoint, 404 widget, export validation, teacher 403 |
| Feature — AttendanceExportTest | 3 | admin download OK, teacher 403, sheet row correctness |
| **Total** | **20** | No frontend tests in MVP; defer to Phase 11.5 |

---

## Definition of Done

- [ ] Wave 0 migration runs cleanly: 5 indexes added, `php artisan migrate` exits 0
- [ ] `KKTP_DEFAULT=70` in `.env.example`; `config('floz.kktp_default')` returns 70
- [ ] `AnalyticsService` has 7 methods; each returns `{ data, meta }`
- [ ] All 10 unit tests pass (`./vendor/bin/pest tests/Unit/AnalyticsServiceTest.php`)
- [ ] `AnalyticsPolicy::view` gates all 4 controller actions; teacher gets 403
- [ ] Routes registered: GET `/analytics`, GET `/analytics/reports`, GET `/analytics/data/{widget}`, GET `/analytics/export/attendance`
- [ ] All 7 feature controller tests pass
- [ ] All 3 export tests pass
- [ ] `AttendanceRecapExport` generates one sheet per kelas with correct headings
- [ ] Downloaded `.xlsx` filename matches pattern `Rekap_Absensi_<School>_<Semester>_<Date>.xlsx`
- [ ] ApexCharts installed; no `vite.config.js` changes required
- [ ] `BaseChart.vue` uses `defineAsyncComponent({ ssr: false })` — no SSR crash
- [ ] `/analytics` renders all 4 widgets without JS errors in browser console
- [ ] `/analytics/reports` filter dropdown triggers live data fetch (no full page reload)
- [ ] "Unduh" button downloads real Excel (not 200 HTML response)
- [ ] AppLayout shows Analitik/Laporan nav for school_admin; hidden for teacher/student
- [ ] Full regression: `./vendor/bin/pest` exits 0, no new failures
- [ ] Git tag `phase11-analytics-complete` created

---

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Excel template fidelity** — Dinas column format unconfirmed | High — export may need rework | Note in sheet header comment; request real template in Phase 11.5; current layout is aggregate (total H/S/I/A per semester), not monthly sub-columns |
| **Raw SQL portability** — `YEARWEEK()` MySQL vs `strftime()` SQLite | Medium — tests fail on SQLite CI | `attendanceTrend()` already branches on `config('database.default')`; confirm test DB driver in `phpunit.xml` |
| **N+1 in ClassAttendanceSheet** — per-student GROUP BY in a loop | Medium at 200 students | Acceptable at current scale; if slow, pre-load all attendance in one query keyed by student_id |
| **Bundle bloat** — ApexCharts 138 KB gzip | Low — admin-only page, not public | Acceptable tradeoff per D-1; only loaded on `/analytics*` routes |
| **`report_cards` not yet generated** — `classAvgComparison` and `atRiskStudents` read from `report_cards` | High if rapor not yet published | Document in controller: widgets return empty `data: []` with `meta.note: "Rapor belum diisi"` if no rows; no crash |
| **`isSchoolAdmin()` method** — must exist on User model | Low | Confirm in User model before writing Policy; if absent, use `$user->role === 'school_admin'` inline |

---

## Out of Scope (defer to Phase 11.5+)

- Teacher per-class scoped analytics view (wali kelas dashboard)
- PDF export (only Excel in MVP)
- Real-time refresh via Reverb / WebSockets
- Custom date range filters (semester filter only; no calendar picker)
- Monthly sub-column breakdown in Excel (confirm Dinas template first)
- Leger Nilai (grade summary) Excel export — prioritized as "should-have" but cut for MVP
- Mobile layout (admin web only)
- Semester Ganjil vs Genap comparison chart (W10)
- Heatmap siswa × mapel (W11)
- Dapodik direct sync or Rapor Pendidikan auto-upload
