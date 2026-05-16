# Plan: Phase 12 — Teacher Per-Class Analytics Scope

## Goal

Extend the existing `/analytics` dashboard to teachers so that wali kelas see their
full kelas data and regular teachers see only their teaching-assignment subjects, while
all admin-only widgets remain invisible to teachers. Backend service scoping enforces
data isolation; frontend gating hides irrelevant controls.

---

## Locked Decisions

| # | Decision |
|---|----------|
| D-01 | Reuse `/analytics` and `/analytics/reports` — no new routes |
| D-02 | Wali kelas: full kelas (attendance + grades + at-risk + trend). Regular teacher: grade distribution + at-risk for their TAs only, no class-wide attendance. Union applies when teacher holds both roles. |
| D-03 | `AnalyticsPolicy::view` returns true for admin OR teacher with ≥ 1 owned scope. Add `viewWidget(User, string): bool` — W2 (`classesMissingAttendance`) and W7 (`teacherWorkload`) are admin-only. |
| D-04 | Every service method gains `?User $scope = null`. Non-null non-admin scope builds `visibleClassIds` union of homeroom class IDs + TA class IDs. |
| D-05 | `teacherWorkload()` and `classesMissingAttendance()` throw `AuthorizationException` when called with non-admin scope. |
| D-06 | Add `view_own_class_analytics` permission (true for any teacher). Keep `manage_analytics` (admin). Nav shows "Analitik" if either is true. |
| D-07 | Frontend: Dashboard.vue hides W2 and admin stat-cards behind `manage_analytics`; Reports.vue hides W7 for non-admin. All other widgets render — backend filters. |
| D-08 | Excel export accepts same User scope; filename unchanged, content scoped. |

---

## Source Audit

| Source | Item | Covered by |
|--------|------|------------|
| GOAL | Teacher-scoped analytics | Wave 1–4 (all tasks) |
| D-01 | Reuse routes | Task 11 |
| D-02 | Two-role visibility rules | Tasks 1–7 |
| D-03 | Policy refactor | Tasks 9–10 |
| D-04 | Service `?User $scope` | Tasks 1–7 |
| D-05 | Admin-only widget guard | Tasks 5, 7, 13 |
| D-06 | Permission key | Task 10 |
| D-07 | Frontend gating | Tasks 15–17 |
| D-08 | Scoped export | Task 14 |

---

## Architecture Notes

**`visibleClassIds` computation (reused across all widget methods):**

```php
// In AnalyticsService — extract to private helper
private function visibleClassIds(User $scope): array
{
    $teacher = $scope->teacher; // hasOne via email

    if (! $teacher) {
        return [];
    }

    $homeroom = SchoolClass::where('homeroom_teacher_id', $teacher->id)
        ->pluck('id');                                    // table: classes

    $taught = TeachingAssignment::where('teacher_id', $teacher->id)
        ->pluck('class_id');

    return $homeroom->merge($taught)->unique()->values()->all();
}
```

**Key model linkage:** `User —hasOne→ Teacher` via `email` field (confirmed in User.php line 59).
`SchoolClass` uses table `classes` (confirmed — do NOT use `school_classes` anywhere).

**Policy gate helper in controller:**
```php
// AnalyticsController::data() — before match()
Gate::authorize('viewWidget', [Analytics::class, $widget]);
// or: $this->authorize('viewWidget', [Analytics::class, $widget]);
```

---

## Wave 1: Service Refactor (TDD)

### Task 1 — Extract `visibleClassIds` helper + refactor `todaysAttendance`

**Files:**
- `src/app/Services/AnalyticsService.php`
- `src/tests/Unit/AnalyticsServiceScopeTest.php` (create)

**TDD behavior:**
```php
// Case 1: null scope (admin) — returns school-wide totals
it('todaysAttendance returns all classes when scope is null', ...)

// Case 2: wali kelas — returns only their class attendance
it('todaysAttendance filters to homeroom class when wali kelas scope given', ...)

// Case 3: regular teacher (no homeroom) — returns only TA classes attendance
it('todaysAttendance filters to TA classes when regular teacher scope given', ...)

// Case 4: teacher with no scope at all — returns empty data with meta.note
it('todaysAttendance returns empty state for teacher with no homeroom and no TAs', ...)
```

**Action (per D-04):**
1. Add `use App\Models\TeachingAssignment;` and `use App\Auth\AuthorizationException;` imports.
2. Add `private function visibleClassIds(User $scope): array` — homeroom pluck union TA pluck (unique, values).
3. Refactor `todaysAttendance(): array` → `todaysAttendance(?User $scope = null): array`.
4. When `$scope` non-null and not `isSchoolAdmin()`: add `->whereIn('class_id', $this->visibleClassIds($scope))` to the DB query. If `visibleClassIds` returns `[]`, skip DB and return `['data' => [...zeros...], 'meta' => ['note' => 'Tidak ada kelas yang dikelola.']]`.

**Verify:** `php artisan test --filter=AnalyticsServiceScopeTest::todaysAttendance` — 4 pass, 0 fail.

**Done:** `todaysAttendance` returns scoped attendance; helper tested in isolation.

---

### Task 2 — Refactor `classesMissingAttendance` + `teacherWorkload` (admin-only guard)

**Files:**
- `src/app/Services/AnalyticsService.php`
- `src/tests/Unit/AnalyticsServiceScopeTest.php`

**TDD behavior:**
```php
// W2
it('classesMissingAttendance with admin scope (null) returns school-wide missing list', ...)
it('classesMissingAttendance throws AuthorizationException when called with teacher scope', ...)

// W7
it('teacherWorkload with admin scope (null) returns all teachers', ...)
it('teacherWorkload throws AuthorizationException when called with teacher scope', ...)
```

**Action (per D-05):**
- `classesMissingAttendance(?User $scope = null)`: if `$scope && ! $scope->isSchoolAdmin()` → `throw new \Illuminate\Auth\Access\AuthorizationException('Widget ini hanya tersedia untuk admin.')`.
- `teacherWorkload(int $academicYearId, ?User $scope = null)`: same guard — throw on non-admin scope.
- Admin null/admin-user path: unchanged behavior.

**Verify:** `php artisan test --filter=AnalyticsServiceScopeTest` — W2 and W7 tests pass.

**Done:** Admin-only widgets throw `AuthorizationException` on teacher scope.

---

### Task 3 — Refactor `classAvgComparison`

**Files:**
- `src/app/Services/AnalyticsService.php`
- `src/tests/Unit/AnalyticsServiceScopeTest.php`

**TDD behavior:**
```php
it('classAvgComparison returns all classes when scope is null', ...)
it('classAvgComparison returns only homeroom class for wali kelas', ...)
it('classAvgComparison returns union of TA classes for regular teacher', ...)
it('classAvgComparison returns empty with note for teacher with zero scope', ...)
```

**Action (per D-04):**
- Signature: `classAvgComparison(int $semesterId, ?User $scope = null): array`
- When scoped: add `->whereIn('report_cards.class_id', $this->visibleClassIds($scope))` after the `semester_id` where clause.
- Empty `visibleClassIds` → return existing WARN-1 empty structure with `empty_reason = 'no_assigned_classes'`.

**Verify:** `php artisan test --filter=AnalyticsServiceScopeTest::classAvgComparison` — 4 pass.

**Done:** W3 returns only classes in the teacher's visible scope.

---

### Task 4 — Refactor `subjectGradeDistribution` + `attendanceTrend`

**Files:**
- `src/app/Services/AnalyticsService.php`
- `src/tests/Unit/AnalyticsServiceScopeTest.php`

**TDD behavior:**
```php
// W4
it('subjectGradeDistribution with admin returns full class data', ...)
it('subjectGradeDistribution with wali kelas allows their class', ...)
it('subjectGradeDistribution with regular teacher blocks class not in TA', ...)
// teacher requests classId not in their scope → return empty + meta.note = 'Anda tidak memiliki akses ke kelas ini.'

// W5
it('attendanceTrend with admin returns data for any class', ...)
it('attendanceTrend with wali kelas returns their class trend', ...)
it('attendanceTrend with regular teacher blocks class not in TA scope', ...)
```

**Action (per D-04):**
- `subjectGradeDistribution(int $classId, int $semesterId, ?User $scope = null)`:
  - When scoped: validate `$classId` is in `visibleClassIds` → if not, return `['data' => [], 'meta' => ['note' => 'Anda tidak memiliki akses ke kelas ini.', 'empty_reason' => 'access_denied']]`.
  - No WHERE modification needed (classId is the filter itself).
- `attendanceTrend(int $classId, int $semesterId, int $weeks = 12, ?User $scope = null)`:
  - Same access-check pattern as W4.

**Verify:** `php artisan test --filter=AnalyticsServiceScopeTest` — all W4/W5 cases pass.

**Done:** Per-class widgets validate classId is in teacher's scope.

---

### Task 5 — Refactor `atRiskStudents`

**Files:**
- `src/app/Services/AnalyticsService.php`
- `src/tests/Unit/AnalyticsServiceScopeTest.php`

**TDD behavior:**
```php
it('atRiskStudents with admin returns school-wide at-risk list', ...)
it('atRiskStudents with wali kelas returns only their class students', ...)
it('atRiskStudents with regular teacher returns only TA-class students', ...)
it('atRiskStudents with zero-scope teacher returns empty with note', ...)
```

**Action (per D-04):**
- `atRiskStudents(int $semesterId, ?float $kktp = null, ?User $scope = null)`:
  - When scoped and non-admin: add `->whereIn('report_cards.class_id', $this->visibleClassIds($scope))`.
  - Empty `visibleClassIds` → skip DB, return WARN-1 empty structure with `empty_reason = 'no_assigned_classes'`.

**Verify:** `php artisan test --filter=AnalyticsServiceScopeTest::atRiskStudents` — 4 pass.

**Done:** W6 at-risk list scoped to teacher's visible classes.

---

## Wave 2: Policy + Permissions

### Task 6 — `AnalyticsPolicy` refactor

**Files:**
- `src/app/Policies/AnalyticsPolicy.php`

**Action (per D-03):**

```php
<?php

namespace App\Policies;

use App\Models\SchoolClass;
use App\Models\TeachingAssignment;
use App\Models\User;

class AnalyticsPolicy
{
    /** Any user with at least 1 owned scope can view analytics. */
    public function view(User $user): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        if (! $user->isTeacher()) {
            return false;
        }

        $teacher = $user->teacher;

        if (! $teacher) {
            return false;
        }

        $hasHomeroom = SchoolClass::where('homeroom_teacher_id', $teacher->id)->exists();
        $hasTA       = TeachingAssignment::where('teacher_id', $teacher->id)->exists();

        return $hasHomeroom || $hasTA;
    }

    /**
     * Widget-level gate — admin-only widgets: classesMissingAttendance, teacherWorkload.
     *
     * @param  User    $user
     * @param  string  $widget  Widget key (kebab-case, matches route param)
     */
    public function viewWidget(User $user, string $widget): bool
    {
        $adminOnly = ['classes-missing-attendance', 'teacher-workload'];

        if (in_array($widget, $adminOnly, true)) {
            return $user->isSchoolAdmin();
        }

        return true; // other widgets gated only by view()
    }
}
```

**Verify:** `php artisan test --filter=AnalyticsPolicyTest` (create alongside — see Task 15 for test file).

**Done:** Policy permits teacher access; admin-only widgets return false for teachers.

---

### Task 7 — HandleInertiaRequests: add `view_own_class_analytics` + update nav permission

**Files:**
- `src/app/Http/Middleware/HandleInertiaRequests.php`

**Action (per D-06):**

In the `'permissions'` closure, add after `'view_analytics'` line:

```php
'manage_analytics'           => $user->isSchoolAdmin(),
'view_own_class_analytics'   => $user->isTeacher() && $user->teacher !== null
                                    && (
                                        \App\Models\SchoolClass::where('homeroom_teacher_id', $user->teacher->id)->exists()
                                        || \App\Models\TeachingAssignment::where('teacher_id', $user->teacher->id)->exists()
                                    ),
```

Remove the old `'view_analytics'` key — it is superseded by `manage_analytics`.

Note: the `$user->load(['student:id,email', 'teacher:id,email'])` eager load on line 38 already loads teacher, so `$user->teacher` is available without N+1 within the same request.

**Verify:** Log in as teacher with TA → `$page.props.permissions.view_own_class_analytics` is true in Vue DevTools. Admin → `manage_analytics` true, `view_own_class_analytics` false.

**Done:** Both permission keys emitted to frontend correctly.

---

### Task 8 — Update analytics route middleware (per D-01, D-08)

**Files:**
- `src/routes/web.php`

**Action (per D-01):**

Change line 144:
```php
// Before
Route::prefix('analytics')->middleware(['role:school_admin'])->name('analytics.')->group(...)

// After
Route::prefix('analytics')->middleware(['role:school_admin,teacher'])->name('analytics.')->group(...)
```

Authorization is now handled by `AnalyticsPolicy::view` in each controller method (see Wave 3).

**Verify:** Teacher hits `/analytics` — gets 200 (Inertia page), not 403. Unauthenticated user → redirected to login. Student → 403.

**Done:** Route permits teacher role; policy enforces per-user scope.

---

## Wave 3: Controller Refactor

### Task 9 — `AnalyticsController::index` + `reports` pass `Auth::user()`

**Files:**
- `src/app/Http/Controllers/AnalyticsController.php`

**Action (per D-04):**

Add `use Illuminate\Support\Facades\Auth;` import.

Refactor `index()`:
```php
public function index(): Response
{
    $this->authorize('view', \App\Models\Analytics::class);
    // Note: Laravel resolves 'view-analytics' gate or use direct policy:
    // Gate::authorize('view', new \App\Policies\AnalyticsPolicy);

    $user     = Auth::user();
    $semester = Semester::where('is_active', true)->firstOrFail();
    $ay       = $semester->academicYear;

    return Inertia::render('Analytics/Dashboard', [
        'todaysAttendance'        => $this->analytics->todaysAttendance($user),
        'missingAttendance'       => $user->isSchoolAdmin()
                                        ? $this->analytics->classesMissingAttendance()
                                        : null,
        'classAvgComparison'      => $this->analytics->classAvgComparison($semester->id, $user),
        'activeSemester'          => $semester,
        'isAdmin'                 => $user->isSchoolAdmin(),
    ]);
}
```

Refactor `reports()`:
```php
public function reports(): Response
{
    $this->authorize('view', \App\Models\Analytics::class);

    $user     = Auth::user();
    $semester = Semester::where('is_active', true)->firstOrFail();
    $ay       = $semester->academicYear;

    // Scope classes dropdown to teacher's visible classes
    $classQuery = SchoolClass::where('academic_year_id', $ay->id)->orderBy('name');
    if (! $user->isSchoolAdmin() && $user->teacher) {
        $teacher   = $user->teacher;
        $homeroom  = SchoolClass::where('homeroom_teacher_id', $teacher->id)->pluck('id');
        $taught    = \App\Models\TeachingAssignment::where('teacher_id', $teacher->id)->pluck('class_id');
        $visible   = $homeroom->merge($taught)->unique()->values()->all();
        $classQuery->whereIn('id', $visible);
    }

    return Inertia::render('Analytics/Reports', [
        'activeSemester'  => $semester,
        'teacherWorkload' => $user->isSchoolAdmin()
                                ? $this->analytics->teacherWorkload($ay->id)
                                : null,
        'classes'         => $classQuery->get(['id', 'name']),
        'isAdmin'         => $user->isSchoolAdmin(),
    ]);
}
```

**Verify:** Admin sees full classes list; teacher sees only their scoped classes.

**Done:** Both page controllers pass user scope and omit admin-only data for teachers.

---

### Task 10 — `AnalyticsController::data` — widget guard + scoped dispatch

**Files:**
- `src/app/Http/Controllers/AnalyticsController.php`

**Action (per D-03, D-04, D-05):**

Refactor `data()`:
```php
public function data(Request $request, string $widget): JsonResponse
{
    $this->authorize('view', \App\Models\Analytics::class);

    // Widget-level gate (admin-only widgets)
    if (! Gate::allows('viewWidget', [\App\Policies\AnalyticsPolicy::class, $widget])) {
        abort(403, "Widget {$widget} is restricted to administrators.");
    }

    $user       = Auth::user();
    $semesterId = (int) $request->input(
        'semester_id',
        Semester::where('is_active', true)->value('id')
    );
    $classId = (int) $request->input('class_id', 0);

    $result = match ($widget) {
        'subject-grade-distribution' => $this->analytics->subjectGradeDistribution($classId, $semesterId, $user),
        'attendance-trend'           => $this->analytics->attendanceTrend($classId, $semesterId, 12, $user),
        'at-risk-students'           => $this->analytics->atRiskStudents($semesterId, null, $user),
        'teacher-workload'           => $this->analytics->teacherWorkload(
                                           Semester::findOrFail($semesterId)->academicYear->id,
                                           $user
                                       ),
        default => abort(404, "Widget {$widget} not found"),
    };

    return response()->json($result);
}
```

Note: `Gate::allows('viewWidget', [$policy, $widget])` requires the policy method be registered. Alternatively inline the check:
```php
abort_unless($user->isSchoolAdmin() || ! in_array($widget, ['teacher-workload', 'classes-missing-attendance']), 403);
```

Use whichever the project's Gate registration pattern supports.

**Verify:** Teacher requests `/analytics/data/teacher-workload` → 403. Teacher requests `/analytics/data/at-risk-students` → 200 (scoped).

**Done:** Widget endpoint applies both role gate and user scope.

---

### Task 11 — Scoped Excel export (per D-08)

**Files:**
- `src/app/Http/Controllers/AnalyticsController.php`
- `src/app/Exports/AttendanceRecapExport.php`

**Action (per D-08):**

Refactor `exportAttendance()`:
```php
public function exportAttendance(Request $request)
{
    $this->authorize('view', \App\Models\Analytics::class);
    $request->validate(['semester_id' => 'required|integer|exists:semesters,id']);

    $user     = Auth::user();
    $semester = Semester::with('academicYear')->findOrFail($request->semester_id);
    $schoolName = config('app.school_name', 'Sekolah');
    $filename = "Rekap_Absensi_{$schoolName}_{$semester->academicYear->name}_Sem{$semester->semester_number}_" . now()->format('Ymd') . '.xlsx';

    return \Maatwebsite\Excel\Facades\Excel::download(
        new \App\Exports\AttendanceRecapExport($semester->id, $user),
        $filename
    );
}
```

Update `AttendanceRecapExport` constructor:
```php
public function __construct(
    private readonly int $semesterId,
    private readonly ?User $scope = null,
) {}
```

In the export's query method, when `$this->scope` is non-null and not admin:
```php
->whereIn('class_id', $this->visibleClassIds($this->scope))
```

Extract `visibleClassIds` to a shared trait or duplicate the logic (acceptable given it's 6 lines).

**Verify:** Teacher downloads export → file contains only their class rows. Admin → full school data.

**Done:** Export honors teacher scope; filename unchanged.

---

## Wave 4: Frontend Gating

### Task 12 — AppLayout nav — show "Analitik" for either permission (per D-06)

**Files:**
- `src/resources/js/Layouts/AppLayout.vue` (or wherever nav links are defined)

**Action (per D-06):**

Find the nav item for "Analitik". Change condition from:
```js
// Before
v-if="$page.props.permissions.view_analytics"

// After
v-if="$page.props.permissions.manage_analytics || $page.props.permissions.view_own_class_analytics"
```

If using a computed `canViewAnalytics`:
```js
const canViewAnalytics = computed(() =>
  page.props.permissions.manage_analytics || page.props.permissions.view_own_class_analytics
);
```

**Verify:** Log in as teacher with TA → "Analitik" visible in nav. Log in as student → not visible.

**Done:** Nav shows analytics link to both admin and scoped teachers.

---

### Task 13 — Dashboard.vue conditional widget rendering (per D-07)

**Files:**
- `src/resources/js/Pages/Analytics/Dashboard.vue`

**Action (per D-07):**

Add `usePage` import:
```js
import { usePage } from '@inertiajs/vue3';
const page = usePage();
const isAdmin = computed(() => page.props.permissions.manage_analytics);
```

Update props — add `isAdmin`:
```js
const props = defineProps({
  todaysAttendance:         { type: Object, default: () => null },
  classAvgComparison:       { type: Object, default: () => null },
  missingAttendance:        { type: Array,  default: () => null },  // null = not sent
  activeSemester:           { type: Object, default: () => null },
  isAdmin:                  { type: Boolean, default: false },
});
```

In template:
- W1 (Today's Attendance): visible to all (always show — scoped by backend).
- W2 (Classes Missing Attendance): wrap in `v-if="isAdmin"` — `missingAttendance` will be null for teachers anyway, but gate visually.
- W3 (Class Avg Comparison): visible to all.
- Summary stat-cards that reference school-wide numbers: wrap in `v-if="isAdmin"`.

Add "Kelas Saya" label for teachers when `!isAdmin` and `classAvgComparison.data.length === 1`:
```html
<p v-if="!isAdmin && classAvgComparison?.data?.length" class="text-sm text-slate-500 mt-1">
  Menampilkan data kelas Anda
</p>
```

**Verify:** Log in as wali kelas → W2 card absent, W1/W3 present with their class data. Admin → all widgets visible.

**Done:** Dashboard conditionally renders admin-only widgets; teacher sees their scoped data.

---

### Task 14 — Reports.vue — hide W7 + scope class dropdown (per D-07)

**Files:**
- `src/resources/js/Pages/Analytics/Reports.vue`

**Action (per D-07):**

Add:
```js
import { usePage } from '@inertiajs/vue3';
const page = usePage();
const isAdmin = computed(() => page.props.permissions.manage_analytics);
```

Update props — add `isAdmin` and handle null `teacherWorkload`:
```js
const props = defineProps({
  classes:         { type: Array,  default: () => [] },
  teacherWorkload: { type: Object, default: () => null },  // null for teachers
  activeSemester:  { type: Object, default: () => null },
  isAdmin:         { type: Boolean, default: false },
});
```

In template:
- W7 (Teacher Workload) panel: `v-if="isAdmin"`.
- Class selector: `props.classes` is already pre-filtered server-side; no frontend change needed.
- Add contextual note when `!isAdmin`: "Menampilkan data untuk kelas yang Anda ampu."

**Verify:** Teacher visits `/analytics/reports` → W7 absent. Admin → W7 visible with full teacher list.

**Done:** Reports page hides workload widget; class dropdown already scoped by controller.

---

## Wave 5: Isolation Tests

### Task 15 — Feature tests: teacher isolation + policy tests

**Files:**
- `src/tests/Feature/Analytics/TeacherAnalyticsIsolationTest.php` (create)
- `src/tests/Unit/AnalyticsPolicyTest.php` (create)

**Test cases:**

```php
// TeacherAnalyticsIsolationTest.php

// 1. Teacher A cannot see Teacher B's data
it('teacher A classAvgComparison does not include teacher B class', function () {
    // Create teacherA (wali kelas classA), teacherB (wali kelas classB)
    // Seed report_cards for both classes
    // Act as teacherA user → GET /analytics → classAvgComparison.data
    // Assert: classB not in data, classA is in data
});

// 2. Wali kelas vs regular teacher visibility
it('wali kelas sees attendance trend but regular teacher does not for unowned class', function () {
    // Regular teacher hits GET /analytics/data/attendance-trend?class_id=<unowned>
    // Assert: response data is empty with access_denied note
});

// 3. Teacher with no scope returns clear empty state
it('teacher with no homeroom and no TA gets clear empty state on dashboard', function () {
    // Teacher with zero TAs and not wali kelas
    // GET /analytics → 200 (policy view returns false → redirect or 403?)
    // Actually: policy::view returns false → 403
    // Assert: response status 403
});

// 4. Teacher who is BOTH wali kelas AND has TAs in other classes sees union
it('teacher who is wali kelas and has TA in another class sees both classes', function () {
    // Create teacher as homeroom of classA AND TA for classB
    // GET /analytics → classAvgComparison.data contains both classA and classB
});

// 5. Admin still sees full data (regression)
it('admin sees school-wide data unchanged', function () {
    // Admin GET /analytics → classAvgComparison.data contains all classes
});

// 6. Export scoped to teacher's classes
it('teacher export contains only their class rows', function () {
    // Teacher GET /analytics/export/attendance?semester_id=X
    // Assert: downloaded XLSX contains only their class(es)
});
```

```php
// AnalyticsPolicyTest.php

it('view returns false for teacher with no homeroom and no TA')
it('view returns true for teacher with homeroom')
it('view returns true for teacher with TA')
it('view returns true for admin')
it('viewWidget returns false for teacher requesting classesMissingAttendance')
it('viewWidget returns false for teacher requesting teacherWorkload')
it('viewWidget returns true for teacher requesting at-risk-students')
it('viewWidget returns true for admin requesting any widget')
```

**Verify:** `php artisan test --filter=TeacherAnalyticsIsolationTest` — 6 pass. `php artisan test --filter=AnalyticsPolicyTest` — 8 pass.

**Done:** Data isolation between teachers proven by feature tests; policy logic unit-tested.

---

## Definition of Done

- [ ] `AnalyticsService::visibleClassIds()` private helper returns correct union for wali + TA roles
- [ ] All 7 widget methods accept `?User $scope = null` without breaking existing admin calls
- [ ] `classesMissingAttendance` and `teacherWorkload` throw `AuthorizationException` for non-admin scope
- [ ] `AnalyticsPolicy::view` allows teachers with ≥ 1 owned scope
- [ ] `AnalyticsPolicy::viewWidget` blocks W2/W7 for teachers
- [ ] `manage_analytics` (admin) and `view_own_class_analytics` (teacher) both emitted from middleware
- [ ] Analytics routes accept `role:school_admin,teacher`
- [ ] Controller passes `Auth::user()` to all service calls
- [ ] `missingAttendance` and `teacherWorkload` return null (not fetched) for teachers in controller
- [ ] Classes dropdown in Reports.vue pre-filtered server-side for teachers
- [ ] Dashboard.vue W2 hidden for teachers; teacher sees scoped W1/W3
- [ ] Reports.vue W7 hidden for teachers
- [ ] Nav "Analitik" link visible if either permission is true
- [ ] Excel export scoped to teacher's visible classes
- [ ] Teacher A cannot retrieve Teacher B's data via any endpoint
- [ ] Teacher with zero TAs and no homeroom receives 403 on all analytics routes
- [ ] All existing admin analytics tests still pass (regression)

---

## Test Count Target

| Suite | File | New Tests |
|-------|------|-----------|
| Unit — service scope | `AnalyticsServiceScopeTest.php` | 14 (2 per widget × 7, incl. admin-only guards) |
| Unit — policy | `AnalyticsPolicyTest.php` | 8 |
| Feature — isolation | `TeacherAnalyticsIsolationTest.php` | 6 |
| **Total** | | **~28 new tests** |

---

## Risk Register

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `User::teacher` relation uses `email` FK — teacher record may not exist | Medium | Policy `view()` and service helper both guard `if (! $teacher) return false / []` |
| `visibleClassIds` returns [] for valid teacher with no current-year assignments | Medium | Empty state with `meta.note` avoids blank widget confusion |
| Admin's cache key collision with teacher's scoped data (if caching is added later) | Low | No caching in Phase 11; document: if caching is added, key MUST include user ID |
| `classes` table (not `school_classes`) — wrong table name in raw queries | Low | Confirmed: `SchoolClass::$table = 'classes'`; use Eloquent builder, not raw `FROM school_classes` |
| Union of homeroom + TA produces duplicate class IDs (teacher teaches their own homeroom class) | Low | `->unique()->values()->all()` on Collection prevents duplicates |
| `Gate::allows('viewWidget', ...)` registration — policy must be registered in `AuthServiceProvider` | Medium | Verify `AnalyticsPolicy` is registered; if not, add `'view-widget' => AnalyticsPolicy::class` |

---

## Out of Scope (Phase 13+)

- Student dashboard showing own grades/attendance — Phase 13
- Real-time data refresh via WebSockets
- Mobile teacher analytics screen — Phase 14
- Per-meeting attendance drill-down
- Parent portal analytics (child's data only)
- Cross-semester comparison for teachers
