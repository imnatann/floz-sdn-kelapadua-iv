---
phase: 12
plan: backend
subsystem: analytics
tags: [analytics, scoping, teacher, policy, tdd]
dependency_graph:
  requires: [phase11_backend]
  provides: [teacher-scoped-analytics]
  affects: [AnalyticsService, AnalyticsPolicy, AnalyticsController, AttendanceRecapExport, routes/web.php, HandleInertiaRequests]
tech_stack:
  added: []
  patterns: [scope-parameter, fail-closed-authorization, union-of-homeroom-and-ta]
key_files:
  created:
    - src/tests/Unit/Services/AnalyticsServiceScopeTest.php
    - src/tests/Unit/Policies/AnalyticsPolicyTest.php
    - src/tests/Feature/Analytics/TeacherAnalyticsIsolationTest.php
  modified:
    - src/app/Services/AnalyticsService.php
    - src/app/Policies/AnalyticsPolicy.php
    - src/app/Providers/AppServiceProvider.php
    - src/app/Http/Middleware/HandleInertiaRequests.php
    - src/app/Http/Controllers/AnalyticsController.php
    - src/app/Exports/AttendanceRecapExport.php
    - src/routes/web.php
decisions:
  - visibleClassIds returns [] for user with no Teacher record (fail closed)
  - Gate::define used for view-analytics and viewWidget (model-less gates)
  - ?User $scope = null preserves full backwards compat for all existing admin callers
  - Route middleware widened to role:school_admin,teacher; authorization delegated to policy
metrics:
  duration: ~18 minutes
  completed: 2026-05-09
  tasks_completed: 15
  files_changed: 10
---

# Phase 12 Backend: Teacher Per-Class Analytics Scope — Summary

One-liner: Teacher-scoped analytics with visibleClassIds union helper, TDD-green for all 7 widgets, fail-closed policy, and 37 new tests (361 total).

## What Was Built

### Wave 1: Service Refactor (TDD)

Added `private visibleClassIds(User $scope): array` helper to `AnalyticsService`. Returns the union of homeroom class IDs and teaching-assignment class IDs. Returns `[]` if `$user->teacher` is null (fail closed, per critical reminder).

All 7 widget methods gained `?User $scope = null`:
- **W1 `todaysAttendance`**: whereIn class_id when scoped; empty state with `note` for zero scope
- **W2 `classesMissingAttendance`**: throws `AuthorizationException` for non-admin scope
- **W3 `classAvgComparison`**: whereIn class_id; empty state with `no_assigned_classes`
- **W4 `subjectGradeDistribution`**: validates classId in visible IDs or returns `access_denied`
- **W5 `attendanceTrend`**: same access-check pattern as W4
- **W6 `atRiskStudents`**: whereIn class_id; empty state with `no_assigned_classes`
- **W7 `teacherWorkload`**: throws `AuthorizationException` for non-admin scope

### Wave 2: Policy + Permissions

`AnalyticsPolicy::view()` now allows admin OR teacher with homeroom/TA. Teachers with no Teacher record return false (fail closed).

`AnalyticsPolicy::viewWidget()` returns false for teachers on `classes-missing-attendance` and `teacher-workload`.

`AppServiceProvider` registers both `view-analytics` and `viewWidget` gates via `Gate::define`.

`HandleInertiaRequests` replaces `view_analytics` with `manage_analytics` (admin) + `view_own_class_analytics` (teacher with scope).

`routes/web.php` analytics middleware widened from `role:school_admin` to `role:school_admin,teacher`.

### Wave 3: Controller Refactor

`AnalyticsController` passes `Auth::user()` to all service calls. Admin-only widgets (`missingAttendance`, `teacherWorkload`) return `null` for teachers in page props. `data()` applies `Gate::allows('viewWidget', $widget)` before dispatch. `exportAttendance()` passes user to `AttendanceRecapExport`.

`AttendanceRecapExport` accepts `?User $scope`; filters sheets to visible classes when scoped.

### Wave 5: Isolation Tests

6 feature tests in `tests/Feature/Analytics/TeacherAnalyticsIsolationTest.php` proving:
- Teacher A cannot see Teacher B's class data
- Regular teacher gets `access_denied` for unowned class attendance-trend
- Orphan teacher (no Teacher record) gets 403
- Teacher with both homeroom and TA sees union of both classes
- Admin regression: sees all classes unfiltered
- Teacher blocked from `teacher-workload` widget (403)

## Test Results

| Suite | File | Tests |
|-------|------|-------|
| Unit — service scope | AnalyticsServiceScopeTest.php | 22 |
| Unit — policy | AnalyticsPolicyTest.php | 9 |
| Feature — isolation | TeacherAnalyticsIsolationTest.php | 6 |
| **New total** | | **37** |
| **Regression** | all suites | **361 passed** (was 324) |

## Commits

| Hash | Message |
|------|---------|
| 561f18f | test(analytics/scope): add failing scope tests for all 7 widget methods |
| 3c35739 | feat(analytics/scope): add visibleClassIds helper + scope all 7 widget methods |
| 5e9216e | test(analytics/scope): add RED policy tests for AnalyticsPolicy view + viewWidget |
| f6b3891 | feat(analytics/scope): refactor policy, permissions, and route middleware |
| 29ad791 | feat(analytics/scope): controller passes Auth::user() to all service calls |
| bf155e5 | test(analytics/scope): add 6 teacher isolation feature tests |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Pest subdirectory test case conflict**
- **Found during:** Wave 5 isolation tests
- **Issue:** `tests/Feature/Analytics/` subfolder with explicit `uses(Tests\TestCase::class)` conflicted with Pest.php's `->in('Feature')` extension
- **Fix:** Removed `Tests\TestCase::class` from `uses()` in isolation test; Pest.php inheritance applies automatically
- **Files modified:** TeacherAnalyticsIsolationTest.php

**2. [Rule 2 - Missing guard] Controller `index()` had no isAdmin check before calling classesMissingAttendance**
- **Found during:** Wave 3 refactor
- **Issue:** Plan said omit W2 for teachers — controller had no guard
- **Fix:** `$user->isSchoolAdmin() ? $this->analytics->classesMissingAttendance() : null`

**3. [Rule 1 - Bug] Existing AnalyticsControllerTest "teacher cannot access" test**
- **Found during:** Wave 2 regression
- **Analysis:** Test creates orphan teacher (no Teacher record) — correctly gets 403 from policy::view(). Test behavior preserved; no fix needed. Documented to confirm intentional.

## Known Stubs

None.

## Self-Check

- [x] AnalyticsServiceScopeTest.php exists and has 22 tests
- [x] AnalyticsPolicyTest.php exists and has 9 tests
- [x] TeacherAnalyticsIsolationTest.php exists and has 6 tests
- [x] All 6 commits exist in git log
- [x] Full regression: 361 passed (was 324, +37 new)
- [x] Admin regression tests in AnalyticsControllerTest.php all still pass

## Self-Check: PASSED
