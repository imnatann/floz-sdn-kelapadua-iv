# Plan Check — Phase 11: Reporting & Analytics Dashboard
**Date:** 2026-05-09 | **Reviewer:** plan-checker agent
**Plan file:** `.planning/PLAN_phase11_analytics.md`

---

## Verdict: EDIT-AND-PROCEED

Two blockers require targeted fixes before execution begins. Neither requires redesign — both are
contained fixes. All other dimensions pass.

---

## Critical (BLOCK)

### BLOCK-1: `attendanceTrend()` DB expression fails on the actual test database

**Location:** Plan lines 378–388 (`attendanceTrend` implementation hint)

```php
$driver = config('database.default');
$weekExpr = $driver === 'sqlite'
    ? "strftime('%Y-%W', date)"
    : "YEARWEEK(date, 1)";          // <-- MySQL-only
```

`phpunit.xml` sets `DB_CONNECTION=pgsql`. The branch is binary: `sqlite` → strftime, else →
`YEARWEEK()`. Postgres goes to the else-branch and throws:
`ERROR: function yearweek(date, integer) does not exist`.

**Fix:** Add a third branch for postgres:

```php
$weekExpr = match($driver) {
    'sqlite'  => "strftime('%Y-%W', \"date\")",
    'pgsql'   => "TO_CHAR(date, 'IYYY-IW')",
    default   => "YEARWEEK(date, 1)",
};
```

Also update the test (line 371 hint) to document the postgres expression.

---

### BLOCK-2: W7 (Teacher Workload) has no rendered UI in `Reports.vue`

**Location:** Plan lines 1230–1260 (`Reports.vue` template)

D-2 locks W7 to `/analytics/reports`. The service method is implemented (Task 7), the `data`
endpoint maps `teacher-workload` (line 665), and `teacherWorkload` is passed as a prop to
`Dashboard.vue` (line 635) — wrong page. `Reports.vue` fetches it lazily via the data endpoint
(line 665) but the template ends at the W6 at-risk table with a comment:
`<!-- W6 (At-Risk) + W7 (Teacher Workload) are tables; no chart component needed -->`.
No W7 table markup follows.

**Fix:** Add W7 table in `Reports.vue` template after W6. Also remove the `teacherWorkload` prop
from `index()` controller response — it doesn't belong on Dashboard.vue per D-2.

---

## Warning (WARN)

### WARN-1: `report_cards` empty-state mitigation is prose-only, not implemented

**Location:** Risk Register line 1369 vs `classAvgComparison` (line 264) and `atRiskStudents`
(line 457) implementations.

The Risk Register acknowledges this: "widgets return empty `data: []` with
`meta.note: 'Rapor belum diisi'` if no rows; no crash." But neither service method implements
`meta.note`. Both return bare `data: []` when no report_cards rows exist — correct for no-crash,
but the frontend has no way to distinguish "empty because rapor not published" from "empty because
genuinely zero at-risk students." W6 at-risk table shows "Tidak ada siswa berisiko" regardless.

**Fix:** Add `meta.note` field in both methods when `$rows->isEmpty()`:
```php
'meta' => ['semester_id' => $semesterId, 'note' => $rows->isEmpty() ? 'Rapor belum diisi' : null]
```
Update frontend to surface the note when present.

---

### WARN-2: 85% attendance threshold is hardcoded, undocumented in config

**Location:** Line 481 (`atRiskStudents` filter), line 498 (meta), line 1235 (template label).

KKTP score threshold is config-driven (D-11, `config('floz.kktp_default')`). The attendance
threshold (85%) is hardcoded at line 481 with no env key, no config entry, no `$kktp`-style
parameter. The domain research (RESEARCH_phase11_domain.md line 18) confirms 85% is the actual
Dinas threshold for kenaikan kelas — but schools may need to tune it.

**Fix (minimal):** Add `'attendance_threshold' => (int) env('ATTENDANCE_THRESHOLD', 85)` to
`config/floz.php` and `.env.example`. Read via `config('floz.attendance_threshold')` at line 481.

---

### WARN-3: Unit test count target is 10 but plan only writes 7

**Location:** Plan lines 1329–1334 (Test Count table) vs actual `it(...)` blocks.

The table promises "1–2 per method; cover happy path + empty state" = target 10. Only 7 unit
tests are written (one per method, happy path only). Three empty-state tests are missing:
- `classAvgComparison` with no report_cards rows → should return `data: []`
- `atRiskStudents` when all students are safe → `data: []`
- `attendanceTrend` for a class with no attendance in range → `data: []`

These are the exact scenarios most likely to produce a null-access JS error in production
(before rapor is published). Missing tests leave the risk register acknowledgement unverifiable.

**Fix:** Add the three empty-state tests to `AnalyticsServiceTest.php` before execution.

---

### WARN-4: `Gate::policy()` registration example at line 593 is invalid syntax

**Location:** Plan line 593:
```php
Gate::policy(\App\Models\User::class . '@analytics', \App\Policies\AnalyticsPolicy::class);
```
`Gate::policy($modelClass, $policyClass)` does not accept a string like `'Model@method'`. This
will silently fail or throw. The correct alternative is shown on line 595:
```php
Gate::define('view-analytics', fn (User $user) => $user->isSchoolAdmin());
```
**Fix:** Remove line 593 entirely. Keep only line 595. Update Task 8 to be unambiguous.

---

### WARN-5: Excel Dinas column format unconfirmed — export will likely need rework

**Location:** `ClassAttendanceSheet::collection()` lines 855–875; D-4.

Current output: one row per student, aggregate H/S/I/A totals per semester. Domain research
(RESEARCH_phase11_domain.md line 33) states Dinas format is "4-column sub-group per week or
month: H / S / I / A" — i.e., monthly sub-columns, not semester totals. The plan's `NOTE`
comment at line 852 acknowledges this explicitly and defers to Phase 11.5.

The plan is internally consistent on this (D-4 says "request real sample from school in Phase
11.5 if unavailable"). This is a WARNING not a BLOCK because the plan explicitly documents
the deferred-fidelity decision. The exported file will be usable for internal tracking but
will need a column layout change before formal Dinas submission.

---

## Approved Strengths

- Wave 0 index migration is correct — 5 targeted composite indexes, all covering real GROUP BY
  patterns used in the service methods. `down()` uses named indexes, safe.
- `attendanceTrend()` sqlite branch shows awareness of CI/prod DB divergence — just needs the
  postgres case added.
- `defineAsyncComponent({ ssr: false })` SSR guard is correct for Vue 3.5.28. SSR bootstrap
  does not exist in this project, making this defensive-but-harmless.
- Bundle size: Inertia uses `import.meta.glob('./Pages/**/*.vue')` (non-eager), so ApexCharts
  138KB will only land in the Analytics page chunks, not the main bundle.
- `atRiskStudents()` correctly reads pre-aggregated `attendance_present/sick/permit/absent`
  from `report_cards` — avoids a JOIN back to the raw attendance table.
- `isSchoolAdmin()` confirmed on `User` model (line 74). Policy is not speculative.
- `report_cards` schema confirmed: `attendance_present/sick/permit/absent` and `average_score`
  all exist; composite index `(class_id, semester_id)` already present.
- `ClassAttendanceSheet` N+1 is acknowledged in Risk Register and acceptable at current scale
  (~30 students/class in an SD). Fix path is documented.
- Excel sheet name truncation to 31 chars (line 841) is correct — PhpSpreadsheet enforces this.

---

## Test Coverage Gaps to Add

Before execution, add to `AnalyticsServiceTest.php`:

```php
it('classAvgComparison returns empty data when no report_cards exist', function () {
    $sem = Semester::factory()->create();
    $result = app(AnalyticsService::class)->classAvgComparison($sem->id);
    expect($result['data'])->toBeEmpty();
});

it('atRiskStudents returns empty data when all students are above threshold', function () {
    $sem  = Semester::factory()->create(['is_active' => true]);
    $class = SchoolClass::factory()->create();
    $student = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);
    ReportCard::factory()->create([
        'student_id' => $student->id, 'class_id' => $class->id,
        'semester_id' => $sem->id, 'report_type' => 'final',
        'average_score' => 90.0,
        'attendance_present' => 18, 'attendance_sick' => 0,
        'attendance_permit' => 0, 'attendance_absent' => 2,
    ]);
    $result = app(AnalyticsService::class)->atRiskStudents($sem->id);
    expect($result['data'])->toBeEmpty();
});

it('attendanceTrend returns empty data when class has no attendance in range', function () {
    $class = SchoolClass::factory()->create();
    $sem   = Semester::factory()->create(['is_active' => true]);
    $result = app(AnalyticsService::class)->attendanceTrend($class->id, $sem->id, 4);
    expect($result['data'])->toBeEmpty();
});
```

---

## Recommended Plan Edits

1. **BLOCK-1** — Replace binary `sqlite/else` driver check in `attendanceTrend()` with a 3-way
   `match` including `pgsql → TO_CHAR(date, 'IYYY-IW')`.

2. **BLOCK-2** — Add W7 teacher workload table to `Reports.vue` template after W6. Remove
   `teacherWorkload` from `AnalyticsController::index()` props (it belongs on reports, not dashboard).

3. **WARN-1** — Add `meta.note` to `classAvgComparison()` and `atRiskStudents()` when result is
   empty. Surface in frontend when note is present.

4. **WARN-2** — Add `ATTENDANCE_THRESHOLD=85` to `.env.example` and `config/floz.php`. Replace
   hardcoded `85` at line 481 with `config('floz.attendance_threshold', 85)`.

5. **WARN-3** — Add 3 empty-state unit tests (see "Test Coverage Gaps" above). This brings unit
   count from 7 to 10, matching the plan's own target.

6. **WARN-4** — Remove the invalid `Gate::policy(User::class . '@analytics', ...)` line 593.
   Keep only `Gate::define('view-analytics', ...)`.

---

## Final Recommendation

**EDIT-AND-PROCEED.** Fix BLOCK-1 (postgres week expression) and BLOCK-2 (W7 missing template)
before starting Wave 1. Both fixes are small (< 20 lines each). The remaining WARNs can be
resolved in parallel with Wave 0 execution or deferred to a cleanup task before Wave 5 smoke.

Do not start Wave 2 (controller) until BLOCK-2 is resolved — the controller already passes
`teacherWorkload` to the wrong page.
