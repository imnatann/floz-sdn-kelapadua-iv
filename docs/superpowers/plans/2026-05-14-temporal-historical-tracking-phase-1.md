# Temporal/Historical Tracking — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a per-semester student class enrollment table so the system can answer "which students were in class X during semester Y?" — including students who later transferred, dropped, or graduated. Wire it into student CRUD, semester activation (auto carry-over), and year transition.

**Architecture:** New `student_class_enrollments` table (composite unique `student_id + semester_id`) holds the authoritative roster per semester. `students.class_id` is preserved as a denormalized "current" pointer to avoid breaking existing controllers/policies. A new `EnrollmentCarryOverService` runs idempotent carry-over when a semester is activated. `YearTransitionService` writes enrollments for the target year's Sem Ganjil after promotions.

**Tech Stack:** Laravel 11, Inertia.js + Vue 3, MySQL/MariaDB on production (PostgreSQL in local dev), Pest for tests, Vite for assets.

**Spec:** `docs/superpowers/specs/2026-05-14-temporal-historical-tracking-design.md`

---

## File Structure

**Create:**
- `src/database/migrations/2026_05_14_180000_create_student_class_enrollments_table.php` — schema
- `src/database/migrations/2026_05_14_180001_backfill_student_class_enrollments.php` — one-time backfill
- `src/app/Models/StudentClassEnrollment.php` — Eloquent model + relations
- `src/app/Services/EnrollmentCarryOverService.php` — preview + execute carry-over
- `src/app/Services/StudentEnrollmentSync.php` — single helper used by StudentController + YearTransitionService to keep enrollments in sync
- `src/tests/Feature/StudentEnrollment/EnrollmentBackfillTest.php`
- `src/tests/Feature/StudentEnrollment/StudentControllerEnrollmentTest.php`
- `src/tests/Feature/StudentEnrollment/EnrollmentCarryOverServiceTest.php`
- `src/tests/Feature/StudentEnrollment/SemesterActivationCarryOverTest.php`
- `src/tests/Feature/StudentEnrollment/YearTransitionEnrollmentTest.php`
- `src/resources/js/Pages/Semesters/CarryOverConfirmModal.vue`

**Modify:**
- `src/app/Models/Student.php` — add `enrollments()` hasMany
- `src/app/Models/SchoolClass.php` — add `enrollments()` hasMany
- `src/app/Models/Semester.php` — add `enrollments()` hasMany
- `src/app/Http/Controllers/StudentController.php` — store/update hooks, semester filter on index, eager-load enrollments on show
- `src/app/Http/Controllers/SemesterController.php` — activate() now also runs carry-over
- `src/app/Services/YearTransitionService.php` — `applyPromotion`/`applyRetention` write enrollment in target Sem Ganjil + close source-year terminal semester enrollment
- `src/resources/js/Pages/Students/Index.vue` — semester filter dropdown, status badge for non-active enrollments
- `src/resources/js/Pages/Students/Show.vue` — Riwayat Kelas section in existing Mutasi & Riwayat tab (or new tab)
- `src/resources/js/Pages/Students/Tabs/StudentMutationTab.vue` — add Riwayat Kelas list above existing mutation list
- `src/resources/js/Pages/Semesters/Index.vue` — Activate button triggers CarryOverConfirmModal

---

## Task 1: Create `student_class_enrollments` migration

**Files:**
- Create: `src/database/migrations/2026_05_14_180000_create_student_class_enrollments_table.php`

- [ ] **Step 1: Write the migration**

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('student_class_enrollments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('students')->cascadeOnDelete();
            $table->foreignId('semester_id')->constrained('semesters')->restrictOnDelete();
            $table->foreignId('class_id')->constrained('classes')->restrictOnDelete();
            $table->string('status', 20)->default('active');
            $table->date('exit_date')->nullable();
            $table->string('exit_reason', 255)->nullable();
            $table->timestamps();

            $table->unique(['student_id', 'semester_id'], 'sce_student_semester_unique');
            $table->index(['semester_id', 'class_id'], 'sce_semester_class_idx');
            $table->index(['student_id', 'semester_id'], 'sce_student_semester_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('student_class_enrollments');
    }
};
```

- [ ] **Step 2: Run migration locally**

Run: `cd src && php artisan migrate`
Expected output: `INFO Running migrations. ... 2026_05_14_180000_create_student_class_enrollments_table ......... DONE`

- [ ] **Step 3: Verify schema (Postgres dev)**

Run: `cd src && php artisan tinker --execute='Schema::getColumnListing("student_class_enrollments");'`
Expected: shows `id, student_id, semester_id, class_id, status, exit_date, exit_reason, created_at, updated_at`

- [ ] **Step 4: Commit**

```bash
git add src/database/migrations/2026_05_14_180000_create_student_class_enrollments_table.php
git commit -m "feat(db): add student_class_enrollments table for per-semester roster"
```

---

## Task 2: `StudentClassEnrollment` model

**Files:**
- Create: `src/app/Models/StudentClassEnrollment.php`

- [ ] **Step 1: Write the model**

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StudentClassEnrollment extends Model
{
    use HasFactory;

    public const STATUS_ACTIVE          = 'active';
    public const STATUS_TRANSFERRED_OUT = 'transferred_out';
    public const STATUS_DROPPED_OUT     = 'dropped_out';
    public const STATUS_GRADUATED       = 'graduated';
    public const STATUS_PROMOTED_OUT    = 'promoted_out';
    public const STATUS_RETAINED_OUT    = 'retained_out';

    protected $fillable = [
        'student_id',
        'semester_id',
        'class_id',
        'status',
        'exit_date',
        'exit_reason',
    ];

    protected $casts = [
        'student_id'  => 'integer',
        'semester_id' => 'integer',
        'class_id'    => 'integer',
        'exit_date'   => 'date',
    ];

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    public function semester(): BelongsTo
    {
        return $this->belongsTo(Semester::class);
    }

    public function schoolClass(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class, 'class_id');
    }

    public function isActive(): bool
    {
        return $this->status === self::STATUS_ACTIVE;
    }
}
```

- [ ] **Step 2: Add `enrollments()` to `Student` model**

Open `src/app/Models/Student.php`. After the `mutations()` method, add:

```php
public function enrollments(): \Illuminate\Database\Eloquent\Relations\HasMany
{
    return $this->hasMany(StudentClassEnrollment::class);
}
```

- [ ] **Step 3: Add `enrollments()` to `SchoolClass` model**

Open `src/app/Models/SchoolClass.php`. After `students()` method, add:

```php
public function enrollments(): HasMany
{
    return $this->hasMany(StudentClassEnrollment::class, 'class_id');
}
```

- [ ] **Step 4: Add `enrollments()` to `Semester` model**

Open `src/app/Models/Semester.php`. After `reportCards()` method, add:

```php
public function enrollments(): HasMany
{
    return $this->hasMany(StudentClassEnrollment::class);
}
```

- [ ] **Step 5: Smoke-test model in tinker**

Run:
```bash
cd src && php artisan tinker --execute='
$s = App\Models\Student::first();
echo "Student: " . $s->name . PHP_EOL;
echo "Enrollments rel exists: " . ($s->enrollments() instanceof Illuminate\Database\Eloquent\Relations\HasMany ? "yes" : "no") . PHP_EOL;
'
```
Expected: prints "yes"

- [ ] **Step 6: Commit**

```bash
git add src/app/Models/StudentClassEnrollment.php src/app/Models/Student.php src/app/Models/SchoolClass.php src/app/Models/Semester.php
git commit -m "feat(models): add StudentClassEnrollment + relations on Student/SchoolClass/Semester"
```

---

## Task 3: Backfill migration for existing students

**Files:**
- Create: `src/database/migrations/2026_05_14_180001_backfill_student_class_enrollments.php`
- Test: `src/tests/Feature/StudentEnrollment/EnrollmentBackfillTest.php`

- [ ] **Step 1: Write the failing test**

```php
<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('backfills enrollments for active students with class_id when active semester exists', function () {
    // Arrange — set up an AY + active semester + class + student
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    $student = Student::create(['nis' => '001', 'name' => 'A', 'class_id' => $class->id, 'status' => 'active']);

    // Pre-condition: no enrollments
    expect(StudentClassEnrollment::count())->toBe(0);

    // Act — run the backfill migration (already ran during RefreshDatabase, so manually invoke logic)
    $migrationFile = base_path('database/migrations/2026_05_14_180001_backfill_student_class_enrollments.php');
    $migration = require $migrationFile;
    $migration->up();

    // Assert
    $enrollment = StudentClassEnrollment::where('student_id', $student->id)->first();
    expect($enrollment)->not->toBeNull();
    expect($enrollment->semester_id)->toBe($sem->id);
    expect($enrollment->class_id)->toBe($class->id);
    expect($enrollment->status)->toBe('active');
});

it('does not duplicate enrollments when backfill runs twice', function () {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    Student::create(['nis' => '001', 'name' => 'A', 'class_id' => $class->id, 'status' => 'active']);

    $migrationFile = base_path('database/migrations/2026_05_14_180001_backfill_student_class_enrollments.php');
    $migration = require $migrationFile;
    $migration->up();
    $migration->up();

    expect(StudentClassEnrollment::count())->toBe(1);
});

it('skips students with null class_id', function () {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    Student::create(['nis' => '001', 'name' => 'Orphan', 'class_id' => null, 'status' => 'active']);

    $migrationFile = base_path('database/migrations/2026_05_14_180001_backfill_student_class_enrollments.php');
    $migration = require $migrationFile;
    $migration->up();

    expect(StudentClassEnrollment::count())->toBe(0);
});

it('skips inactive students', function () {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    Student::create(['nis' => '001', 'name' => 'Graduated', 'class_id' => $class->id, 'status' => 'graduated']);

    $migrationFile = base_path('database/migrations/2026_05_14_180001_backfill_student_class_enrollments.php');
    $migration = require $migrationFile;
    $migration->up();

    expect(StudentClassEnrollment::count())->toBe(0);
});
```

- [ ] **Step 2: Run test, expect fail**

Run: `cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/EnrollmentBackfillTest.php`
Expected: FAIL (migration file doesn't exist yet → require fails)

- [ ] **Step 3: Write the backfill migration**

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $activeSemester = DB::table('semesters')->where('is_active', true)->first();
        if (! $activeSemester) {
            return;
        }

        DB::table('students')
            ->where('status', 'active')
            ->whereNotNull('class_id')
            ->orderBy('id')
            ->chunkById(500, function ($students) use ($activeSemester) {
                $rows = [];
                $now = now();
                foreach ($students as $s) {
                    $rows[] = [
                        'student_id'  => $s->id,
                        'semester_id' => $activeSemester->id,
                        'class_id'    => $s->class_id,
                        'status'      => 'active',
                        'created_at'  => $now,
                        'updated_at'  => $now,
                    ];
                }
                if (! empty($rows)) {
                    DB::table('student_class_enrollments')->insertOrIgnore($rows);
                }
            });
    }

    public function down(): void
    {
        // Non-destructive: do not delete enrollments on rollback.
        // Manual cleanup if reverting: TRUNCATE student_class_enrollments;
    }
};
```

- [ ] **Step 4: Run tests, expect pass**

Run: `cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/EnrollmentBackfillTest.php`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add src/database/migrations/2026_05_14_180001_backfill_student_class_enrollments.php src/tests/Feature/StudentEnrollment/EnrollmentBackfillTest.php
git commit -m "feat(db): backfill student_class_enrollments for active students"
```

---

## Task 4: `StudentEnrollmentSync` helper service

This service centralises enrollment writes so `StudentController` and `YearTransitionService` share one code path.

**Files:**
- Create: `src/app/Services/StudentEnrollmentSync.php`

- [ ] **Step 1: Write the helper service**

```php
<?php

namespace App\Services;

use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use Illuminate\Support\Facades\DB;

/**
 * Single-responsibility helper that keeps student_class_enrollments rows
 * consistent with student CRUD and year transitions.
 *
 * All methods are idempotent and safe to call inside a parent transaction.
 */
class StudentEnrollmentSync
{
    /**
     * Ensure an active enrollment row exists for (student, active-semester, class).
     * If a row already exists, its class_id is overwritten to match `$classId`.
     * If no active semester exists OR `$classId` is null, no-op.
     *
     * Used by: StudentController::store, StudentController::update.
     */
    public function syncCurrent(Student $student, ?int $classId): void
    {
        if ($classId === null) {
            return;
        }
        $sem = Semester::where('is_active', true)->first();
        if (! $sem) {
            return;
        }

        StudentClassEnrollment::updateOrCreate(
            ['student_id' => $student->id, 'semester_id' => $sem->id],
            ['class_id' => $classId, 'status' => StudentClassEnrollment::STATUS_ACTIVE, 'exit_date' => null, 'exit_reason' => null],
        );
    }

    /**
     * Write an enrollment for a specific (student, semester, class).
     * Used by YearTransitionService when promoting/retaining into target year Sem Ganjil.
     */
    public function writeEnrollment(int $studentId, int $semesterId, int $classId, string $status = StudentClassEnrollment::STATUS_ACTIVE): StudentClassEnrollment
    {
        return StudentClassEnrollment::updateOrCreate(
            ['student_id' => $studentId, 'semester_id' => $semesterId],
            ['class_id' => $classId, 'status' => $status, 'exit_date' => null, 'exit_reason' => null],
        );
    }

    /**
     * Mark the latest enrollment for a student in a given AY as a terminal status
     * (promoted_out / retained_out / graduated / transferred_out / dropped_out).
     * Used by YearTransitionService to close out the source-year enrollment.
     */
    public function closeLatestEnrollmentInAcademicYear(int $studentId, int $academicYearId, string $status, ?string $reason = null): void
    {
        $semesterIds = Semester::where('academic_year_id', $academicYearId)->pluck('id');
        $latest = StudentClassEnrollment::where('student_id', $studentId)
            ->whereIn('semester_id', $semesterIds)
            ->orderByDesc('semester_id')
            ->first();

        if ($latest) {
            $latest->update([
                'status'      => $status,
                'exit_date'   => now()->toDateString(),
                'exit_reason' => $reason,
            ]);
        }
    }
}
```

- [ ] **Step 2: Smoke-test in tinker**

Run:
```bash
cd src && php artisan tinker --execute='$svc = app(App\Services\StudentEnrollmentSync::class); echo "ok " . get_class($svc);'
```
Expected: `ok App\Services\StudentEnrollmentSync`

- [ ] **Step 3: Commit**

```bash
git add src/app/Services/StudentEnrollmentSync.php
git commit -m "feat(svc): StudentEnrollmentSync centralises enrollment writes"
```

---

## Task 5: Wire `StudentController::store` to create enrollment

**Files:**
- Modify: `src/app/Http/Controllers/StudentController.php`
- Test: `src/tests/Feature/StudentEnrollment/StudentControllerEnrollmentTest.php`

- [ ] **Step 1: Write the failing test**

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

function makeAdmin(): User {
    return User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);
}

function makeAyWithActiveSem(): array {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    return [$ay, $sem, $class];
}

it('creates an enrollment row when admin creates a student with class_id', function () {
    [, $sem, $class] = makeAyWithActiveSem();
    $admin = makeAdmin();

    $this->actingAs($admin)->post('/students', [
        'nis'      => '001',
        'name'     => 'Nathan',
        'class_id' => $class->id,
    ])->assertRedirect();

    $student = Student::where('nis', '001')->first();
    expect($student)->not->toBeNull();

    $enrollment = StudentClassEnrollment::where('student_id', $student->id)->first();
    expect($enrollment)->not->toBeNull();
    expect($enrollment->semester_id)->toBe($sem->id);
    expect($enrollment->class_id)->toBe($class->id);
    expect($enrollment->status)->toBe('active');
});

it('does not create an enrollment when student has no class_id', function () {
    [, , ] = makeAyWithActiveSem();
    $admin = makeAdmin();

    $this->actingAs($admin)->post('/students', [
        'nis'  => '002',
        'name' => 'Orphan',
    ])->assertRedirect();

    expect(StudentClassEnrollment::count())->toBe(0);
});
```

- [ ] **Step 2: Run test, expect fail**

Run: `cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/StudentControllerEnrollmentTest.php --filter='creates an enrollment row'`
Expected: FAIL (no enrollment created)

- [ ] **Step 3: Patch `StudentController::store`**

Open `src/app/Http/Controllers/StudentController.php`. At the top of the file add:

```php
use App\Services\StudentEnrollmentSync;
```

Find the `store(Request $request)` method. After the line `$student = Student::create($validated);` add:

```php
        // Phase 1 — temporal tracking: write enrollment for active semester
        app(StudentEnrollmentSync::class)->syncCurrent($student, $student->class_id);
```

(The existing "Create User Account if requested" block stays untouched after this line.)

- [ ] **Step 4: Run test, expect pass**

Run: `cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/StudentControllerEnrollmentTest.php`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add src/app/Http/Controllers/StudentController.php src/tests/Feature/StudentEnrollment/StudentControllerEnrollmentTest.php
git commit -m "feat(students): create enrollment on student create"
```

---

## Task 6: Hook `StudentController::update` for class changes

**Files:**
- Modify: `src/app/Http/Controllers/StudentController.php`
- Test: `src/tests/Feature/StudentEnrollment/StudentControllerEnrollmentTest.php` (append)

- [ ] **Step 1: Append failing tests**

Append to `StudentControllerEnrollmentTest.php`:

```php
it('overwrites enrollment + records mutation when admin changes class_id mid-semester', function () {
    [$ay, $sem, $classA] = makeAyWithActiveSem();
    $classB = SchoolClass::create(['name' => '1B', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    $admin = makeAdmin();

    $this->actingAs($admin)->post('/students', [
        'nis'      => '003',
        'name'     => 'Andi',
        'class_id' => $classA->id,
    ])->assertRedirect();

    $student = Student::where('nis', '003')->first();

    $this->actingAs($admin)->put("/students/{$student->id}", [
        'nis'      => '003',
        'name'     => 'Andi',
        'class_id' => $classB->id,
        'status'   => 'active',
    ])->assertRedirect();

    $enrollment = StudentClassEnrollment::where('student_id', $student->id)
        ->where('semester_id', $sem->id)
        ->first();
    expect($enrollment->class_id)->toBe($classB->id);
    expect($enrollment->status)->toBe('active');

    // mutation row created
    $mutation = \App\Models\StudentMutation::where('student_id', $student->id)->first();
    expect($mutation)->not->toBeNull();
    expect($mutation->from_class_id)->toBe($classA->id);
    expect($mutation->to_class_id)->toBe($classB->id);
    expect($mutation->type)->toBe('transfer_in');
});

it('does not write a mutation if class_id is unchanged on update', function () {
    [, , $classA] = makeAyWithActiveSem();
    $admin = makeAdmin();

    $this->actingAs($admin)->post('/students', [
        'nis'      => '004',
        'name'     => 'Layen',
        'class_id' => $classA->id,
    ])->assertRedirect();

    $student = Student::where('nis', '004')->first();

    $this->actingAs($admin)->put("/students/{$student->id}", [
        'nis'      => '004',
        'name'     => 'Layen Updated',
        'class_id' => $classA->id,
        'status'   => 'active',
    ])->assertRedirect();

    expect(\App\Models\StudentMutation::count())->toBe(0);
});
```

- [ ] **Step 2: Run test, expect fail**

Run: `cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/StudentControllerEnrollmentTest.php --filter='overwrites enrollment'`
Expected: FAIL (no mutation row written; enrollment may or may not be updated depending on existing update logic)

- [ ] **Step 3: Patch `StudentController::update`**

Open `src/app/Http/Controllers/StudentController.php`. Add at top:

```php
use App\Models\StudentMutation;
```

In `update(Request $request, Student $student)`, capture old class_id BEFORE `$student->update($validated)`:

Replace this block:

```php
        $student->update($validated);
```

With:

```php
        $oldClassId = $student->class_id;
        $student->update($validated);

        // Phase 1 — temporal tracking: log mutation + sync enrollment if class changed mid-semester
        if (array_key_exists('class_id', $validated) && (int) $validated['class_id'] !== (int) $oldClassId) {
            StudentMutation::create([
                'student_id'    => $student->id,
                'type'          => 'transfer_in',
                'from_class_id' => $oldClassId,
                'to_class_id'   => $student->class_id,
                'date'          => now()->toDateString(),
                'reason'        => 'Pindah kelas (mid-semester admin edit)',
            ]);
            app(StudentEnrollmentSync::class)->syncCurrent($student, $student->class_id);
        }
```

- [ ] **Step 4: Run test, expect pass**

Run: `cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/StudentControllerEnrollmentTest.php`
Expected: PASS (all 4 tests)

- [ ] **Step 5: Commit**

```bash
git add src/app/Http/Controllers/StudentController.php src/tests/Feature/StudentEnrollment/StudentControllerEnrollmentTest.php
git commit -m "feat(students): log mutation + sync enrollment on class change"
```

---

## Task 7: Add `semester_id` filter + status badges to `StudentController::index`

**Files:**
- Modify: `src/app/Http/Controllers/StudentController.php`
- Test: `src/tests/Feature/StudentEnrollment/StudentControllerEnrollmentTest.php` (append)

- [ ] **Step 1: Append failing test**

```php
it('filters students by enrollment semester showing historical roster including non-active', function () {
    [, $semGanjil, $classA] = makeAyWithActiveSem();
    $admin = makeAdmin();

    // Two students enrolled in Sem Ganjil, classA
    $this->actingAs($admin)->post('/students', ['nis' => '101', 'name' => 'Stayed', 'class_id' => $classA->id]);
    $this->actingAs($admin)->post('/students', ['nis' => '102', 'name' => 'Pindah', 'class_id' => $classA->id]);

    $pindah = Student::where('nis', '102')->first();

    // Mark Pindah as transferred_out in this semester
    StudentClassEnrollment::where('student_id', $pindah->id)
        ->where('semester_id', $semGanjil->id)
        ->update(['status' => 'transferred_out', 'exit_date' => '2025-10-15']);

    // Index page should return both, filtered by semester_id
    $response = $this->actingAs($admin)->get("/students?semester_id={$semGanjil->id}");
    $response->assertOk();
    $data = $response->viewData('page')['props']['students']['data'];

    $names = collect($data)->pluck('name')->toArray();
    expect($names)->toContain('Stayed');
    expect($names)->toContain('Pindah');

    // Each row carries enrollment.status
    $pindahRow = collect($data)->firstWhere('name', 'Pindah');
    expect($pindahRow['enrollment_status'])->toBe('transferred_out');
});
```

- [ ] **Step 2: Run test, expect fail**

Run: `cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/StudentControllerEnrollmentTest.php --filter='filters students by enrollment semester'`
Expected: FAIL (`enrollment_status` key missing)

- [ ] **Step 3: Patch `StudentController::index`**

Open `src/app/Http/Controllers/StudentController.php`. Locate the `index(Request $request)` method. Replace the `$students = Student::query()...` chain with:

```php
        $semesterId = $request->integer('semester_id') ?: null;

        if ($semesterId) {
            // Historical roster: join enrollments, return all statuses
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
            // Current view (existing behavior, unchanged)
            $students = Student::query()
                ->with('class.academicYear:id,name,is_active')
                ->when($request->search, fn($q, $s) => $q->where(function ($qq) use ($s) {
                    $qq->where('name', 'like', "%{$s}%")
                       ->orWhere('nis', 'like', "%{$s}%");
                }))
                ->when($request->class_id, fn($q, $c) => $q->where('class_id', $c))
                ->when($request->status, fn($q, $s) => $q->where('status', $s))
                ->when($selectedAyId, fn($q, $ay) => $q->whereHas('class', fn($cq) => $cq->where('academic_year_id', $ay)))
                ->latest()
                ->paginate(20)
                ->withQueryString();
        }
```

Then update the `Inertia::render` call to also pass `semesters` and include `semester_id` in `filters`:

```php
        $semesters = $selectedAyId
            ? \App\Models\Semester::where('academic_year_id', $selectedAyId)->orderBy('semester_number')->get(['id', 'semester_number', 'is_active'])
            : collect();

        return Inertia::render('Students/Index', [
            'students'      => $students,
            'classes'       => $classes,
            'academicYears' => $academicYears,
            'semesters'     => $semesters,
            'filters'       => array_merge(
                $request->only(['search', 'class_id', 'status']),
                ['academic_year_id' => $selectedAyId, 'semester_id' => $semesterId]
            ),
        ]);
```

- [ ] **Step 4: Run test, expect pass**

Run: `cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/StudentControllerEnrollmentTest.php`
Expected: PASS (all 5 tests)

- [ ] **Step 5: Commit**

```bash
git add src/app/Http/Controllers/StudentController.php src/tests/Feature/StudentEnrollment/StudentControllerEnrollmentTest.php
git commit -m "feat(students): semester_id filter + enrollment status on index"
```

---

## Task 8: Eager-load enrollments on `StudentController::show`

**Files:**
- Modify: `src/app/Http/Controllers/StudentController.php`

- [ ] **Step 1: Edit show()**

Open `src/app/Http/Controllers/StudentController.php`. In `show(Student $student)`, modify the `$student->load([...])` call to include enrollments:

```php
        $student->load([
            'class.homeroomTeacher',
            'grades.subject',
            'grades.semester.academicYear',
            'reportCards',
            'mutations.fromClass',
            'mutations.toClass',
            'enrollments.semester.academicYear',
            'enrollments.schoolClass',
            'siblings.class',
        ]);
```

- [ ] **Step 2: Smoke-test by hitting show route in tinker**

```bash
cd src && php artisan tinker --execute='
$student = App\Models\Student::with(["enrollments.semester.academicYear", "enrollments.schoolClass"])->first();
if ($student) {
    foreach ($student->enrollments as $e) {
        echo $e->semester->semester_number . " " . $e->semester->academicYear->name . " - " . $e->schoolClass->name . " - " . $e->status . PHP_EOL;
    }
} else { echo "no students"; }
'
```
Expected: prints enrollments or "no students" without errors.

- [ ] **Step 3: Commit**

```bash
git add src/app/Http/Controllers/StudentController.php
git commit -m "feat(students): eager-load enrollments on show"
```

---

## Task 9: `EnrollmentCarryOverService::preview`

**Files:**
- Create: `src/app/Services/EnrollmentCarryOverService.php`
- Test: `src/tests/Feature/StudentEnrollment/EnrollmentCarryOverServiceTest.php`

- [ ] **Step 1: Write the failing test**

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

function makeAyWithTwoSemesters(): array {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem1 = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $sem2 = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 2, 'is_active' => false, 'start_date' => '2026-01-01', 'end_date' => '2026-06-30']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    return [$ay, $sem1, $sem2, $class];
}

it('preview lists active enrollments from previous semester and skips non-active ones', function () {
    [, $sem1, $sem2, $class] = makeAyWithTwoSemesters();

    $stay = Student::create(['nis' => '1', 'name' => 'Stay', 'class_id' => $class->id, 'status' => 'active']);
    $left = Student::create(['nis' => '2', 'name' => 'Left', 'class_id' => $class->id, 'status' => 'active']);

    StudentClassEnrollment::create(['student_id' => $stay->id, 'semester_id' => $sem1->id, 'class_id' => $class->id, 'status' => 'active']);
    StudentClassEnrollment::create(['student_id' => $left->id, 'semester_id' => $sem1->id, 'class_id' => $class->id, 'status' => 'transferred_out', 'exit_date' => '2025-10-01']);

    $svc = app(EnrollmentCarryOverService::class);
    $preview = $svc->preview($sem2->id);

    expect($preview['source_semester_id'])->toBe($sem1->id);
    expect($preview['target_semester_id'])->toBe($sem2->id);
    expect(count($preview['carry_over']))->toBe(1);
    expect($preview['carry_over'][0]['student_id'])->toBe($stay->id);
    expect(count($preview['skipped']))->toBe(1);
    expect($preview['skipped'][0]['student_id'])->toBe($left->id);
    expect($preview['skipped'][0]['reason'])->toContain('transferred_out');
});

it('preview returns empty result when no previous semester exists', function () {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem1 = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => false, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);

    $svc = app(EnrollmentCarryOverService::class);
    $preview = $svc->preview($sem1->id);

    expect($preview['source_semester_id'])->toBeNull();
    expect($preview['carry_over'])->toBe([]);
});
```

- [ ] **Step 2: Run test, expect fail**

Run: `cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/EnrollmentCarryOverServiceTest.php`
Expected: FAIL (class doesn't exist)

- [ ] **Step 3: Write the service (preview only for now)**

```php
<?php

namespace App\Services;

use App\Models\Semester;
use App\Models\StudentClassEnrollment;
use Illuminate\Support\Facades\DB;

class EnrollmentCarryOverService
{
    /**
     * Return a plan of which students would be carried into `$targetSemesterId`
     * from the previous semester in the same academic year, and which would be
     * skipped (status != active).
     *
     * Shape:
     * [
     *   'source_semester_id' => int|null,
     *   'target_semester_id' => int,
     *   'carry_over' => [ ['student_id' => int, 'name' => string, 'class_id' => int, 'class_name' => string], ... ],
     *   'skipped'    => [ ['student_id' => int, 'name' => string, 'reason' => string], ... ],
     * ]
     */
    public function preview(int $targetSemesterId): array
    {
        $target = Semester::findOrFail($targetSemesterId);

        $source = Semester::where('academic_year_id', $target->academic_year_id)
            ->where('semester_number', '<', $target->semester_number)
            ->orderByDesc('semester_number')
            ->first();

        if (! $source) {
            return [
                'source_semester_id' => null,
                'target_semester_id' => $targetSemesterId,
                'carry_over'         => [],
                'skipped'            => [],
            ];
        }

        $rows = StudentClassEnrollment::where('semester_id', $source->id)
            ->with(['student:id,name', 'schoolClass:id,name'])
            ->get();

        $carry = [];
        $skipped = [];
        foreach ($rows as $r) {
            if ($r->status === StudentClassEnrollment::STATUS_ACTIVE) {
                $carry[] = [
                    'student_id' => $r->student_id,
                    'name'       => $r->student->name ?? '—',
                    'class_id'   => $r->class_id,
                    'class_name' => $r->schoolClass->name ?? '—',
                ];
            } else {
                $skipped[] = [
                    'student_id' => $r->student_id,
                    'name'       => $r->student->name ?? '—',
                    'reason'     => "Status di semester sumber: {$r->status}",
                ];
            }
        }

        return [
            'source_semester_id' => $source->id,
            'target_semester_id' => $targetSemesterId,
            'carry_over'         => $carry,
            'skipped'            => $skipped,
        ];
    }
}
```

- [ ] **Step 4: Run test, expect pass**

Run: `cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/EnrollmentCarryOverServiceTest.php`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add src/app/Services/EnrollmentCarryOverService.php src/tests/Feature/StudentEnrollment/EnrollmentCarryOverServiceTest.php
git commit -m "feat(svc): EnrollmentCarryOverService::preview"
```

---

## Task 10: `EnrollmentCarryOverService::execute` (atomic, idempotent)

**Files:**
- Modify: `src/app/Services/EnrollmentCarryOverService.php`
- Test: `src/tests/Feature/StudentEnrollment/EnrollmentCarryOverServiceTest.php` (append)

- [ ] **Step 1: Append failing tests**

```php
it('execute creates enrollment rows for carry-over students and is idempotent', function () {
    [, $sem1, $sem2, $class] = makeAyWithTwoSemesters();
    $stay = Student::create(['nis' => '1', 'name' => 'Stay', 'class_id' => $class->id, 'status' => 'active']);
    StudentClassEnrollment::create(['student_id' => $stay->id, 'semester_id' => $sem1->id, 'class_id' => $class->id, 'status' => 'active']);

    $svc = app(EnrollmentCarryOverService::class);
    $result = $svc->execute($sem2->id);
    expect($result['carried'])->toBe(1);

    // Idempotent — second run is a no-op
    $result2 = $svc->execute($sem2->id);
    expect($result2['carried'])->toBe(0);

    expect(StudentClassEnrollment::where('semester_id', $sem2->id)->count())->toBe(1);
});

it('execute returns zero when no previous semester exists', function () {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem1 = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => false, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);

    $svc = app(EnrollmentCarryOverService::class);
    $result = $svc->execute($sem1->id);
    expect($result['carried'])->toBe(0);
    expect($result['source_semester_id'])->toBeNull();
});
```

- [ ] **Step 2: Run test, expect fail**

Run: `cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/EnrollmentCarryOverServiceTest.php --filter='execute'`
Expected: FAIL (no `execute` method)

- [ ] **Step 3: Implement `execute`**

Append to `EnrollmentCarryOverService.php` (inside the class):

```php
    /**
     * Atomically carry over active enrollments from the previous semester
     * into `$targetSemesterId`. Idempotent: existing rows are not duplicated.
     *
     * @return array{carried:int, skipped:int, source_semester_id:?int, target_semester_id:int}
     */
    public function execute(int $targetSemesterId): array
    {
        return DB::transaction(function () use ($targetSemesterId) {
            $plan = $this->preview($targetSemesterId);

            if ($plan['source_semester_id'] === null || empty($plan['carry_over'])) {
                return [
                    'carried'            => 0,
                    'skipped'            => count($plan['skipped']),
                    'source_semester_id' => $plan['source_semester_id'],
                    'target_semester_id' => $targetSemesterId,
                ];
            }

            $now = now();
            $rows = [];
            foreach ($plan['carry_over'] as $entry) {
                $rows[] = [
                    'student_id'  => $entry['student_id'],
                    'semester_id' => $targetSemesterId,
                    'class_id'    => $entry['class_id'],
                    'status'      => StudentClassEnrollment::STATUS_ACTIVE,
                    'created_at'  => $now,
                    'updated_at'  => $now,
                ];
            }

            $before = StudentClassEnrollment::where('semester_id', $targetSemesterId)->count();
            DB::table('student_class_enrollments')->insertOrIgnore($rows);
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

- [ ] **Step 4: Run test, expect pass**

Run: `cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/EnrollmentCarryOverServiceTest.php`
Expected: PASS (all 4 tests)

- [ ] **Step 5: Commit**

```bash
git add src/app/Services/EnrollmentCarryOverService.php src/tests/Feature/StudentEnrollment/EnrollmentCarryOverServiceTest.php
git commit -m "feat(svc): EnrollmentCarryOverService::execute atomic idempotent"
```

---

## Task 11: `SemesterController::activate` runs carry-over

**Files:**
- Modify: `src/app/Http/Controllers/SemesterController.php`
- Test: `src/tests/Feature/StudentEnrollment/SemesterActivationCarryOverTest.php`

- [ ] **Step 1: Write failing test**

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

it('activating a new semester carries over enrollments from previous semester', function () {
    $admin = User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem1 = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $sem2 = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 2, 'is_active' => false, 'start_date' => '2026-01-01', 'end_date' => '2026-06-30']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    $student = Student::create(['nis' => '1', 'name' => 'Stay', 'class_id' => $class->id, 'status' => 'active']);
    StudentClassEnrollment::create(['student_id' => $student->id, 'semester_id' => $sem1->id, 'class_id' => $class->id, 'status' => 'active']);

    $this->actingAs($admin)->post("/semesters/{$sem2->id}/activate")->assertRedirect();

    $sem2->refresh();
    expect($sem2->is_active)->toBeTrue();

    $newEnrollment = StudentClassEnrollment::where('student_id', $student->id)
        ->where('semester_id', $sem2->id)
        ->first();
    expect($newEnrollment)->not->toBeNull();
    expect($newEnrollment->class_id)->toBe($class->id);
    expect($newEnrollment->status)->toBe('active');
});
```

- [ ] **Step 2: Run test, expect fail**

Run: `cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/SemesterActivationCarryOverTest.php`
Expected: FAIL (no enrollment created in Sem 2)

- [ ] **Step 3: Patch `SemesterController::activate`**

Open `src/app/Http/Controllers/SemesterController.php`. Add at top:

```php
use App\Services\EnrollmentCarryOverService;
```

Modify `activate()`:

```php
    public function activate(Semester $semester): RedirectResponse
    {
        $this->authorize('activate', $semester);

        $result = DB::transaction(function () use ($semester) {
            Semester::where('academic_year_id', $semester->academic_year_id)
                ->update(['is_active' => false]);
            $semester->update(['is_active' => true]);

            return app(EnrollmentCarryOverService::class)->execute($semester->id);
        });

        $msg = "Semester {$semester->semester_number} sekarang aktif.";
        if ($result['carried'] > 0) {
            $msg .= " {$result['carried']} siswa di-carry-over dari semester sebelumnya.";
        }
        if ($result['skipped'] > 0) {
            $msg .= " {$result['skipped']} siswa di-skip (sudah keluar/lulus).";
        }

        return redirect()->route('academic-years.semesters.index', $semester->academic_year_id)
            ->with('success', $msg);
    }
```

- [ ] **Step 4: Run test, expect pass**

Run: `cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/SemesterActivationCarryOverTest.php`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/app/Http/Controllers/SemesterController.php src/tests/Feature/StudentEnrollment/SemesterActivationCarryOverTest.php
git commit -m "feat(semester): activate now triggers enrollment carry-over"
```

---

## Task 12: Hook `YearTransitionService` to write target-year enrollments

**Files:**
- Modify: `src/app/Services/YearTransitionService.php`
- Test: `src/tests/Feature/StudentEnrollment/YearTransitionEnrollmentTest.php`

- [ ] **Step 1: Write the failing test**

```php
<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\User;
use App\Services\YearTransitionService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('year transition writes promoted students enrollment in target year Sem Ganjil and closes source-year enrollment', function () {
    $admin = User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);

    $sourceAy = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $targetAy = AcademicYear::create(['name' => '2026/2027', 'is_active' => false, 'start_date' => '2026-07-01', 'end_date' => '2027-06-30']);

    $sourceSem2 = Semester::create(['academic_year_id' => $sourceAy->id, 'semester_number' => 2, 'is_active' => true, 'start_date' => '2026-01-01', 'end_date' => '2026-06-30']);
    $targetSem1 = Semester::create(['academic_year_id' => $targetAy->id, 'semester_number' => 1, 'is_active' => false, 'start_date' => '2026-07-01', 'end_date' => '2026-12-31']);

    $class1A = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $sourceAy->id, 'status' => 'active']);
    $student = Student::create(['nis' => '1', 'name' => 'Nathan', 'class_id' => $class1A->id, 'status' => 'active']);
    StudentClassEnrollment::create(['student_id' => $student->id, 'semester_id' => $sourceSem2->id, 'class_id' => $class1A->id, 'status' => 'active']);

    /** @var YearTransitionService $svc */
    $svc = app(YearTransitionService::class);
    $svc->executeTransition($sourceAy->id, $targetAy->id, [], $admin);

    // Source-year Sem 2 enrollment should be closed as promoted_out
    $sourceEnrollment = StudentClassEnrollment::where('student_id', $student->id)
        ->where('semester_id', $sourceSem2->id)
        ->first();
    expect($sourceEnrollment->status)->toBe('promoted_out');

    // Target-year Sem 1 enrollment should exist as active
    $targetEnrollment = StudentClassEnrollment::where('student_id', $student->id)
        ->where('semester_id', $targetSem1->id)
        ->first();
    expect($targetEnrollment)->not->toBeNull();
    expect($targetEnrollment->status)->toBe('active');
});
```

- [ ] **Step 2: Run test, expect fail**

Run: `cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/YearTransitionEnrollmentTest.php`
Expected: FAIL — source enrollment status not changed, target enrollment not created.

- [ ] **Step 3: Patch `YearTransitionService`**

Open `src/app/Services/YearTransitionService.php`. Add at top:

```php
use App\Services\StudentEnrollmentSync;
use App\Models\Semester;
use App\Models\StudentClassEnrollment;
```

In `applyPromotion`, after `StudentMutation::create([...])`:

```php
        $this->writeTransitionEnrollment(
            studentId: $student->id,
            sourceAcademicYearId: $mutation['source_ay_id'] ?? null,
            targetAcademicYearId: $mutation['target_ay_id'] ?? null,
            targetClassId: $newClass->id,
            sourceStatus: StudentClassEnrollment::STATUS_PROMOTED_OUT,
        );
```

In `applyRetention`, after `StudentMutation::create`:

```php
        $this->writeTransitionEnrollment(
            studentId: $student->id,
            sourceAcademicYearId: $mutation['source_ay_id'] ?? null,
            targetAcademicYearId: $mutation['target_ay_id'] ?? null,
            targetClassId: $newClass->id,
            sourceStatus: StudentClassEnrollment::STATUS_RETAINED_OUT,
        );
```

In `applyGraduation`, after `StudentMutation::create`:

```php
        $this->writeTransitionEnrollment(
            studentId: $student->id,
            sourceAcademicYearId: $mutation['source_ay_id'] ?? null,
            targetAcademicYearId: null,
            targetClassId: null,
            sourceStatus: StudentClassEnrollment::STATUS_GRADUATED,
        );
```

In `applyExit`, after `StudentMutation::create`:

```php
        $exitStatus = $mutation['action'] === 'dropout'
            ? StudentClassEnrollment::STATUS_DROPPED_OUT
            : StudentClassEnrollment::STATUS_TRANSFERRED_OUT;
        $this->writeTransitionEnrollment(
            studentId: $student->id,
            sourceAcademicYearId: $mutation['source_ay_id'] ?? null,
            targetAcademicYearId: null,
            targetClassId: null,
            sourceStatus: $exitStatus,
        );
```

Add this private method to the class:

```php
    /**
     * After year transition mutation is applied, close the source-AY terminal-semester
     * enrollment and (if applicable) open a new enrollment in target AY Sem Ganjil.
     */
    private function writeTransitionEnrollment(
        int $studentId,
        ?int $sourceAcademicYearId,
        ?int $targetAcademicYearId,
        ?int $targetClassId,
        string $sourceStatus,
    ): void {
        $sync = app(StudentEnrollmentSync::class);

        if ($sourceAcademicYearId) {
            $sync->closeLatestEnrollmentInAcademicYear(
                $studentId,
                $sourceAcademicYearId,
                $sourceStatus,
                'Year transition',
            );
        }

        if ($targetAcademicYearId && $targetClassId) {
            $targetSem1 = Semester::where('academic_year_id', $targetAcademicYearId)
                ->where('semester_number', 1)
                ->first();
            if ($targetSem1) {
                $sync->writeEnrollment(
                    studentId: $studentId,
                    semesterId: $targetSem1->id,
                    classId: $targetClassId,
                    status: StudentClassEnrollment::STATUS_ACTIVE,
                );
            }
        }
    }
```

Now ensure `previewTransition` injects `source_ay_id` and `target_ay_id` into each mutation array so `applyMutation` has access to them. Find the place in `previewTransition` where `$mutations[] = [...]` is built (look for `'student_id' => ...` followed by `'action' => ...`). Add `'source_ay_id' => $sourceAyId,` and `'target_ay_id' => $targetAyId,` to each mutation literal.

- [ ] **Step 4: Run test, expect pass**

Run: `cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/YearTransitionEnrollmentTest.php`
Expected: PASS

- [ ] **Step 5: Verify nothing else broke**

Run: `cd src && ./vendor/bin/pest tests/Feature/`
Expected: All existing tests still PASS.

- [ ] **Step 6: Commit**

```bash
git add src/app/Services/YearTransitionService.php src/tests/Feature/StudentEnrollment/YearTransitionEnrollmentTest.php
git commit -m "feat(year-transition): write enrollments on promotion/retention/exit"
```

---

## Task 13: `Students/Index.vue` — semester filter + status column

**Files:**
- Modify: `src/resources/js/Pages/Students/Index.vue`

- [ ] **Step 1: Add semester dropdown to filter section**

Open `src/resources/js/Pages/Students/Index.vue`.

In `defineProps`, add `semesters`:

```javascript
const props = defineProps({
  students: Object,
  classes: Array,
  academicYears: { type: Array, default: () => [] },
  semesters: { type: Array, default: () => [] },
  filters: Object,
});
```

After `const academicYearId = ref(props.filters.academic_year_id || '');` add:

```javascript
const semesterId = ref(props.filters.semester_id || '');
```

Update the watcher to include `semesterId`:

```javascript
watch([search, classId, status, academicYearId, semesterId], (newVals, oldVals) => {
  if (newVals[3] !== oldVals[3]) {
    classId.value = '';
    semesterId.value = '';
  }
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    router.get('/students', {
      search:            search.value,
      class_id:          classId.value,
      status:            status.value,
      academic_year_id:  academicYearId.value || undefined,
      semester_id:       semesterId.value || undefined,
    }, { preserveState: true, replace: true });
  }, 300);
});
```

In the template, find the filter row (`<!-- Filters -->`). After the Tahun Ajaran dropdown, add a Semester dropdown:

```html
      <div class="w-44">
        <FormSelect v-model="semesterId" label="Semester">
          <option value="">Semua</option>
          <option v-for="s in semesters" :key="s.id" :value="s.id">
            Semester {{ s.semester_number }}{{ s.is_active ? ' (Aktif)' : '' }}
          </option>
        </FormSelect>
      </div>
```

- [ ] **Step 2: Update status column to use enrollment_status when present**

Find the table row rendering `Status` column. Replace the badge cell with:

```html
              <td class="px-4 py-3">
                <Badge :color="statusColor(s.enrollment_status || s.status)">
                  {{ statusLabel(s.enrollment_status || s.status) }}
                </Badge>
                <span v-if="s.enrollment_exit_date" class="ml-1 text-[10px] text-slate-400">
                  ({{ new Date(s.enrollment_exit_date).toLocaleDateString('id-ID') }})
                </span>
              </td>
```

And extend the label/color maps:

```javascript
const statusColor = (s) => {
  if (s === 'active') return 'emerald';
  if (s === 'graduated') return 'blue';
  if (['transferred', 'transferred_out', 'dropped_out', 'dropout'].includes(s)) return 'amber';
  if (['promoted_out', 'retained_out'].includes(s)) return 'slate';
  return 'slate';
};

const statusLabel = (s) => ({
  active: 'Aktif',
  graduated: 'Lulus',
  transferred: 'Pindah',
  transferred_out: 'Pindah',
  dropout: 'Keluar',
  dropped_out: 'Keluar',
  promoted_out: 'Naik kelas',
  retained_out: 'Tinggal kelas',
}[s] || s);
```

- [ ] **Step 3: Build assets locally**

Run: `cd src && npm run build`
Expected: `✓ built`

- [ ] **Step 4: Manual smoke check (local dev)**

Open `http://localhost:8000/students` in browser. Verify Semester dropdown appears next to Tahun Ajaran. Select a semester → table updates. Filtering by semester shows all enrollment statuses with correct badges.

- [ ] **Step 5: Commit**

```bash
git add src/resources/js/Pages/Students/Index.vue
git commit -m "feat(ui): students index — semester filter + enrollment status badge"
```

---

## Task 14: `Students/Show.vue` Riwayat Kelas section

**Files:**
- Modify: `src/resources/js/Pages/Students/Tabs/StudentMutationTab.vue`

- [ ] **Step 1: Inspect existing tab to find insertion point**

Run: `head -80 src/resources/js/Pages/Students/Tabs/StudentMutationTab.vue`

Note the props it receives (typically `student` with relations).

- [ ] **Step 2: Add Riwayat Kelas section at top of the tab template**

Open `src/resources/js/Pages/Students/Tabs/StudentMutationTab.vue`. At the very top of the template, insert this section BEFORE the existing mutation list:

```html
    <!-- Riwayat Kelas (Phase 1 — temporal tracking) -->
    <div class="rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="border-b border-slate-100 px-6 py-4">
        <h3 class="text-sm font-semibold text-slate-700">Riwayat Kelas</h3>
        <p class="mt-0.5 text-xs text-slate-400">Penempatan kelas per semester</p>
      </div>
      <div v-if="!student.enrollments || student.enrollments.length === 0" class="px-6 py-8 text-center text-sm text-slate-400">
        Belum ada riwayat kelas
      </div>
      <table v-else class="w-full text-sm">
        <thead>
          <tr class="border-b border-slate-100 bg-slate-50/60">
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Tahun / Semester</th>
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Kelas</th>
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Status</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="e in sortedEnrollments" :key="e.id" class="border-b border-slate-100">
            <td class="px-4 py-2">{{ e.semester?.academic_year?.name }} — Sem {{ e.semester?.semester_number }}</td>
            <td class="px-4 py-2">{{ e.school_class?.name || '—' }}</td>
            <td class="px-4 py-2">
              <span class="text-xs font-medium">{{ enrollmentStatusLabel(e.status) }}</span>
              <span v-if="e.exit_date" class="ml-1 text-[10px] text-slate-400">({{ new Date(e.exit_date).toLocaleDateString('id-ID') }})</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
```

In the `<script setup>`, add:

```javascript
import { computed } from 'vue';

const sortedEnrollments = computed(() => {
  if (!props.student.enrollments) return [];
  return [...props.student.enrollments].sort((a, b) => {
    const ayA = a.semester?.academic_year?.start_date || '';
    const ayB = b.semester?.academic_year?.start_date || '';
    if (ayA !== ayB) return ayB.localeCompare(ayA);
    return (b.semester?.semester_number || 0) - (a.semester?.semester_number || 0);
  });
});

const enrollmentStatusLabel = (s) => ({
  active: 'Aktif',
  promoted_out: 'Selesai (Naik kelas)',
  retained_out: 'Selesai (Tinggal kelas)',
  graduated: 'Lulus',
  transferred_out: 'Pindah',
  dropped_out: 'Keluar',
}[s] || s);
```

- [ ] **Step 3: Update Eloquent serialization to use `school_class` snake-case key**

Inertia serializes relations by default. The `schoolClass` relation will serialise to `school_class`. Verify with tinker:

```bash
cd src && php artisan tinker --execute='
$s = App\Models\Student::with("enrollments.schoolClass")->first();
echo json_encode($s?->toArray()["enrollments"] ?? []);
'
```
Expected output: enrollments array entries contain `school_class` key.

- [ ] **Step 4: Build assets + smoke check**

Run: `cd src && npm run build`

Open `/students/<id>` in browser → click "Mutasi & Riwayat" tab → verify Riwayat Kelas section renders enrollments correctly.

- [ ] **Step 5: Commit**

```bash
git add src/resources/js/Pages/Students/Tabs/StudentMutationTab.vue
git commit -m "feat(ui): Riwayat Kelas section in StudentMutationTab"
```

---

## Task 15: Semester activation confirmation modal

**Files:**
- Create: `src/resources/js/Pages/Semesters/CarryOverConfirmModal.vue`
- Modify: `src/resources/js/Pages/Semesters/Index.vue`
- Modify: `src/app/Http/Controllers/SemesterController.php` (add JSON preview endpoint)
- Modify: `src/routes/web.php` (add preview route)

- [ ] **Step 1: Add preview route**

Open `src/routes/web.php`. Near the existing `Route::post('semesters/{semester}/activate', ...)`, add:

```php
        Route::get('semesters/{semester}/carry-over-preview', [SemesterController::class, 'carryOverPreview'])
            ->name('semesters.carry-over-preview');
```

- [ ] **Step 2: Implement preview endpoint**

Open `src/app/Http/Controllers/SemesterController.php`. Add method:

```php
    public function carryOverPreview(Semester $semester)
    {
        $this->authorize('activate', $semester);
        return response()->json(
            app(EnrollmentCarryOverService::class)->preview($semester->id)
        );
    }
```

- [ ] **Step 3: Write the modal component**

```vue
<script setup>
import { ref, watch } from 'vue';
import { router } from '@inertiajs/vue3';

const props = defineProps({
  show: Boolean,
  semester: Object,
});
const emit = defineEmits(['close']);

const loading = ref(false);
const preview = ref(null);

watch(() => props.show, async (val) => {
  if (val && props.semester) {
    loading.value = true;
    try {
      const res = await fetch(`/semesters/${props.semester.id}/carry-over-preview`);
      preview.value = await res.json();
    } finally {
      loading.value = false;
    }
  } else {
    preview.value = null;
  }
});

const confirm = () => {
  router.post(`/semesters/${props.semester.id}/activate`, {}, {
    onFinish: () => emit('close'),
  });
};
</script>

<template>
  <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="w-full max-w-2xl rounded-xl bg-white shadow-xl">
      <div class="border-b border-slate-100 px-6 py-4">
        <h3 class="text-base font-semibold text-slate-800">Aktivasi Semester {{ semester?.semester_number }}</h3>
      </div>
      <div class="max-h-[60vh] overflow-y-auto px-6 py-5 text-sm">
        <div v-if="loading" class="text-center text-slate-400">Memuat preview…</div>
        <template v-else-if="preview">
          <p v-if="preview.source_semester_id" class="mb-4 text-slate-600">
            <strong>{{ preview.carry_over.length }}</strong> siswa akan di-carry-over ke semester ini.
            <span v-if="preview.skipped.length">
              <strong>{{ preview.skipped.length }}</strong> siswa di-skip (sudah keluar/lulus).
            </span>
          </p>
          <p v-else class="mb-4 text-slate-600">Tidak ada semester sebelumnya. Tidak ada carry-over.</p>

          <div v-if="preview.carry_over.length" class="mb-4">
            <h4 class="mb-1 text-xs font-semibold uppercase text-slate-500">Akan di-carry-over</h4>
            <ul class="space-y-1">
              <li v-for="row in preview.carry_over" :key="row.student_id" class="text-slate-700">
                {{ row.name }} — {{ row.class_name }}
              </li>
            </ul>
          </div>
          <div v-if="preview.skipped.length">
            <h4 class="mb-1 text-xs font-semibold uppercase text-slate-500">Di-skip</h4>
            <ul class="space-y-1">
              <li v-for="row in preview.skipped" :key="row.student_id" class="text-slate-600">
                {{ row.name }} — {{ row.reason }}
              </li>
            </ul>
          </div>
        </template>
      </div>
      <div class="flex justify-end gap-2 border-t border-slate-100 bg-slate-50/60 px-6 py-3">
        <button @click="emit('close')" class="rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-50">Batal</button>
        <button @click="confirm" :disabled="loading" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-50">
          Aktifkan & Carry-Over
        </button>
      </div>
    </div>
  </div>
</template>
```

- [ ] **Step 4: Wire modal into `Semesters/Index.vue`**

Open `src/resources/js/Pages/Semesters/Index.vue`. Add import + modal:

```javascript
import CarryOverConfirmModal from './CarryOverConfirmModal.vue';
import { ref } from 'vue';

const showModal = ref(false);
const targetSemester = ref(null);

const openActivateModal = (semester) => {
  targetSemester.value = semester;
  showModal.value = true;
};
```

In the template, replace the existing "Aktifkan" button (or `<form>` submitting to `/semesters/{id}/activate`) with:

```html
<button @click="openActivateModal(s)" class="...">Aktifkan</button>
```

And below the existing template, add:

```html
<CarryOverConfirmModal :show="showModal" :semester="targetSemester" @close="showModal = false" />
```

- [ ] **Step 5: Build + smoke test**

```bash
cd src && npm run build
```

Open the semesters page in browser → click Aktifkan on an inactive semester → modal renders preview → confirm → semester activates + enrollments carry over.

- [ ] **Step 6: Commit**

```bash
git add src/resources/js/Pages/Semesters/CarryOverConfirmModal.vue \
        src/resources/js/Pages/Semesters/Index.vue \
        src/app/Http/Controllers/SemesterController.php \
        src/routes/web.php
git commit -m "feat(ui): carry-over confirmation modal on semester activation"
```

---

## Task 16: Run full test suite, then deploy to production

**Files:** (deploy only — no code changes)

- [ ] **Step 1: Run full test suite**

Run: `cd src && ./vendor/bin/pest`
Expected: All tests PASS. If any pre-existing test fails (not enrollment-related), investigate.

- [ ] **Step 2: Build production assets**

```bash
cd src && npm run build
```
Expected: Vite build succeeds.

- [ ] **Step 3: Copy controllers + models + services to production**

```bash
SRC=/Users/tokaf/Floz_SDN_KELAPADUA_IV/src
SERVER=sdnkelap@tarsius.kencang.com
KEY=~/.ssh/floz_cpanel

scp -i "$KEY" \
  "$SRC/app/Models/StudentClassEnrollment.php" \
  "$SRC/app/Models/Student.php" \
  "$SRC/app/Models/SchoolClass.php" \
  "$SRC/app/Models/Semester.php" \
  "$SERVER:/home/sdnkelap/floz/app/Models/"

scp -i "$KEY" \
  "$SRC/app/Services/StudentEnrollmentSync.php" \
  "$SRC/app/Services/EnrollmentCarryOverService.php" \
  "$SRC/app/Services/YearTransitionService.php" \
  "$SERVER:/home/sdnkelap/floz/app/Services/"

scp -i "$KEY" \
  "$SRC/app/Http/Controllers/StudentController.php" \
  "$SRC/app/Http/Controllers/SemesterController.php" \
  "$SERVER:/home/sdnkelap/floz/app/Http/Controllers/"

scp -i "$KEY" "$SRC/routes/web.php" "$SERVER:/home/sdnkelap/floz/routes/"

scp -i "$KEY" \
  "$SRC/database/migrations/2026_05_14_180000_create_student_class_enrollments_table.php" \
  "$SRC/database/migrations/2026_05_14_180001_backfill_student_class_enrollments.php" \
  "$SERVER:/home/sdnkelap/floz/database/migrations/"
```

- [ ] **Step 4: Tar + scp built Vite assets**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/public/build
tar -czf /tmp/floz-build.tgz .
scp -i ~/.ssh/floz_cpanel /tmp/floz-build.tgz sdnkelap@tarsius.kencang.com:/tmp/
```

- [ ] **Step 5: Run migrations + rebuild caches on server**

```bash
ssh -i ~/.ssh/floz_cpanel sdnkelap@tarsius.kencang.com 'bash -s' <<'SH'
set -e
cd ~/floz
php artisan migrate --force
rm -rf public/build/*
tar -xzf /tmp/floz-build.tgz -C public/build
rm /tmp/floz-build.tgz
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "== Verify enrollments backfilled =="
php artisan tinker --execute='echo App\Models\StudentClassEnrollment::count() . " enrollment rows" . PHP_EOL;'
SH
```

Expected: migrations run, backfill creates enrollment rows for existing active students, caches rebuilt, count printed.

- [ ] **Step 6: Smoke test on production**

Open https://sdnkelapaduaiv.my.id/students in browser. Verify:
1. Filter "Semester" dropdown appears.
2. Selecting a semester filters the roster.
3. Open a student → Mutasi & Riwayat tab → Riwayat Kelas list shows the active enrollment.
4. Aktivasi Semester button on Semester index opens carry-over confirmation modal.

- [ ] **Step 7: Final commit (only if there are any deploy-related changes; otherwise skip)**

If everything passes, no further commits are needed; previous tasks already committed.

---

## Self-Review Notes

### Spec coverage check

| Spec section | Implementing task(s) |
|---|---|
| §1 Data Model — `student_class_enrollments` table | Task 1, Task 2 |
| §1 Source-of-truth rules | Tasks 4, 5, 6 (controller hooks keep `students.class_id` synced) |
| §2.1 Student created | Task 5 |
| §2.2 Student moved mid-semester | Task 6 |
| §2.3 Student exits | Out of Phase 1 admin scope (no admin UI yet); covered by year transition path in Task 12 |
| §2.4 Semester activation carry-over | Tasks 9–11 |
| §2.5 Year transition | Task 12 |
| §2.6 Backfill | Task 3 |
| §3.1 Students Index semester filter | Tasks 7, 13 |
| §3.2 Students Show Riwayat Kelas | Tasks 8, 14 |
| §3.3 Semester activation modal | Task 15 |
| §4.1 Migrations | Tasks 1, 3 |
| §4.2 Controller / service changes | Tasks 4–12 |
| §4.3 Edge cases | Covered by tests in Tasks 3, 5, 6, 7, 9, 10, 11, 12 |
| §5 Acceptance criteria | Tasks 1–16 |

### Known deviations from spec

- Spec §2.3 (admin mid-semester exit via student edit) is **deferred**: no admin UI currently exposes status-change-with-exit-date, so wiring in Phase 1 would be speculative. Year-transition path (Task 12) covers the exit statuses. Add to Phase 3 if a UI for mid-semester exits is needed.
- Spec mentions the "Mutasi & Riwayat" tab as the home for Riwayat Kelas (Task 14). Confirmed by inspecting `Students/Show.vue` — the tab already exists.

### Notes for the executing agent

- Use `cd src` before every `php artisan` / `./vendor/bin/pest` / `npm run build` — the Laravel project lives in `src/`, not the repo root.
- Production server has no `rsync` and no `node`/`npm` — Vite must be built locally then tar+scp'd. See Task 16 for the exact deploy commands.
- The deployed branch is `chore/mysql-compat`. All commits in this plan should land there until the branch merges to `main`.
- MySQL/MariaDB compatibility: do not use `jsonb()` (use `json()`), always cast FK columns to integer in model `$casts`, and ensure every FK column has a backing index. The migration in Task 1 already follows these rules.
