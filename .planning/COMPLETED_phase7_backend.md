# Phase 7 Backend — School-Year Transition: Execution Summary

**Executor:** claude-sonnet-4-6
**Date:** 2026-05-08
**Duration:** ~1 session
**Scope:** Tasks 1-6 + 12 (backend only; Vue wizard Tasks 7-11 deferred to frontend executor)

---

## Tasks Completed

| Task | Description | Commit | Tests Added |
|------|-------------|--------|-------------|
| 1 | Migration + YearTransitionLog model + YearTransitionLogFactory + StudentMutationFactory | 9a64469 | 3 unit |
| 2 (RED) | previewTransition failing tests | 2c1da01 | 9 unit |
| 2 (GREEN) | previewTransition implementation | 9765570 | — |
| 3 | executeTransition TDD (atomicity + rollback + multi-section) | 6642456 | 6 unit |
| 4 | YearTransitionPolicy + AppServiceProvider gate registration | effb11d | — |
| 5 | PreviewRequest + ExecuteRequest form validation | ef96297 | — |
| 6 | YearTransitionController + routes + feature tests | 985e63f | 11 feature |
| 12 | HandleInertiaRequests manage_year_transition permission | 7192a15 | — |

---

## Test Results

- **Baseline:** 240 tests
- **New tests added:** 29 (3 unit model + 15 unit service + 11 feature)
- **Final count:** 269 tests passing (1143 assertions)
- **Regressions:** 0

---

## BLOCK/WARN Fixes Applied

| Fix | Status | Description |
|-----|--------|-------------|
| BLOCK-1 | Applied | Guard in executeTransition: throws if target AY already has classes |
| BLOCK-2 | Verified | audit_logs.user_id is nullable; AuditLog::create inside transaction rolls back correctly. Added regression test. |
| BLOCK-3 | Applied | previewTransition called INSIDE DB::transaction; Student::lockForUpdate() on all mutated students |
| BLOCK-4 | Applied | preg_replace digit-boundary regex for grade→grade+1 class name; section-letter fallback in applyPromotion |
| BLOCK-5 | Applied | Cache::lock("year_transition_{src}_{tgt}", 120) in executeTransition with finally{} release |
| WARN-1 | Applied | Policy and gate return isSchoolAdmin() || isSuperAdmin() |
| WARN-2 | Applied | plan_snapshot stores $sourceAy->toArray() (plain arrays, not Eloquent models) |
| WARN-5 | Applied | StudentMutationFactory created in Task 1, not Task 12 |
| WARN-6 | Applied | Comment in applyExit() documenting attendance FK behavior |

---

## Architecture Notes for Frontend Executor

### API Contract (tested and working)

**POST /year-transition/preview** — Returns:
```json
{
  "source_ay": { ...array },
  "target_ay": { ...array },
  "new_classes": [{ "source_class_id", "name", "grade_level", "homeroom_teacher_id" }],
  "mutations": [{ "student_id", "student_name", "nis", "from_class_id", "from_class_name", "from_grade_level", "action", "to_class_id", "to_class_name", "reason", "warnings" }],
  "summary": { "promoted", "graduated", "retained", "excluded" }
}
```

**POST /year-transition/execute** — Returns:
```json
{ "log_id": 1, "summary": { "promoted", "graduated", "retained", "excluded" } }
```
Returns 409 when target AY already has classes OR cache lock busy.
Returns 500 for unexpected service exceptions.

### Class Promotion Architecture (IMPORTANT for frontend)

The new-AY classes are mirrors of the source-AY structure (same names, same grade levels). For grade-N students to promote to grade-N+1, the source AY must contain a grade-N+1 class. Example: source AY must have Kelas 5A for grade-4 students to have a promotion destination. The wizard must warn admins if any source grade is missing its promotion destination class.

### Routes Registered

```
GET  /year-transition              → year-transition.index
POST /year-transition/preview      → year-transition.preview
POST /year-transition/execute      → year-transition.execute
GET  /year-transition/logs         → year-transition.logs
GET  /year-transition/logs/{log}   → year-transition.logs.show
```

All require `auth` middleware + `can:manage_year_transition` gate.

### Permissions

`auth.permissions.manage_year_transition` is shared via HandleInertiaRequests — true for school_admin and super_admin.

### Files Created

- `src/database/migrations/2026_05_08_000001_create_year_transition_logs_table.php`
- `src/app/Models/YearTransitionLog.php`
- `src/database/factories/YearTransitionLogFactory.php`
- `src/database/factories/StudentMutationFactory.php`
- `src/app/Services/YearTransitionService.php`
- `src/app/Policies/YearTransitionPolicy.php`
- `src/app/Http/Requests/YearTransition/PreviewRequest.php`
- `src/app/Http/Requests/YearTransition/ExecuteRequest.php`
- `src/app/Http/Controllers/YearTransitionController.php`
- `src/tests/Unit/Models/YearTransitionLogTest.php`
- `src/tests/Unit/Services/YearTransitionServiceTest.php`
- `src/tests/Feature/YearTransition/PreviewTest.php`
- `src/tests/Feature/YearTransition/ExecuteTest.php`

### Files Modified

- `src/app/Models/StudentMutation.php` — added HasFactory trait
- `src/app/Providers/AppServiceProvider.php` — added Gate::define + Gate::policy for YearTransitionLog
- `src/app/Http/Middleware/HandleInertiaRequests.php` — added manage_year_transition permission
- `src/routes/web.php` — registered year-transition route group

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Faker `ipv4()` format not available**
- Found during: Task 1
- Fix: Used `'192.168.1.' . $this->faker->numberBetween(1, 254)`

**2. [Rule 1 - Bug] Unit tests need `uses(Tests\TestCase::class)` not just RefreshDatabase**
- Found during: Task 1 (no app bootstrap in Unit tests without TestCase)
- Fix: Added `uses(Tests\TestCase::class, RefreshDatabase::class)` to all Unit tests

**3. [Rule 1 - Bug] Regex `/\b4\b/` fails for "4A" (word boundary doesn't match between digit and letter)**
- Found during: Task 2 multi-section test
- Fix: Used `preg_replace('/(?<![0-9])4(?![0-9])/', '5', ...)` — negative lookbehind/lookahead

**4. [Rule 1 - Bug] Execute happy-path test missing destination grade class in source AY**
- Found during: Task 6
- Fix: Test setup now creates both source grade AND destination grade classes in source AY (architectural requirement documented in Architecture Notes above)

**5. [Rule 2 - Missing] 409 response for idempotency conflicts**
- Found during: Task 6 controller implementation
- Fix: Controller returns 409 (not 500) for `sudah memiliki kelas` and `sedang berjalan` RuntimeExceptions; separate test added

---

## Known Stubs

None — all backend endpoints are fully wired. Frontend Vue pages (Tasks 7-11) are not implemented in this run.

---

## Blockers for Frontend Executor

1. **Vue pages needed:** `YearTransition/Wizard.vue`, `YearTransition/Logs.vue`, `YearTransition/LogDetail.vue`, and step components `SelectYears.vue`, `ClassStructure.vue`, `StudentReview.vue`, `Preview.vue`, `Confirm.vue`
2. **Nav menu:** AppLayout.vue needs "Kenaikan Kelas" entry (conditionally shown on `permissions.manage_year_transition`)
3. **Architectural note for wizard Step 2:** When building the class structure table, warn admin if any source grade is missing its promotion-destination class (see Architecture Notes above)
4. **Inertia pages for index/logs/logs.show** must exist for those routes to render (currently would fail with view not found)
