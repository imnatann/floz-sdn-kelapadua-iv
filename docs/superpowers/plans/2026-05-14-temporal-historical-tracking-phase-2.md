# Temporal/Historical Tracking — Phase 2 Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Make historical roster actually surface in Tasks/Exams/Attendance pages, enforce activation workflow (no rogue toggles), let admin set per-student status during semester carry-over, and backfill missing data from the pre-deploy year transition.

**Architecture:** Phase 1 added the data layer (`student_class_enrollments`). Phase 2 wires it everywhere the legacy `class->students()` is used (showing wrong "empty" roster after year transition), and gates Semester/Academic Year activation behind the proper workflows. The Carry-Over modal becomes admin's per-student status editor.

**Tech Stack:** Laravel 11, Inertia/Vue 3, MySQL/MariaDB on prod, Pest tests.

**Spec ref:** `docs/superpowers/specs/2026-05-14-temporal-historical-tracking-design.md`
**Phase 1 plan:** `docs/superpowers/plans/2026-05-14-temporal-historical-tracking-phase-1.md`

## Problems Being Fixed

1. **Bug A:** Data Siswa filter by TA (without semester) shows empty when students have been promoted out — falls back to legacy `students.class_id`-based query.
2. **Bug B:** Tugas/Ujian/Absensi pages "Tidak ada siswa di kelas ini" for past classes — student listing uses `class->students()` (current view) instead of enrollment roster (historical view).
3. **Bug C:** Year transition executed before Phase 1 deploy → no enrollments written for target year. One-time backfill needed.
4. **Bug D:** Multi-active semester pollution — `SemesterController::activate` only deactivates within same AY. Globally there should be exactly ONE active semester.
5. **Feature F1:** Carry-over preview should let admin set per-student status (Aktif / Keluar / Lulus / Tinggal kelas) before executing.
6. **Feature F2a:** Remove direct AY "Aktifkan" button — AY activation must go through Year Transition (Kenaikan Kelas) flow.
7. **Feature F2b:** Block Year Transition unless source AY's Sem 2 is currently active.

## Design Decisions (from this session)

| Decision | Choice |
|---|---|
| AY activation gating | Remove "Aktifkan" button on AY list; add "Mulai Kenaikan Kelas" trigger which routes to existing Year Transition flow. |
| Carry-over status UI | Per-row dropdown in the existing CarryOverConfirmModal: Aktif (default) / Keluar / Lulus / Tinggal kelas. |
| Year transition prereq | Source AY's Sem 2 must be `is_active=true` before transition can execute. |

## File Structure

**Create:**
- `src/database/migrations/2026_05_14_220000_backfill_enrollments_from_year_transitions.php`
- `src/tests/Feature/StudentEnrollment/HistoricalRosterTaskTest.php`
- `src/tests/Feature/StudentEnrollment/HistoricalRosterExamTest.php`
- `src/tests/Feature/StudentEnrollment/CarryOverOverridesTest.php`
- `src/tests/Feature/StudentEnrollment/SingleActiveSemesterTest.php`
- `src/tests/Feature/StudentEnrollment/YearTransitionPrereqTest.php`

**Modify:**
- `src/app/Http/Controllers/StudentController.php` — Bug A fix
- `src/app/Http/Controllers/TaskController.php` — Bug B (student list from enrollments)
- `src/app/Http/Controllers/ExamController.php` — Bug B
- `src/app/Http/Controllers/AttendanceController.php` — Bug B (where applicable)
- `src/app/Http/Controllers/SemesterController.php` — Bug D (global single-active)
- `src/app/Services/EnrollmentCarryOverService.php` — F1 (accept overrides)
- `src/app/Services/YearTransitionService.php` — F2b (Sem 2 prereq)
- `src/resources/js/Pages/Semesters/CarryOverConfirmModal.vue` — F1 UI
- `src/resources/js/Pages/AcademicYears/Index.vue` — F2a (remove Aktifkan button, add Kenaikan Kelas)
- `src/resources/js/Pages/Students/Index.vue` — Bug A UX (auto-pick semester)

---

## Task 1: Backfill historical enrollments from past year transitions

**Files:**
- Create: `src/database/migrations/2026_05_14_220000_backfill_enrollments_from_year_transitions.php`

The prod DB has one year_transition_log (AY 1 → AY 2, 4 promoted) that ran before Phase 1 deploy. The mutations exist in `student_mutations` but no corresponding enrollment rows were written. Reconstruct them.

For each `student_mutations` row where `type='promotion'`:
- Write enrollment for `(student_id, source-AY Sem 2, from_class_id, status='promoted_out')` — if Sem 2 exists for that AY
- Write enrollment for `(student_id, target-AY Sem 1, to_class_id, status='active')` — if Sem 1 exists for target

For `type='retention'`: same as promotion (source closed as retained_out, target opened as active)
For `type='graduated'`: source closed as graduated, no target enrollment
For `type='transfer_out'`: source closed as transferred_out
For `type='dropout'`: source closed as dropped_out

Use `insertOrIgnore` so this is idempotent and won't clobber existing Phase 1 enrollments.

- [ ] **Step 1: Write the migration**

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $statusMap = [
            'promotion'    => 'promoted_out',
            'retention'    => 'retained_out',
            'graduated'    => 'graduated',
            'transfer_out' => 'transferred_out',
            'dropout'      => 'dropped_out',
        ];

        $now = now();
        $rows = [];

        // For each transition mutation, derive source-AY and target-AY enrollments
        $mutations = DB::table('student_mutations')
            ->whereIn('type', array_keys($statusMap))
            ->get();

        foreach ($mutations as $m) {
            $sourceClass = $m->from_class_id ? DB::table('classes')->find($m->from_class_id) : null;
            $targetClass = $m->to_class_id ? DB::table('classes')->find($m->to_class_id) : null;

            // Source enrollment — closed
            if ($sourceClass) {
                $sourceSem2 = DB::table('semesters')
                    ->where('academic_year_id', $sourceClass->academic_year_id)
                    ->orderByDesc('semester_number')
                    ->first();
                if ($sourceSem2) {
                    $rows[] = [
                        'student_id'  => $m->student_id,
                        'semester_id' => $sourceSem2->id,
                        'class_id'    => $m->from_class_id,
                        'status'      => $statusMap[$m->type],
                        'exit_date'   => $m->date,
                        'exit_reason' => 'Backfilled from year transition',
                        'created_at'  => $now,
                        'updated_at'  => $now,
                    ];
                }
            }

            // Target enrollment — active in Sem 1 of target AY
            if ($targetClass && in_array($m->type, ['promotion', 'retention'])) {
                $targetSem1 = DB::table('semesters')
                    ->where('academic_year_id', $targetClass->academic_year_id)
                    ->where('semester_number', 1)
                    ->first();
                if ($targetSem1) {
                    $rows[] = [
                        'student_id'  => $m->student_id,
                        'semester_id' => $targetSem1->id,
                        'class_id'    => $m->to_class_id,
                        'status'      => 'active',
                        'created_at'  => $now,
                        'updated_at'  => $now,
                    ];
                }
            }
        }

        if (! empty($rows)) {
            DB::table('student_class_enrollments')->insertOrIgnore($rows);
        }
    }

    public function down(): void
    {
        // Non-destructive — see Phase 1 backfill rationale
    }
};
```

- [ ] **Step 2: Run locally + verify on a dev DB**

Run: `cd src && php artisan migrate`
Expected: migration runs.

- [ ] **Step 3: Commit**

```bash
git add src/database/migrations/2026_05_14_220000_backfill_enrollments_from_year_transitions.php
git commit -m "feat(db): backfill enrollments from past year transitions"
```

---

## Task 2: Bug D — single global active semester

**Files:**
- Modify: `src/app/Http/Controllers/SemesterController.php`
- Test: `src/tests/Feature/StudentEnrollment/SingleActiveSemesterTest.php`

- [ ] **Step 1: Write failing test**

```php
<?php

use App\Models\AcademicYear;
use App\Models\Semester;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('activating a semester deactivates the globally-active semester in any other AY', function () {
    $admin = User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);
    $ay1 = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $ay2 = AcademicYear::create(['name' => '2026/2027', 'is_active' => false, 'start_date' => '2026-07-01', 'end_date' => '2027-06-30']);

    $semA = Semester::create(['academic_year_id' => $ay1->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $semB = Semester::create(['academic_year_id' => $ay2->id, 'semester_number' => 1, 'is_active' => false, 'start_date' => '2026-07-01', 'end_date' => '2026-12-31']);

    $this->actingAs($admin)->post("/semesters/{$semB->id}/activate")->assertRedirect();

    expect(Semester::find($semA->id)->is_active)->toBeFalse();
    expect(Semester::find($semB->id)->is_active)->toBeTrue();
    expect(Semester::where('is_active', true)->count())->toBe(1);
});
```

- [ ] **Step 2: Run, expect fail**

`cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/SingleActiveSemesterTest.php`

- [ ] **Step 3: Patch `SemesterController::activate`**

Replace the existing inner `Semester::where('academic_year_id', ...)->update(...)` line with:

```php
            // Single active semester globally (Phase 2 Bug D)
            Semester::where('is_active', true)->update(['is_active' => false]);
            $semester->update(['is_active' => true]);
```

(Remove the now-redundant per-AY update; the global `where('is_active', true)` covers it.)

- [ ] **Step 4: Run, expect pass**

`cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/SingleActiveSemesterTest.php`

- [ ] **Step 5: Commit**

```bash
git add src/app/Http/Controllers/SemesterController.php src/tests/Feature/StudentEnrollment/SingleActiveSemesterTest.php
git commit -m "fix(semester): enforce single globally-active semester"
```

---

## Task 3: Bug A — Students Index uses enrollments when AY selected (no semester)

**Files:**
- Modify: `src/app/Http/Controllers/StudentController.php`

When admin selects only Tahun Ajaran (no semester), query students via enrollments table joined to semesters of that AY. Default semester filter to the AY's most-recently-numbered semester (Sem 2 if exists, else Sem 1).

- [ ] **Step 1: Patch `StudentController::index`**

In the existing `index()` method, after computing `$selectedAyId`, replace the conditional with:

```php
        $semesterId = $request->integer('semester_id') ?: null;

        // Bug A: when AY is selected without explicit semester, default to the
        // most-recently-numbered semester of that AY (the one whose roster is
        // most representative of "the year").
        if (! $semesterId && $selectedAyId) {
            $semesterId = \App\Models\Semester::where('academic_year_id', $selectedAyId)
                ->orderByDesc('semester_number')
                ->value('id');
        }

        if ($semesterId) {
            // Historical roster: join enrollments
            $students = Student::query()
                ->select('students.*')
                ->selectRaw('sce.class_id as enrollment_class_id, sce.status as enrollment_status, sce.exit_date as enrollment_exit_date')
                ->join('student_class_enrollments as sce', 'sce.student_id', '=', 'students.id')
                ->where('sce.semester_id', $semesterId)
                ->with(['class.academicYear:id,name,is_active'])
                ->when($request->search, fn($q, $s) => $q->where(function ($qq) use ($s) {
                    $qq->where('students.name', 'like', "%{$s}%")
                       ->orWhere('students.nis', 'like', "%{$s}%");
                }))
                ->when($request->class_id, fn($q, $c) => $q->where('sce.class_id', $c))
                ->orderByDesc('students.id')
                ->paginate(20)
                ->withQueryString();
        } else {
            // No AY selected → current view (existing behaviour)
            $students = Student::query()
                ->with('class.academicYear:id,name,is_active')
                ->when($request->search, fn($q, $s) => $q->where(function ($qq) use ($s) {
                    $qq->where('name', 'like', "%{$s}%")
                       ->orWhere('nis', 'like', "%{$s}%");
                }))
                ->when($request->class_id, fn($q, $c) => $q->where('class_id', $c))
                ->when($request->status, fn($q, $s) => $q->where('status', $s))
                ->latest()
                ->paginate(20)
                ->withQueryString();
        }
```

(Note: this changes the behavior when only AY is selected to use enrollments. The default-active-semester case is also handled because we resolve `selectedAyId` from active AY if not explicitly given.)

- [ ] **Step 2: Smoke test in tinker**

```bash
cd src && php artisan tinker --execute='
$ay = App\Models\AcademicYear::first();
$semId = App\Models\Semester::where("academic_year_id", $ay?->id)->orderByDesc("semester_number")->value("id");
echo "AY: {$ay?->name}, default semester_id: $semId" . PHP_EOL;
'
```

- [ ] **Step 3: Commit**

```bash
git add src/app/Http/Controllers/StudentController.php
git commit -m "fix(students): default to enrollments view when AY selected without semester"
```

---

## Task 4: Bug B — TaskController student listing from enrollments

**Files:**
- Modify: `src/app/Http/Controllers/TaskController.php`
- Test: `src/tests/Feature/StudentEnrollment/HistoricalRosterTaskTest.php`

The pages that need fixing: `classIndex()`, `create()` (form student picker if any), `show()` (input scores list).

Read the current TaskController to find where `$class->students()` is called or where student lists are built. Replace with an enrollment-based query: students whose `student_class_enrollments` row exists for `(task.semester_id, task.class_id)` OR `(class.id matched to a relevant semester)`.

For `classIndex(SchoolClass $class, Request $request)` the relevant data is `studentsCount`. Replace:
```php
'studentsCount' => $class->students()->count(),
```
With:
```php
'studentsCount' => \App\Models\StudentClassEnrollment::where('class_id', $class->id)->where('semester_id', $selectedSemesterId)->count(),
```

For `show(Task $task)` or wherever the scoring page resolves students, query students whose enrollment row matches `(task.class_id, task.semester_id)` — this is the historical roster.

- [ ] **Step 1: Inspect current TaskController to find all `students` / `class->students` references**

Run: `cd src && grep -n 'class->students\|students()->\|->students()' app/Http/Controllers/TaskController.php`

Note all locations. Pay attention to which method needs the historical roster (typically the scoring form `show()` and the list `classIndex()`).

- [ ] **Step 2: Write failing test**

```php
<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\Subject;
use App\Models\Task;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('task class roster lists students who had enrollment in that class+semester even if they have since moved on', function () {
    $admin = User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => false, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => false, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $oldClass = SchoolClass::create(['name' => '1', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    $newClass = SchoolClass::create(['name' => '2', 'grade_level' => 2, 'academic_year_id' => $ay->id, 'status' => 'active']);

    // Student NOW in newClass (moved up), but historically in oldClass
    $student = Student::create(['nis' => '1', 'name' => 'Historic', 'class_id' => $newClass->id, 'status' => 'active']);
    StudentClassEnrollment::create([
        'student_id' => $student->id, 'semester_id' => $sem->id,
        'class_id' => $oldClass->id, 'status' => 'promoted_out',
    ]);

    $response = $this->actingAs($admin)->get("/tasks/class/{$oldClass->id}?semester_id={$sem->id}");
    $response->assertOk();

    expect($response->viewData('page')['props']['studentsCount'])->toBe(1);
});
```

- [ ] **Step 3: Run, expect fail**

`cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/HistoricalRosterTaskTest.php`

- [ ] **Step 4: Patch TaskController**

In `classIndex()`, find `'studentsCount' => $class->students()->count()` and replace with:

```php
            'studentsCount' => \App\Models\StudentClassEnrollment::where('class_id', $class->id)
                ->where('semester_id', $selectedSemesterId)
                ->count(),
```

(Use the `$selectedSemesterId` already computed earlier in that method.)

In `show(Task $task)` (or wherever the input-scores list of students is rendered), find the student loading logic. Inspect what's there first. If it currently does `$task->schoolClass->students()` or similar, replace with:

```php
$students = \App\Models\Student::query()
    ->select('students.*')
    ->join('student_class_enrollments as sce', 'sce.student_id', '=', 'students.id')
    ->where('sce.class_id', $task->class_id)
    ->where('sce.semester_id', $task->semester_id)
    ->orderBy('students.name')
    ->get();
```

- [ ] **Step 5: Run test + smoke check**

`cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/HistoricalRosterTaskTest.php`

- [ ] **Step 6: Commit**

```bash
git add src/app/Http/Controllers/TaskController.php src/tests/Feature/StudentEnrollment/HistoricalRosterTaskTest.php
git commit -m "fix(tasks): historical roster from enrollments for past classes"
```

---

## Task 5: Bug B — ExamController student listing from enrollments

**Files:**
- Modify: `src/app/Http/Controllers/ExamController.php`
- Test: `src/tests/Feature/StudentEnrollment/HistoricalRosterExamTest.php`

Same pattern as TaskController.

- [ ] **Step 1: Inspect ExamController for student-listing locations**

`cd src && grep -n 'class->students\|students()->\|->students()' app/Http/Controllers/ExamController.php`

- [ ] **Step 2: Write failing test (mirror Task 4 test structure for exams)**

```php
<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('exam class roster lists students who had enrollment in that class+semester even if they have since moved on', function () {
    $admin = User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => false, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => false, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $oldClass = SchoolClass::create(['name' => '1', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    $newClass = SchoolClass::create(['name' => '2', 'grade_level' => 2, 'academic_year_id' => $ay->id, 'status' => 'active']);

    $student = Student::create(['nis' => '1', 'name' => 'Historic', 'class_id' => $newClass->id, 'status' => 'active']);
    StudentClassEnrollment::create([
        'student_id' => $student->id, 'semester_id' => $sem->id,
        'class_id' => $oldClass->id, 'status' => 'promoted_out',
    ]);

    $response = $this->actingAs($admin)->get("/exams/class/{$oldClass->id}?semester_id={$sem->id}");
    $response->assertOk();

    expect($response->viewData('page')['props']['studentsCount'])->toBe(1);
});
```

- [ ] **Step 3: Run, expect fail**

- [ ] **Step 4: Patch ExamController**

Apply same pattern as TaskController: replace `$class->students()->count()` with enrollment-based count, and replace student loading on `show()` with enrollment join.

- [ ] **Step 5: Run, expect pass**

- [ ] **Step 6: Commit**

```bash
git add src/app/Http/Controllers/ExamController.php src/tests/Feature/StudentEnrollment/HistoricalRosterExamTest.php
git commit -m "fix(exams): historical roster from enrollments for past classes"
```

---

## Task 6: Bug B — AttendanceController student listing from enrollments

**Files:**
- Modify: `src/app/Http/Controllers/AttendanceController.php`

Apply the same enrollment-based student listing pattern. Inspect first to find where students are listed.

- [ ] **Step 1: Inspect**

`cd src && grep -n 'class->students\|students()->\|->students()' app/Http/Controllers/AttendanceController.php`

- [ ] **Step 2: Apply same enrollment-based student query pattern**

For wherever students are loaded for an attendance class+semester context, use:

```php
$students = \App\Models\Student::query()
    ->select('students.*')
    ->join('student_class_enrollments as sce', 'sce.student_id', '=', 'students.id')
    ->where('sce.class_id', $class->id)
    ->where('sce.semester_id', $semesterId)
    ->orderBy('students.name')
    ->get();
```

- [ ] **Step 3: Smoke test by hitting the attendance page in dev**

(No new automated test required — covered by enrollment data flow already tested in Tasks 4 + 5.)

- [ ] **Step 4: Commit**

```bash
git add src/app/Http/Controllers/AttendanceController.php
git commit -m "fix(attendance): historical roster from enrollments"
```

---

## Task 7: Feature F1 — EnrollmentCarryOverService::execute accepts per-student overrides

**Files:**
- Modify: `src/app/Services/EnrollmentCarryOverService.php`
- Test: `src/tests/Feature/StudentEnrollment/CarryOverOverridesTest.php`

`execute()` should accept an optional `$overrides` parameter — an array keyed by student_id mapping to a target status (`active`, `transferred_out`, `dropped_out`, `graduated`, `retained_out`). For each carry_over student, the override (if set) determines what status to write in the target semester. Students marked non-active should NOT carry over to target — they should get their `student_class_enrollments` row in the SOURCE semester closed with the override status, AND `students.status` updated to match (transferred / dropout / graduated / etc.) if applicable.

Status semantics:
- `active` (default) → carry over to target as before
- `transferred_out` / `dropped_out` / `graduated` → no target enrollment; close source enrollment with that status + exit_date=today; update students.status

- [ ] **Step 1: Write failing test**

```php
<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Services\EnrollmentCarryOverService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('execute honors per-student overrides for keluar/lulus during carry-over', function () {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem1 = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $sem2 = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 2, 'is_active' => false, 'start_date' => '2026-01-01', 'end_date' => '2026-06-30']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);

    $stay = Student::create(['nis' => '1', 'name' => 'Stay', 'class_id' => $class->id, 'status' => 'active']);
    $leave = Student::create(['nis' => '2', 'name' => 'Leave', 'class_id' => $class->id, 'status' => 'active']);
    StudentClassEnrollment::create(['student_id' => $stay->id, 'semester_id' => $sem1->id, 'class_id' => $class->id, 'status' => 'active']);
    StudentClassEnrollment::create(['student_id' => $leave->id, 'semester_id' => $sem1->id, 'class_id' => $class->id, 'status' => 'active']);

    $svc = app(EnrollmentCarryOverService::class);
    $result = $svc->execute($sem2->id, [
        $leave->id => 'transferred_out',
    ]);

    expect($result['carried'])->toBe(1); // only stay
    // stay has new enrollment in sem2
    expect(StudentClassEnrollment::where('student_id', $stay->id)->where('semester_id', $sem2->id)->where('status', 'active')->exists())->toBeTrue();
    // leave's sem1 enrollment is now transferred_out, no sem2 enrollment
    expect(StudentClassEnrollment::where('student_id', $leave->id)->where('semester_id', $sem1->id)->value('status'))->toBe('transferred_out');
    expect(StudentClassEnrollment::where('student_id', $leave->id)->where('semester_id', $sem2->id)->exists())->toBeFalse();
    // leave's student.status synced
    expect(Student::find($leave->id)->status)->toBe('transferred');
});
```

- [ ] **Step 2: Run, expect fail**

- [ ] **Step 3: Modify `execute()` to accept `$overrides = []`**

Replace the existing `execute(int $targetSemesterId): array` signature with:

```php
    public function execute(int $targetSemesterId, array $overrides = []): array
    {
        return DB::transaction(function () use ($targetSemesterId, $overrides) {
            $plan = $this->preview($targetSemesterId);
            $studentStatusMap = [
                'transferred_out' => 'transferred',
                'dropped_out'     => 'dropout',
                'graduated'       => 'graduated',
                'retained_out'    => 'active',
            ];

            if ($plan['source_semester_id'] === null) {
                return [
                    'carried'            => 0,
                    'skipped'            => count($plan['skipped']),
                    'source_semester_id' => null,
                    'target_semester_id' => $targetSemesterId,
                ];
            }

            $now = now();
            $rowsToCarry = [];
            $exits = []; // ['student_id' => exitStatus, ...]

            foreach ($plan['carry_over'] as $entry) {
                $override = $overrides[$entry['student_id']] ?? StudentClassEnrollment::STATUS_ACTIVE;
                if ($override === StudentClassEnrollment::STATUS_ACTIVE) {
                    $rowsToCarry[] = [
                        'student_id'  => $entry['student_id'],
                        'semester_id' => $targetSemesterId,
                        'class_id'    => $entry['class_id'],
                        'status'      => StudentClassEnrollment::STATUS_ACTIVE,
                        'created_at'  => $now,
                        'updated_at'  => $now,
                    ];
                } else {
                    $exits[$entry['student_id']] = $override;
                }
            }

            // Close source-semester enrollments for exits
            foreach ($exits as $studentId => $exitStatus) {
                StudentClassEnrollment::where('student_id', $studentId)
                    ->where('semester_id', $plan['source_semester_id'])
                    ->update([
                        'status'      => $exitStatus,
                        'exit_date'   => $now->toDateString(),
                        'exit_reason' => 'Set during semester transition',
                    ]);
                if (isset($studentStatusMap[$exitStatus]) && $studentStatusMap[$exitStatus] !== 'active') {
                    \App\Models\Student::where('id', $studentId)->update(['status' => $studentStatusMap[$exitStatus]]);
                }
            }

            $before = StudentClassEnrollment::where('semester_id', $targetSemesterId)->count();
            if (! empty($rowsToCarry)) {
                DB::table('student_class_enrollments')->insertOrIgnore($rowsToCarry);
            }
            $after = StudentClassEnrollment::where('semester_id', $targetSemesterId)->count();

            return [
                'carried'            => $after - $before,
                'skipped'            => count($plan['skipped']),
                'source_semester_id' => $plan['source_semester_id'],
                'target_semester_id' => $targetSemesterId,
            ];
        });
    }
```

- [ ] **Step 4: Run, expect pass**

- [ ] **Step 5: Update `SemesterController::activate` to forward overrides**

Open `src/app/Http/Controllers/SemesterController.php`. The `activate()` calls `execute($semester->id)` — change to:

```php
$overrides = (array) request()->input('overrides', []);
return app(EnrollmentCarryOverService::class)->execute($semester->id, $overrides);
```

- [ ] **Step 6: Commit**

```bash
git add src/app/Services/EnrollmentCarryOverService.php src/app/Http/Controllers/SemesterController.php src/tests/Feature/StudentEnrollment/CarryOverOverridesTest.php
git commit -m "feat(carry-over): per-student status overrides during semester transition"
```

---

## Task 8: Feature F1 — CarryOverConfirmModal UI dropdown

**Files:**
- Modify: `src/resources/js/Pages/Semesters/CarryOverConfirmModal.vue`

Add a reactive `overrides` object keyed by student_id, and render a `<select>` per carry_over row with the status options. On confirm, send `overrides` as POST body.

- [ ] **Step 1: Patch the modal**

Open `src/resources/js/Pages/Semesters/CarryOverConfirmModal.vue` and replace the `<script setup>` block with:

```vue
<script setup>
import { ref, watch, reactive } from 'vue';
import { router } from '@inertiajs/vue3';

const props = defineProps({
  show: Boolean,
  semester: Object,
});
const emit = defineEmits(['close']);

const loading = ref(false);
const preview = ref(null);
const overrides = reactive({});

const STATUS_OPTIONS = [
  { value: 'active',          label: 'Aktif' },
  { value: 'transferred_out', label: 'Keluar (Pindah)' },
  { value: 'dropped_out',     label: 'Keluar (Dropout)' },
  { value: 'graduated',       label: 'Lulus' },
  { value: 'retained_out',    label: 'Tinggal kelas' },
];

watch(() => props.show, async (val) => {
  if (val && props.semester) {
    loading.value = true;
    try {
      const res = await fetch(`/semesters/${props.semester.id}/carry-over-preview`);
      preview.value = await res.json();
      // initialize overrides default to 'active' for each carry_over student
      for (const row of (preview.value.carry_over || [])) {
        overrides[row.student_id] = 'active';
      }
    } finally {
      loading.value = false;
    }
  } else {
    preview.value = null;
    Object.keys(overrides).forEach((k) => delete overrides[k]);
  }
});

const confirm = () => {
  router.post(`/semesters/${props.semester.id}/activate`, {
    overrides: { ...overrides },
  }, {
    onFinish: () => emit('close'),
  });
};
</script>
```

Replace the `<template>`'s carry_over list (`<ul>... <li v-for="row in preview.carry_over"...>...</li></ul>`) with a table-style layout with dropdowns:

```html
          <div v-if="preview.carry_over.length" class="mb-4">
            <h4 class="mb-2 text-xs font-semibold uppercase text-slate-500">Daftar siswa & status di semester baru</h4>
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-slate-100 bg-slate-50/60">
                  <th class="px-3 py-2 text-left text-xs font-semibold uppercase text-slate-500">Siswa</th>
                  <th class="px-3 py-2 text-left text-xs font-semibold uppercase text-slate-500">Kelas</th>
                  <th class="px-3 py-2 text-left text-xs font-semibold uppercase text-slate-500">Status</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="row in preview.carry_over" :key="row.student_id" class="border-b border-slate-50">
                  <td class="px-3 py-2 text-slate-700">{{ row.name }}</td>
                  <td class="px-3 py-2 text-slate-600">{{ row.class_name }}</td>
                  <td class="px-3 py-2">
                    <select v-model="overrides[row.student_id]" class="w-full rounded-md border border-slate-200 px-2 py-1 text-xs">
                      <option v-for="opt in STATUS_OPTIONS" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
                    </select>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
```

- [ ] **Step 2: Build assets**

`cd src && npm run build`

- [ ] **Step 3: Commit**

```bash
git add src/resources/js/Pages/Semesters/CarryOverConfirmModal.vue
git commit -m "feat(ui): per-student status dropdown in carry-over modal"
```

---

## Task 9: Feature F2b — Year transition prerequisite (Sem 2 must be active)

**Files:**
- Modify: `src/app/Services/YearTransitionService.php`
- Test: `src/tests/Feature/StudentEnrollment/YearTransitionPrereqTest.php`

- [ ] **Step 1: Write failing test**

```php
<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\User;
use App\Services\YearTransitionService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('year transition rejects execution when source AY Sem 2 is not active', function () {
    $admin = User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);
    $sourceAy = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $targetAy = AcademicYear::create(['name' => '2026/2027', 'is_active' => false, 'start_date' => '2026-07-01', 'end_date' => '2027-06-30']);

    // Only Sem 1 of source AY exists/active
    Semester::create(['academic_year_id' => $sourceAy->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    Semester::create(['academic_year_id' => $targetAy->id, 'semester_number' => 1, 'is_active' => false, 'start_date' => '2026-07-01', 'end_date' => '2026-12-31']);

    $class1A = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $sourceAy->id, 'status' => 'active']);
    Student::create(['nis' => '1', 'name' => 'X', 'class_id' => $class1A->id, 'status' => 'active']);

    $svc = app(YearTransitionService::class);

    expect(fn () => $svc->executeTransition($sourceAy->id, $targetAy->id, [], $admin))
        ->toThrow(\RuntimeException::class);
});
```

- [ ] **Step 2: Run, expect fail**

- [ ] **Step 3: Patch `YearTransitionService::executeTransition`**

Add a guard at the very start of the method (before the existing lock acquisition):

```php
        $sourceSem2 = \App\Models\Semester::where('academic_year_id', $sourceAyId)
            ->where('semester_number', 2)
            ->where('is_active', true)
            ->first();
        if (! $sourceSem2) {
            throw new \RuntimeException('Kenaikan kelas hanya bisa dieksekusi saat Sem 2 dari tahun ajaran sumber sedang aktif.');
        }
```

- [ ] **Step 4: Run, expect pass**

- [ ] **Step 5: Verify no regression in existing year transition tests**

`cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/YearTransition*`

(In the existing `YearTransitionEnrollmentTest`, the test setup creates sourceSem2 with `is_active=true` — so it should still pass.)

- [ ] **Step 6: Commit**

```bash
git add src/app/Services/YearTransitionService.php src/tests/Feature/StudentEnrollment/YearTransitionPrereqTest.php
git commit -m "feat(year-transition): require source AY Sem 2 active before executing"
```

---

## Task 10: Feature F2a — Remove AY "Aktifkan" button, route activation via Kenaikan Kelas

**Files:**
- Modify: `src/resources/js/Pages/AcademicYears/Index.vue`
- Modify: `src/app/Http/Controllers/AcademicYearController.php`

The current AY list likely has an "Aktifkan" button per AY (POST to `/academic-years/{id}/activate`). Remove that button. For an inactive AY, show "Mulai Kenaikan Kelas" which links to `/year-transitions/create?target_academic_year_id={id}` (the existing year transition entry page).

For the currently-active AY: keep just the "Aktif" badge.

For AY without any students or transitions: the very first AY is the bootstrap case — it should still be activatable via some bootstrap path (e.g., a "Tandai Aktif (Inisial)" button shown only if no AY has ever been active and there are no students). Discuss with the user if first-time setup is a concern — for now we'll keep that button but only if there are zero year_transition_logs.

- [ ] **Step 1: Inspect existing AcademicYears/Index.vue**

`cd src && head -200 resources/js/Pages/AcademicYears/Index.vue`

Note the existing Aktifkan button + its handler.

- [ ] **Step 2: Replace Aktifkan button with Mulai Kenaikan Kelas link**

Find the existing button (likely `<button>` or `<Link>` calling `/academic-years/{id}/activate`). Replace with:

```html
<Link
  v-if="!ay.is_active && hasActiveAy"
  :href="`/year-transitions/create?target_academic_year_id=${ay.id}`"
  class="...same styling as old Aktifkan button..."
>
  Mulai Kenaikan Kelas
</Link>
<button
  v-else-if="!ay.is_active && !hasActiveAy"
  @click="activateBootstrap(ay)"
  class="...same styling..."
>
  Tandai Aktif (Inisial)
</button>
<span v-else class="inline-flex items-center rounded-md bg-emerald-100 px-2 py-0.5 text-xs font-medium text-emerald-700">
  Aktif
</span>
```

Add to `<script setup>`:

```javascript
import { computed } from 'vue';
import { router } from '@inertiajs/vue3';

const hasActiveAy = computed(() => props.academicYears.some(ay => ay.is_active));

const activateBootstrap = (ay) => {
  if (!confirm(`Tandai ${ay.name} sebagai TA aktif inisial? Setelah ada TA aktif, perubahan harus via Kenaikan Kelas.`)) return;
  router.post(`/academic-years/${ay.id}/activate`);
};
```

- [ ] **Step 3: Build assets**

`cd src && npm run build`

- [ ] **Step 4: Commit**

```bash
git add src/resources/js/Pages/AcademicYears/Index.vue
git commit -m "feat(ui): remove AY Aktifkan button; route via Kenaikan Kelas"
```

---

## Task 11: Run full test suite + deploy to production

**Files:** (deploy)

- [ ] **Step 1: Run all enrollment tests**

`cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/`
Expected: all Phase 1 + Phase 2 tests pass.

- [ ] **Step 2: Build assets**

`cd src && npm run build`

- [ ] **Step 3: Take prod DB backup**

```bash
ssh -i ~/.ssh/floz_cpanel sdnkelap@tarsius.kencang.com 'bash -s' <<'SH'
DB="sdnkelap_floz"; U="sdnkelap_floz"; P='sYtrpMJ*fE0*YTEwlBl%p!AosEUh'
TS=$(date +%Y%m%d_%H%M%S)
BACKUP=~/floz_db_backup_${TS}_phase2.sql
mysqldump -u"$U" -p"$P" --single-transaction --no-tablespaces "$DB" > "$BACKUP"
ls -lh "$BACKUP"
SH
```

- [ ] **Step 4: Copy modified PHP files + new migration + build**

```bash
SRC=/Users/tokaf/Floz_SDN_KELAPADUA_IV/src
SERVER=sdnkelap@tarsius.kencang.com
KEY=~/.ssh/floz_cpanel

scp -i "$KEY" \
  "$SRC/app/Http/Controllers/StudentController.php" \
  "$SRC/app/Http/Controllers/SemesterController.php" \
  "$SRC/app/Http/Controllers/TaskController.php" \
  "$SRC/app/Http/Controllers/ExamController.php" \
  "$SRC/app/Http/Controllers/AttendanceController.php" \
  "$SERVER:/home/sdnkelap/floz/app/Http/Controllers/"

scp -i "$KEY" \
  "$SRC/app/Services/EnrollmentCarryOverService.php" \
  "$SRC/app/Services/YearTransitionService.php" \
  "$SERVER:/home/sdnkelap/floz/app/Services/"

scp -i "$KEY" \
  "$SRC/database/migrations/2026_05_14_220000_backfill_enrollments_from_year_transitions.php" \
  "$SERVER:/home/sdnkelap/floz/database/migrations/"

cd "$SRC/public/build"
tar -czf /tmp/floz-build.tgz .
scp -i "$KEY" /tmp/floz-build.tgz "$SERVER:/tmp/"
```

- [ ] **Step 5: Migrate + cleanup multi-active state + rebuild caches on server**

```bash
ssh -i ~/.ssh/floz_cpanel sdnkelap@tarsius.kencang.com 'bash -s' <<'SH'
set -e
cd ~/floz

echo "== Migrate (backfill from past transitions) =="
php artisan migrate --force

echo "== Cleanup: ensure exactly one active semester globally (Sem 2 of AY 1) =="
DB="sdnkelap_floz"; U="sdnkelap_floz"; P='sYtrpMJ*fE0*YTEwlBl%p!AosEUh'
mysql -u"$U" -p"$P" "$DB" -e "UPDATE semesters SET is_active = (id = 2);"

echo "== Replace public/build =="
rm -rf public/build/*
tar -xzf /tmp/floz-build.tgz -C public/build
rm /tmp/floz-build.tgz

echo "== Rebuild caches =="
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "== Verify enrollment counts =="
mysql -u"$U" -p"$DB" -e "SELECT semester_id, status, COUNT(*) FROM student_class_enrollments GROUP BY semester_id, status ORDER BY semester_id;" "$DB"
SH
```

- [ ] **Step 6: Smoke test in browser**

Test on https://sdnkelapaduaiv.my.id :
- /students with TA=2026/2027 (no semester) → should now auto-load Sem 2 enrollments showing the 4 promoted-out students with class context
- /students with TA=2027/2028 → should show 5 active students
- Tugas & Nilai → Kelas 1 (AY 1) → task "So" → should now show 2 students (Daniel, Fahrezi) historically
- Tahun Ajaran list → AY 2028/2029 should show "Mulai Kenaikan Kelas" button instead of Aktifkan
- Activate semester → modal shows status dropdown per siswa

- [ ] **Step 7: Report and offer Phase 2 PR**

---

## Self-Review

### Spec coverage

| Concern | Task |
|---|---|
| Bug A — Students Index empty for past AY | Task 3 |
| Bug B — Task page empty | Task 4 |
| Bug B — Exam page empty | Task 5 |
| Bug B — Attendance page | Task 6 |
| Bug C — Backfill past transition data | Task 1 |
| Bug D — Global single active semester | Task 2 |
| F1 — per-student override in carry-over | Tasks 7, 8 |
| F2a — Remove AY Aktifkan button | Task 10 |
| F2b — Sem 2 prereq for year transition | Task 9 |
| Prod data cleanup (multi-active fix) | Task 11 Step 5 (one-time SQL) |

### Notes

- Migration in Task 1 uses `insertOrIgnore` so Phase 1 enrollments aren't clobbered. Safe to re-run.
- Task 2 `Semester::where('is_active', true)` global update is fine for single-school deployment; for multi-school SaaS it would need a tenant scope.
- Task 4/5/6 — the legacy `class->students()` relation is NOT removed (still used elsewhere); only the controller queries change.
- Task 9's guard is a runtime check, not a UI gate. The Year Transition UI should also check this state before showing the "Execute" button, but that's covered by Task 10's "Mulai Kenaikan Kelas" routing (only inactive non-bootstrap AYs are valid targets).
