# AcademicYear + Semester CRUD — Completion Report

**Date:** 2026-05-08
**Branch:** chore/remove-tenant-leftovers

---

## Tasks Completed

| # | Task | Status | Commit |
|---|------|--------|--------|
| 0 | Factory updates (AcademicYear + Semester) | Done | 1271fdc |
| 1 | AcademicYear backend: controller, policy, requests, routes, tests | Done | c087e91 |
| 2 | Semester backend: controller, policy, requests, routes, tests | Done | 43818e2 |
| 3 | AcademicYears Vue pages (Index.vue + Form.vue) | Done | ef0a8b7 |
| 4 | Semesters Vue pages (Index.vue + Form.vue) | Done | ef0a8b7 |
| 5 | AppLayout nav item + manage_academic_years permission | Done | ef0a8b7 |

---

## Test Results

- **AcademicYearTest.php:** 14 tests, 14 passed (42 assertions)
- **SemesterTest.php:** 10 tests, 10 passed (34 assertions)
- **Full regression:** 240 tests, 240 passed (1046 assertions)

---

## Commits

1. `c087e91` feat(academic-years): admin CRUD with activate flow and TDD tests
2. `43818e2` feat(semesters): admin CRUD with activate flow and TDD tests
3. `ef0a8b7` feat(web/academic-years): AcademicYears + Semesters Vue pages and nav item
4. `1271fdc` test(factories): improve AcademicYear + Semester factories for test isolation

---

## Files Created

**Backend:**
- `src/app/Http/Controllers/AcademicYearController.php`
- `src/app/Http/Controllers/SemesterController.php`
- `src/app/Policies/AcademicYearPolicy.php`
- `src/app/Policies/SemesterPolicy.php`
- `src/app/Http/Requests/StoreAcademicYearRequest.php`
- `src/app/Http/Requests/UpdateAcademicYearRequest.php`
- `src/app/Http/Requests/StoreSemesterRequest.php`
- `src/app/Http/Requests/UpdateSemesterRequest.php`
- `src/tests/Feature/AcademicYearTest.php`
- `src/tests/Feature/SemesterTest.php`

**Frontend:**
- `src/resources/js/Pages/AcademicYears/Index.vue`
- `src/resources/js/Pages/AcademicYears/Form.vue`
- `src/resources/js/Pages/Semesters/Index.vue`
- `src/resources/js/Pages/Semesters/Form.vue`

**Modified:**
- `src/routes/web.php` — academic-years resource + activate, semesters shallow resource + activate
- `src/app/Http/Middleware/HandleInertiaRequests.php` — manage_academic_years permission
- `src/app/Providers/AppServiceProvider.php` — Gate::policy for AcademicYear + Semester
- `src/resources/js/Layouts/AppLayout.vue` — Tahun Ajaran nav item + academic-years icon
- `src/database/factories/AcademicYearFactory.php` — unique names, is_active false
- `src/database/factories/SemesterFactory.php` — random dates, is_active false

---

## Deviations

1. **Route param mismatch (Rule 1 - Bug):** Laravel resource routes use snake_case `{academic_year}` for multi-word model names, not camelCase `{academicYear}`. Fixed `authorizeResource` param, `UpdateAcademicYearRequest::authorize()`, and `StoreSemesterRequest::rules()` accordingly.

2. **AcademicYear delete guard (Rule 2 deviation from plan):** Plan mentioned catching `QueryException` (FK violation), but the classes table uses `onDelete('cascade')`, meaning AY delete would cascade-delete all classes without throwing a FK error. Switched to proactive `classes()->exists()` check before deletion, returning 422 before any data is touched.

3. **AcademicYear factory uniqueness:** Original factory had a fixed name `'2026/2027 - Ganjil'`. Replaced with `faker->unique()->numberBetween(2020, 2099)` to prevent unique constraint failures in tests.

4. **Semester index test:** Test accidentally created 2 semesters with `semester_number => 1` (violating DB unique constraint). Fixed to explicitly use semester_number 1 and 2.

---

## Regression Status

All 240 existing tests pass. No regressions.
