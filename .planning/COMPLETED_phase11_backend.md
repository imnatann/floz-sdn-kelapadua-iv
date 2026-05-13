# Phase 11 Backend — Analytics Dashboard: COMPLETED

**Date:** 2026-05-09
**Branch:** chore/remove-tenant-leftovers
**Baseline tests:** 292 | **Final tests:** 316 | **Added:** 24

---

## Commits

| Hash     | Description |
|----------|-------------|
| a5d2f04  | feat(analytics): Wave 0 — 5 analytics indexes + config thresholds |
| b1271e4  | test(analytics): 10 failing unit tests for AnalyticsService (TDD RED) |
| 3771f09  | feat(analytics): AnalyticsService 7 widget methods (TDD GREEN) |
| 047226c  | feat(analytics): Wave 2 — Controller, Policy, routes, permissions |
| 9ebaca4  | feat(analytics): Wave 3 — Excel export AttendanceRecapExport + ClassAttendanceSheet |

---

## Tasks Completed

| Task | Description | Status |
|------|-------------|--------|
| 1    | Wave 0 migration (5 indexes) + index existence tests | DONE |
| 2    | AnalyticsService skeleton + TDD RED (10 tests) | DONE |
| 3-9  | 7 widget methods with TDD GREEN | DONE |
| 10   | AnalyticsPolicy + Gate::define + HandleInertiaRequests | DONE |
| 11   | AnalyticsController (index, reports, data, exportAttendance) | DONE |
| 12   | Routes + feature tests (8 tests) | DONE |
| 13   | AttendanceRecapExport + ClassAttendanceSheet + 3 export tests | DONE |
| 14   | Full regression: 316/316 pass | DONE |

---

## Tests Added: 24

| File | Tests | Layer |
|------|-------|-------|
| AnalyticsIndexesTest.php | 3 | Unit |
| AnalyticsServiceTest.php | 10 | Unit |
| AnalyticsControllerTest.php | 8 | Feature |
| AttendanceExportTest.php | 3 | Feature |

---

## BLOCK/WARN Fixes Verified

| Item | Fix | Status |
|------|-----|--------|
| BLOCK-1 | `attendanceTrend()` uses 3-way `match($conn)` with explicit `pgsql => TO_CHAR(date, 'IYYY-IW')` | VERIFIED |
| BLOCK-2 | `teacherWorkload` removed from `index()`, added to `reports()` as server-side prop + `/analytics/data/teacher-workload` endpoint | VERIFIED |
| WARN-1 | `classAvgComparison()` and `atRiskStudents()` return `meta.note` + `meta.empty_reason: 'no_published_report_cards'` when empty | VERIFIED |
| WARN-2 | `at_risk_attendance_threshold` and `at_risk_grade_kktp` added to `config/floz.php` + `.env.example`; read via `config()` in service | VERIFIED |
| WARN-3 | 3 empty-state tests added: `classAvgComparison_empty`, `atRiskStudents_empty`, `attendanceTrend_empty` | VERIFIED |
| WARN-4 | `Gate::define('view-analytics', ...)` used (not invalid `Gate::policy(User::class.'@analytics', ...)`) | VERIFIED |

---

## Key Files Created

- `src/app/Services/AnalyticsService.php` — 7 widget methods
- `src/app/Http/Controllers/AnalyticsController.php` — 4 actions
- `src/app/Policies/AnalyticsPolicy.php` — view gate
- `src/app/Exports/AttendanceRecapExport.php` — WithMultipleSheets
- `src/app/Exports/Sheets/ClassAttendanceSheet.php` — per-class sheet
- `src/database/migrations/2026_05_09_000000_add_analytics_indexes.php` — 5 indexes
- `src/tests/Unit/Services/AnalyticsServiceTest.php` — 10 unit tests
- `src/tests/Feature/AnalyticsControllerTest.php` — 8 feature tests
- `src/tests/Feature/AttendanceExportTest.php` — 3 export tests
- `src/tests/Unit/AnalyticsIndexesTest.php` — 3 index existence tests

## Key Files Modified

- `src/config/floz.php` — added `analytics` config block + `kktp_default`
- `src/.env.example` — added analytics env vars
- `src/app/Providers/AppServiceProvider.php` — Gate::define('view-analytics')
- `src/app/Http/Middleware/HandleInertiaRequests.php` — view_analytics permission
- `src/routes/web.php` — 4 analytics routes

---

## Deviations

1. **[Rule 1 - Bug] todaysAttendance percentage** — Plan test expected `33.0` (1/3 * 100), actual round is `33.3`. Fixed test to expect `33.3` (mathematically correct).

2. **[Rule 1 - Bug] Attendance factory unique constraint** — Factory defaults `meeting_number: 1`. `attendanceTrend` test needed 2 records for same student. Fixed by specifying distinct `meeting_number` values (1, 2) in test.

3. **[Rule 1 - Bug] Excel assertDownloaded** — maatwebsite/excel v3 `assertDownloaded` takes a string filename, not a closure. Fixed test to construct the exact expected filename (using `config('app.school_name', 'Sekolah')`).

4. **[Rule 2 - Missing] ROUND cast for pgsql** — PostgreSQL's `ROUND(AVG(...))` returns `numeric`, not `float`. Added `::numeric` cast in `classAvgComparison` SQL to ensure correct type handling.

---

## Architecture Notes

- `AnalyticsService` reads from `report_cards` (pre-aggregated) — no re-aggregation of raw grades
- `attendanceTrend` uses `DB::connection()->getDriverName()` (not `config('database.default')`) for accurate driver detection
- `atRiskStudents` reads `attendance_threshold` from `config('floz.analytics.at_risk_attendance_threshold')` as a float (0.85), not int (85)
- Excel export: N+1 per student is acceptable at SD scale (~30 students/class); documented in Risk Register

---

## Self-Check

- [x] Migration applied: `php artisan migrate --force` returned DONE
- [x] 24 new tests added, all passing
- [x] 316/316 total tests pass (no regressions)
- [x] All BLOCK + WARN fixes implemented and tested
- [x] Frontend scope (Wave 4) excluded per task definition
