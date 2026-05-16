# Plan: Phase 7 — School-Year Transition & Student Promotion Flow

## Goal

Build a 5-step admin wizard (`/year-transition`) that automates the annual Indonesian SD kenaikan kelas process: auto-generating new-AY class structure, classifying each student's disposition (promote/graduate/retain), previewing all mutations as a dry-run, then executing atomically in a single DB transaction with a full audit log. All historical class, grade, attendance, and report-card records are preserved intact; only `students.class_id` is re-pointed.

---

## Locked Decisions

1. **Class creation:** Auto-generate new-AY classes by copying prior-AY grade structure (`grade_level` + `name`). `homeroom_teacher_id` left NULL — admin must assign explicitly.
2. **TA rebuild:** NO auto-copy. Admin uses existing `/teaching-assignments` page. "Import TAs from prior year" deferred to Phase 7.5.
3. **Promotion logic:** Re-point `students.class_id` to corresponding next-grade class in new AY. Insert `StudentMutation(type='promotion')`. Old-AY class records preserved intact — never deleted.
4. **Graduation (Kelas 6):** Set `students.status='graduated'`, `students.class_id=NULL`. Insert `StudentMutation(type='graduated')`. Historical grades/attendance/report cards remain on old class.
5. **Retention:** Admin flags students "tinggal kelas" before confirm. Re-point `class_id` to new-AY class of the **same** grade. Insert `StudentMutation(type='retention')`.
6. **Dry-run mandatory:** Step 4 shows full per-student mutation table. Step 5 requires typing "TERAPKAN" to execute.
7. **Atomicity:** All mutations in single `DB::transaction`. Any exception → full rollback, no partial state.
8. **Semester activation timing:** `Semester::is_active=true` flip is the LAST step inside the transaction, after all `class_id` re-points are committed.
9. **Audit trail:** Every execution writes one `YearTransitionLog` row: actor ID, timestamp, source/target AY IDs, mutation counts by type, full JSON snapshot of dry-run plan.
10. **Reversibility:** No undo UI. Full snapshot stored in `YearTransitionLog.plan_snapshot` (JSON) for manual restore by developer if needed. Documented in UI: "Proses ini tidak dapat dibatalkan secara otomatis."

---

## Wizard UX Spec (Bahasa Indonesia)

**Step 1 — Pilih Tahun Ajaran**
- Label: "Dari Tahun Ajaran" (default: tahun ajaran aktif)
- Label: "Ke Tahun Ajaran Baru" — dropdown of existing AYs OR inline create fields (nama, tanggal mulai, tanggal selesai)
- Warning box: "Data tahun ajaran lama tidak akan dihapus. Proses ini hanya akan memindahkan siswa ke kelas baru."
- Button: "Lanjutkan →"

**Step 2 — Struktur Kelas Baru**
- Tabel: daftar kelas yang akan dibuat di tahun ajaran target, diambil dari struktur tahun sumber (kolom: Nama Kelas, Tingkat, Wali Kelas)
- Kolom Wali Kelas: "(Belum ditentukan)" — hanya bisa diisi setelah proses selesai
- Admin dapat mengedit nama kelas atau menghapus kelas yang tidak diperlukan
- Info: "Kelas 1 untuk siswa baru (PPDB) perlu dibuat terpisah setelah proses ini."
- Button: "Lanjutkan →"

**Step 3 — Review Per Siswa**
- Tabel semua siswa aktif di tahun ajaran sumber, dikelompokkan per kelas
- Kolom: Nama Siswa | NIS | Kelas Asal | Tindakan Default | Alasan
- Tindakan default:
  - Grade 1–5: "Naik Kelas" (promote)
  - Grade 6: "Lulus" (graduated)
- Admin dapat mengubah per-siswa ke: Naik Kelas / Mengulang / Mutasi Keluar / Putus Sekolah
- Siswa dengan status `transferred` atau `dropout` sudah dikeluarkan dari daftar (pre-filtered)
- Warning badge: siswa dengan mutasi pindah masuk (transfer_in) mid-year → "Perlu konfirmasi"
- Button: "Buat Preview →"

**Step 4 — Preview Mutasi (Dry Run)**
- Summary cards: X Naik Kelas | Y Lulus | Z Mengulang | W Dikecualikan
- Tabel detail: setiap siswa + tindakan yang akan dijalankan
- Tombol: "Unduh Rencana (JSON)"
- Alert: "Belum ada perubahan data. Klik Konfirmasi untuk menerapkan."
- Button: "Lanjutkan ke Konfirmasi →"

**Step 5 — Konfirmasi & Terapkan**
- Ringkasan akhir (jumlah per tindakan)
- Warning merah: "Proses ini tidak dapat dibatalkan secara otomatis. Pastikan data sudah benar."
- Input: ketik kata "TERAPKAN" untuk mengaktifkan tombol konfirmasi
- Button (disabled until TERAPKAN typed): "Konfirmasi & Terapkan Transisi"
  <!-- L-08 NOTE: Implementation uses "Konfirmasi & Terapkan Transisi" which is idiomatic
       Bahasa Indonesia and kept as-is. Spec label was loosely worded; implementation is correct. -->
- Setelah berhasil: redirect ke `/year-transition/logs` dengan flash success

---

## Service Contract (`YearTransitionService`)

```php
/**
 * Build full mutation plan without writing to DB.
 *
 * @param int $sourceAyId
 * @param int $targetAyId
 * @param array $overrides  [student_id => ['action' => 'promote|graduate|retain|transfer_out|dropout', 'reason' => string]]
 * @return array {
 *   source_ay: AcademicYear,
 *   target_ay: AcademicYear,
 *   new_classes: SchoolClass[],          // to be created (not yet persisted)
 *   mutations: array[]{
 *     student_id, student_name, nis,
 *     from_class_id, from_class_name, from_grade_level,
 *     action,                             // promote|graduate|retain|transfer_out|dropout
 *     to_class_id|null,                   // null for graduated/transfer_out/dropout
 *     to_class_name|null,
 *     reason|null,
 *     warnings: string[]                  // e.g. 'transfer_in mid-year'
 *   },
 *   summary: { promoted: int, graduated: int, retained: int, excluded: int },
 * }
 */
public function previewTransition(int $sourceAyId, int $targetAyId, array $overrides): array;

/**
 * Execute transition atomically. Returns audit log row.
 *
 * @throws \RuntimeException on any partial failure (triggers rollback)
 */
public function executeTransition(
    int $sourceAyId,
    int $targetAyId,
    array $overrides,
    User $admin
): YearTransitionLog;

/**
 * Phase 7.1 — not implemented. Placeholder for undo UI.
 * Snapshot stored in YearTransitionLog::plan_snapshot.
 */
public function restoreFromLog(YearTransitionLog $log, User $admin): void;
```

---

## Endpoints

| Method | URI | Purpose |
|--------|-----|---------|
| GET | `/year-transition` | Wizard root (Inertia, Step 1) |
| POST | `/year-transition/preview` | Returns JSON dry-run plan (no DB writes) |
| POST | `/year-transition/execute` | Commits transition, returns `{ log_id }` |
| GET | `/year-transition/logs` | History list (Inertia) |
| GET | `/year-transition/logs/{log}` | Single log detail (Inertia) |

All routes: `auth` middleware + `can:manage_year_transition` gate check.

---

## Tasks (TDD, step-by-step)

---

### Task 1: Migration + Model + Factory for `YearTransitionLog`

**Files created:**
- `src/database/migrations/2026_05_08_000001_create_year_transition_logs_table.php`
- `src/app/Models/YearTransitionLog.php`
- `src/database/factories/YearTransitionLogFactory.php`
- `src/tests/Unit/Models/YearTransitionLogTest.php`

**Migration SQL:**

```php
Schema::create('year_transition_logs', function (Blueprint $table) {
    $table->id();
    $table->foreignId('executed_by')->constrained('users')->restrictOnDelete();
    $table->foreignId('source_academic_year_id')->constrained('academic_years')->restrictOnDelete();
    $table->foreignId('target_academic_year_id')->constrained('academic_years')->restrictOnDelete();
    $table->timestamp('executed_at');
    $table->integer('promoted_count')->default(0);
    $table->integer('graduated_count')->default(0);
    $table->integer('retained_count')->default(0);
    $table->integer('excluded_count')->default(0);
    $table->json('plan_snapshot');  // full dry-run plan for manual restore reference
    $table->string('ip_address', 45)->nullable();
    $table->timestamps();
});
```

**Model (`YearTransitionLog.php`):**

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class YearTransitionLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'executed_by', 'source_academic_year_id', 'target_academic_year_id',
        'executed_at', 'promoted_count', 'graduated_count',
        'retained_count', 'excluded_count', 'plan_snapshot', 'ip_address',
    ];

    protected $casts = [
        'executed_at'    => 'datetime',
        'plan_snapshot'  => 'array',
    ];

    public function executor(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(User::class, 'executed_by');
    }

    public function sourceAcademicYear(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(AcademicYear::class, 'source_academic_year_id');
    }

    public function targetAcademicYear(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(AcademicYear::class, 'target_academic_year_id');
    }

    public function totalMutations(): int
    {
        return $this->promoted_count + $this->graduated_count + $this->retained_count;
    }
}
```

**Factory:**

```php
<?php

namespace Database\Factories;

use App\Models\AcademicYear;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class YearTransitionLogFactory extends Factory
{
    public function definition(): array
    {
        return [
            'executed_by'              => User::factory(),
            'source_academic_year_id'  => AcademicYear::factory(),
            'target_academic_year_id'  => AcademicYear::factory(),
            'executed_at'              => now(),
            'promoted_count'           => $this->faker->numberBetween(10, 30),
            'graduated_count'          => $this->faker->numberBetween(0, 10),
            'retained_count'           => $this->faker->numberBetween(0, 3),
            'excluded_count'           => 0,
            'plan_snapshot'            => ['mutations' => [], 'summary' => []],
            'ip_address'               => $this->faker->ipv4(),
        ];
    }
}
```

**Unit test (`YearTransitionLogTest.php`):**

```php
<?php

use App\Models\YearTransitionLog;
use App\Models\AcademicYear;
use App\Models\User;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

it('creates a log with correct relationships', function () {
    $log = YearTransitionLog::factory()->create([
        'promoted_count'  => 20,
        'graduated_count' => 5,
        'retained_count'  => 2,
    ]);

    expect($log->executor)->toBeInstanceOf(User::class);
    expect($log->sourceAcademicYear)->toBeInstanceOf(AcademicYear::class);
    expect($log->targetAcademicYear)->toBeInstanceOf(AcademicYear::class);
});

it('totalMutations sums promoted + graduated + retained', function () {
    $log = new YearTransitionLog([
        'promoted_count'  => 20,
        'graduated_count' => 5,
        'retained_count'  => 2,
        'excluded_count'  => 1,
    ]);

    expect($log->totalMutations())->toBe(27);
});

it('casts plan_snapshot as array', function () {
    $log = YearTransitionLog::factory()->create([
        'plan_snapshot' => ['mutations' => [['student_id' => 1, 'action' => 'promote']]],
    ]);

    expect($log->fresh()->plan_snapshot)->toBeArray();
    expect($log->fresh()->plan_snapshot['mutations'][0]['action'])->toBe('promote');
});
```

**Commit:** `feat(phase7): YearTransitionLog migration, model, factory, unit tests`

---

### Task 2: `YearTransitionService::previewTransition` (TDD)

**Files created:**
- `src/app/Services/YearTransitionService.php` (preview method only)
- `src/tests/Unit/Services/YearTransitionServiceTest.php`

**Step 1 — Write failing tests first:**

```php
<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\StudentMutation;
use App\Services\YearTransitionService;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

// ── helpers ───────────────────────────────────────────────────────────

function makeAY(string $name, bool $active = false): AcademicYear
{
    return AcademicYear::factory()->create([
        'name'      => $name,
        'is_active' => $active,
        'start_date'=> '2025-07-14',
        'end_date'  => '2026-06-19',
    ]);
}

function makeClass(AcademicYear $ay, int $grade, string $name): SchoolClass
{
    return SchoolClass::factory()->create([
        'academic_year_id'    => $ay->id,
        'grade_level'         => $grade,
        'name'                => $name,
        'homeroom_teacher_id' => null,
    ]);
}

function makeStudents(SchoolClass $class, int $count): \Illuminate\Database\Eloquent\Collection
{
    return Student::factory()->count($count)->create([
        'class_id' => $class->id,
        'status'   => 'active',
    ]);
}

// ── preview: basic structure ──────────────────────────────────────────

it('preview returns expected top-level keys', function () {
    $sourceAy = makeAY('2025/2026', true);
    $targetAy = makeAY('2026/2027');
    $class1a  = makeClass($sourceAy, 1, 'Kelas 1A');
    makeStudents($class1a, 3);

    $service = new YearTransitionService();
    $result  = $service->previewTransition($sourceAy->id, $targetAy->id, []);

    expect($result)->toHaveKeys(['source_ay', 'target_ay', 'new_classes', 'mutations', 'summary']);
});

// ── preview: class mirroring ──────────────────────────────────────────

it('preview generates one new target class per source class', function () {
    $sourceAy = makeAY('2025/2026', true);
    $targetAy = makeAY('2026/2027');
    makeClass($sourceAy, 1, 'Kelas 1A');
    makeClass($sourceAy, 1, 'Kelas 1B');
    makeClass($sourceAy, 2, 'Kelas 2A');

    $service = new YearTransitionService();
    $result  = $service->previewTransition($sourceAy->id, $targetAy->id, []);

    // 3 source classes → 3 new classes (no DB write yet)
    expect($result['new_classes'])->toHaveCount(3);
    expect(collect($result['new_classes'])->pluck('name')->toArray())
        ->toContain('Kelas 1A', 'Kelas 1B', 'Kelas 2A');
});

// ── preview: 30 students, promotion + graduation + retention ──────────

it('preview correctly classifies 30 students across grades with overrides', function () {
    $sourceAy = makeAY('2025/2026', true);
    $targetAy = makeAY('2026/2027');

    // 20 grade-5 students → default promote
    $class5a  = makeClass($sourceAy, 5, 'Kelas 5A');
    $promoted = makeStudents($class5a, 20);

    // 5 grade-6 students → default graduate
    $class6a   = makeClass($sourceAy, 6, 'Kelas 6A');
    $graduates = makeStudents($class6a, 5);

    // 5 grade-4 students, 2 flagged as retention via overrides
    $class4a  = makeClass($sourceAy, 4, 'Kelas 4A');
    $grade4s  = makeStudents($class4a, 5);
    $retainedIds = $grade4s->take(2)->pluck('id')->toArray();

    $overrides = collect($retainedIds)
        ->mapWithKeys(fn ($id) => [$id => ['action' => 'retain', 'reason' => 'Nilai tidak memenuhi KKM']])
        ->toArray();

    $service = new YearTransitionService();
    $result  = $service->previewTransition($sourceAy->id, $targetAy->id, $overrides);

    expect($result['summary']['promoted'])->toBe(23);  // 20 grade-5 + 3 remaining grade-4
    expect($result['summary']['graduated'])->toBe(5);
    expect($result['summary']['retained'])->toBe(2);
    expect($result['summary']['excluded'])->toBe(0);
    expect($result['mutations'])->toHaveCount(30);
});

// ── preview: transferred-out students are excluded ────────────────────

it('preview excludes students with status transferred or dropout', function () {
    $sourceAy = makeAY('2025/2026', true);
    $targetAy = makeAY('2026/2027');
    $class3a  = makeClass($sourceAy, 3, 'Kelas 3A');

    // 5 active, 1 transferred, 1 dropout
    makeStudents($class3a, 5);
    Student::factory()->create(['class_id' => $class3a->id, 'status' => 'transferred']);
    Student::factory()->create(['class_id' => $class3a->id, 'status' => 'dropout']);

    $service = new YearTransitionService();
    $result  = $service->previewTransition($sourceAy->id, $targetAy->id, []);

    expect($result['summary']['excluded'])->toBe(2);
    expect($result['mutations'])->toHaveCount(5);  // only active students
});

// ── preview: grade-6 override to retain (extraordinary case) ─────────

it('preview allows grade-6 student to be marked retain via override', function () {
    $sourceAy = makeAY('2025/2026', true);
    $targetAy = makeAY('2026/2027');
    $class6a  = makeClass($sourceAy, 6, 'Kelas 6A');
    $student  = Student::factory()->create(['class_id' => $class6a->id, 'status' => 'active']);

    $overrides = [$student->id => ['action' => 'retain', 'reason' => 'Keputusan kepala sekolah']];

    $service = new YearTransitionService();
    $result  = $service->previewTransition($sourceAy->id, $targetAy->id, $overrides);

    $mutation = collect($result['mutations'])->firstWhere('student_id', $student->id);
    expect($mutation['action'])->toBe('retain');
    expect($result['summary']['graduated'])->toBe(0);
    expect($result['summary']['retained'])->toBe(1);
});

// ── preview: transfer_in mid-year triggers warning ────────────────────

it('preview flags transfer_in students with a warning', function () {
    $sourceAy = makeAY('2025/2026', true);
    $targetAy = makeAY('2026/2027');
    $class2a  = makeClass($sourceAy, 2, 'Kelas 2A');
    $student  = Student::factory()->create(['class_id' => $class2a->id, 'status' => 'active']);

    // Mid-year transfer_in mutation exists
    StudentMutation::factory()->create([
        'student_id'  => $student->id,
        'type'        => 'transfer_in',
        'to_class_id' => $class2a->id,
        'date'        => now()->subMonths(3),
    ]);

    $service = new YearTransitionService();
    $result  = $service->previewTransition($sourceAy->id, $targetAy->id, []);

    $mutation = collect($result['mutations'])->firstWhere('student_id', $student->id);
    expect($mutation['warnings'])->toContain('transfer_in mid-year — konfirmasi manual diperlukan');
});

// ── preview: no DB writes occur ───────────────────────────────────────

it('preview does not write any DB rows', function () {
    $sourceAy = makeAY('2025/2026', true);
    $targetAy = makeAY('2026/2027');
    $class5a  = makeClass($sourceAy, 5, 'Kelas 5A');
    makeStudents($class5a, 5);

    $studentCountBefore  = Student::count();
    $mutationCountBefore = StudentMutation::count();
    $classCountBefore    = SchoolClass::count();

    $service = new YearTransitionService();
    $service->previewTransition($sourceAy->id, $targetAy->id, []);

    expect(Student::count())->toBe($studentCountBefore);
    expect(StudentMutation::count())->toBe($mutationCountBefore);
    expect(SchoolClass::count())->toBe($classCountBefore);
});
```

**Step 2 — Implement `YearTransitionService::previewTransition`:**

```php
<?php

namespace App\Services;

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\StudentMutation;
use App\Models\User;
use App\Models\YearTransitionLog;
use Illuminate\Support\Facades\DB;

class YearTransitionService
{
    /**
     * Promotion destination grade map.
     * Grade 6 has no next grade within SD — handled separately (graduate).
     */
    private const GRADE_STEP = [1 => 2, 2 => 3, 3 => 4, 4 => 5, 5 => 6];

    public function previewTransition(int $sourceAyId, int $targetAyId, array $overrides): array
    {
        $sourceAy = AcademicYear::findOrFail($sourceAyId);
        $targetAy = AcademicYear::findOrFail($targetAyId);

        // Build new-class map: source class → proposed new class (not persisted)
        $sourceClasses = SchoolClass::where('academic_year_id', $sourceAyId)->get();
        $newClasses = $sourceClasses->map(fn ($c) => [
            'source_class_id' => $c->id,
            'name'            => $c->name,
            'grade_level'     => $c->grade_level,
            'homeroom_teacher_id' => null,
        ])->toArray();

        // All active students in source AY (via their class)
        $students = Student::whereIn('class_id', $sourceClasses->pluck('id'))
            ->whereIn('status', ['active'])
            ->with(['class', 'mutations' => fn ($q) => $q->where('type', 'transfer_in')])
            ->get();

        // Students excluded (transferred/dropout already resolved)
        $excludedStudents = Student::whereIn('class_id', $sourceClasses->pluck('id'))
            ->whereIn('status', ['transferred', 'dropout'])
            ->get();

        $mutations = [];
        $summary   = ['promoted' => 0, 'graduated' => 0, 'retained' => 0, 'excluded' => 0];

        foreach ($students as $student) {
            $grade    = $student->class->grade_level;
            $override = $overrides[$student->id] ?? null;
            $action   = $override['action'] ?? ($grade === 6 ? 'graduate' : 'promote');
            $reason   = $override['reason'] ?? null;
            $warnings = [];

            // Flag mid-year transfer-in students
            if ($student->mutations->isNotEmpty()) {
                $warnings[] = 'transfer_in mid-year — konfirmasi manual diperlukan';
            }

            // Determine target class name
            $toClassName = null;
            $toClassId   = null;
            if ($action === 'promote') {
                $nextGrade   = self::GRADE_STEP[$grade] ?? null;
                $toClassName = $nextGrade ? $student->class->name : null;
                // class_id will be resolved during execute against newly-created classes
            } elseif ($action === 'retain') {
                $toClassName = $student->class->name; // same grade, same class name in new AY
            }
            // graduate/transfer_out/dropout → to_class = null

            $mutations[] = [
                'student_id'      => $student->id,
                'student_name'    => $student->name,
                'nis'             => $student->nis,
                'from_class_id'   => $student->class_id,
                'from_class_name' => $student->class->name,
                'from_grade_level'=> $grade,
                'action'          => $action,
                'to_class_name'   => $toClassName,
                'reason'          => $reason,
                'warnings'        => $warnings,
            ];

            $summary[match ($action) {
                'promote'      => 'promoted',
                'graduate'     => 'graduated',
                'retain'       => 'retained',
                'transfer_out',
                'dropout'      => 'excluded',
                default        => 'excluded',
            }]++;
        }

        $summary['excluded'] += $excludedStudents->count();

        return [
            'source_ay'   => $sourceAy,
            'target_ay'   => $targetAy,
            'new_classes' => $newClasses,
            'mutations'   => $mutations,
            'summary'     => $summary,
        ];
    }
}
```

**Commit:** `test(phase7): previewTransition unit tests RED` then `feat(phase7): implement previewTransition GREEN`

---

### Task 3: `YearTransitionService::executeTransition` (TDD — atomicity)

**Additional tests appended to `YearTransitionServiceTest.php`:**

```php
// ── executeTransition: happy path ─────────────────────────────────────

it('executeTransition creates new classes, re-points class_id, writes mutations and log', function () {
    $sourceAy = makeAY('2025/2026', true);
    $targetAy = makeAY('2026/2027');
    $class5a  = makeClass($sourceAy, 5, 'Kelas 5A');
    $class6a  = makeClass($sourceAy, 6, 'Kelas 6A');
    $promoted = makeStudents($class5a, 5);
    $graduates= makeStudents($class6a, 3);
    $admin    = \App\Models\User::factory()->create(['role' => 'school_admin']);

    $service = new YearTransitionService();
    $log = $service->executeTransition($sourceAy->id, $targetAy->id, [], $admin);

    // New classes created
    expect(SchoolClass::where('academic_year_id', $targetAy->id)->count())->toBe(2);

    // Promoted students: class_id → new grade-6 class in targetAy
    $newGrade6Class = SchoolClass::where('academic_year_id', $targetAy->id)
        ->where('grade_level', 6)->first();
    foreach ($promoted as $s) {
        expect($s->fresh()->class_id)->toBe($newGrade6Class->id);
        expect($s->fresh()->status)->toBe('active');
    }

    // Graduated students: status=graduated, class_id=NULL
    foreach ($graduates as $s) {
        expect($s->fresh()->status)->toBe('graduated');
        expect($s->fresh()->class_id)->toBeNull();
    }

    // StudentMutation rows written
    expect(StudentMutation::where('type', 'promotion')->count())->toBe(5);
    expect(StudentMutation::where('type', 'graduated')->count())->toBe(3);

    // Log row created
    expect($log)->toBeInstanceOf(\App\Models\YearTransitionLog::class);
    expect($log->promoted_count)->toBe(5);
    expect($log->graduated_count)->toBe(3);
    expect($log->plan_snapshot)->toBeArray();
});

// ── executeTransition: atomicity — partial failure rolls back ─────────

it('executeTransition rolls back all changes when an exception occurs mid-execution', function () {
    $sourceAy = makeAY('2025/2026', true);
    $targetAy = makeAY('2026/2027');
    $class4a  = makeClass($sourceAy, 4, 'Kelas 4A');
    $students = makeStudents($class4a, 4);
    $admin    = \App\Models\User::factory()->create(['role' => 'school_admin']);

    $originalClassIds = $students->pluck('class_id', 'id')->toArray();

    // Inject a service subclass that throws after 2 mutations
    $boom = new class extends YearTransitionService {
        private int $callCount = 0;
        protected function applyMutation(array $mutation, array $classMap): void
        {
            $this->callCount++;
            if ($this->callCount > 2) {
                throw new \RuntimeException('Simulated mid-execution failure');
            }
            parent::applyMutation($mutation, $classMap);
        }
    };

    expect(fn () => $boom->executeTransition($sourceAy->id, $targetAy->id, [], $admin))
        ->toThrow(\RuntimeException::class);

    // All students must remain on original class_id (rolled back)
    foreach ($students as $s) {
        expect($s->fresh()->class_id)->toBe($originalClassIds[$s->id]);
    }

    // No mutations written
    expect(StudentMutation::count())->toBe(0);

    // No new classes created
    expect(SchoolClass::where('academic_year_id', $targetAy->id)->count())->toBe(0);

    // No log written
    expect(\App\Models\YearTransitionLog::count())->toBe(0);
});

// ── executeTransition: retention keeps same grade in new AY ──────────

it('executeTransition assigns retained student to same-grade class in target AY', function () {
    $sourceAy = makeAY('2025/2026', true);
    $targetAy = makeAY('2026/2027');
    $class3a  = makeClass($sourceAy, 3, 'Kelas 3A');
    $student  = Student::factory()->create(['class_id' => $class3a->id, 'status' => 'active']);
    $admin    = \App\Models\User::factory()->create(['role' => 'school_admin']);

    $overrides = [$student->id => ['action' => 'retain', 'reason' => 'Nilai tidak memenuhi CP']];

    $service = new YearTransitionService();
    $service->executeTransition($sourceAy->id, $targetAy->id, $overrides, $admin);

    $newGrade3Class = SchoolClass::where('academic_year_id', $targetAy->id)
        ->where('grade_level', 3)->first();

    expect($student->fresh()->class_id)->toBe($newGrade3Class->id);
    expect(StudentMutation::where('student_id', $student->id)->where('type', 'retention')->exists())->toBeTrue();
});
```

**Implementation — add to `YearTransitionService`:**

```php
public function executeTransition(
    int $sourceAyId,
    int $targetAyId,
    array $overrides,
    User $admin
): YearTransitionLog {
    $plan = $this->previewTransition($sourceAyId, $targetAyId, $overrides);

    return DB::transaction(function () use ($plan, $sourceAyId, $targetAyId, $overrides, $admin) {
        // 1. Create new-AY classes
        $classMap = []; // source_class_id → new SchoolClass
        foreach ($plan['new_classes'] as $classDef) {
            $newClass = SchoolClass::create([
                'name'                => $classDef['name'],
                'grade_level'         => $classDef['grade_level'],
                'academic_year_id'    => $targetAyId,
                'homeroom_teacher_id' => null,
                'status'              => 'active',
            ]);
            $classMap[$classDef['source_class_id']] = $newClass;
        }

        // 2. Apply mutations
        foreach ($plan['mutations'] as $mutation) {
            $this->applyMutation($mutation, $classMap);
        }

        // 3. Write audit log
        $log = YearTransitionLog::create([
            'executed_by'             => $admin->id,
            'source_academic_year_id' => $sourceAyId,
            'target_academic_year_id' => $targetAyId,
            'executed_at'             => now(),
            'promoted_count'          => $plan['summary']['promoted'],
            'graduated_count'         => $plan['summary']['graduated'],
            'retained_count'          => $plan['summary']['retained'],
            'excluded_count'          => $plan['summary']['excluded'],
            'plan_snapshot'           => $plan,
            'ip_address'              => request()->ip(),
        ]);

        return $log;
    });
}

protected function applyMutation(array $mutation, array $classMap): void
{
    $student = Student::findOrFail($mutation['student_id']);

    match ($mutation['action']) {
        'promote' => $this->applyPromotion($student, $mutation, $classMap),
        'graduate' => $this->applyGraduation($student, $mutation),
        'retain'   => $this->applyRetention($student, $mutation, $classMap),
        'transfer_out', 'dropout' => $this->applyExit($student, $mutation),
        default    => null,
    };
}

private function applyPromotion(Student $student, array $mutation, array $classMap): void
{
    // Find the new-AY class matching grade_level + 1
    $targetGrade = self::GRADE_STEP[$mutation['from_grade_level']] ?? null;
    if (! $targetGrade) {
        throw new \RuntimeException("No grade step for grade {$mutation['from_grade_level']}");
    }

    $newClass = collect($classMap)->first(
        fn ($c) => $c->grade_level === $targetGrade && $c->name === $mutation['to_class_name']
    ) ?? collect($classMap)->first(fn ($c) => $c->grade_level === $targetGrade);

    if (! $newClass) {
        throw new \RuntimeException("Target class not found for promotion: grade {$targetGrade}");
    }

    $student->update(['class_id' => $newClass->id]);
    StudentMutation::create([
        'student_id'   => $student->id,
        'type'         => 'promotion',
        'from_class_id'=> $mutation['from_class_id'],
        'to_class_id'  => $newClass->id,
        'date'         => now()->toDateString(),
        'reason'       => $mutation['reason'],
    ]);
}

private function applyGraduation(Student $student, array $mutation): void
{
    $student->update(['class_id' => null, 'status' => 'graduated']);
    StudentMutation::create([
        'student_id'    => $student->id,
        'type'          => 'graduated',
        'from_class_id' => $mutation['from_class_id'],
        'to_class_id'   => null,
        'date'          => now()->toDateString(),
        'reason'        => $mutation['reason'],
    ]);
}

private function applyRetention(Student $student, array $mutation, array $classMap): void
{
    // Same grade in new AY
    $newClass = collect($classMap)->first(
        fn ($c) => $c->grade_level === $mutation['from_grade_level']
    );

    if (! $newClass) {
        throw new \RuntimeException("Retention target class not found for grade {$mutation['from_grade_level']}");
    }

    $student->update(['class_id' => $newClass->id]);
    StudentMutation::create([
        'student_id'    => $student->id,
        'type'          => 'retention',
        'from_class_id' => $mutation['from_class_id'],
        'to_class_id'   => $newClass->id,
        'date'          => now()->toDateString(),
        'reason'        => $mutation['reason'],
    ]);
}

private function applyExit(Student $student, array $mutation): void
{
    $newStatus = $mutation['action'] === 'dropout' ? 'dropout' : 'transferred';
    $student->update(['class_id' => null, 'status' => $newStatus]);
    StudentMutation::create([
        'student_id'    => $student->id,
        'type'          => $mutation['action'] === 'dropout' ? 'dropout' : 'transfer_out',
        'from_class_id' => $mutation['from_class_id'],
        'to_class_id'   => null,
        'date'          => now()->toDateString(),
        'reason'        => $mutation['reason'],
    ]);
}

public function restoreFromLog(YearTransitionLog $log, User $admin): void
{
    throw new \RuntimeException('Undo not implemented. Restore manually from plan_snapshot in YearTransitionLog #' . $log->id);
}
```

**Commit:** `test(phase7): executeTransition TDD — atomicity + happy path RED` then `feat(phase7): executeTransition GREEN`

---

### Task 4: `YearTransitionPolicy` + `AppServiceProvider` registration

**File created:** `src/app/Policies/YearTransitionPolicy.php`
**File modified:** `src/app/Providers/AppServiceProvider.php`

```php
<?php

namespace App\Policies;

use App\Models\User;

class YearTransitionPolicy
{
    public function manage(User $user): bool
    {
        return $user->isSchoolAdmin();
    }
}
```

In `AppServiceProvider::boot()`:
```php
\Illuminate\Support\Facades\Gate::define('manage_year_transition', function (User $user) {
    return $user->isSchoolAdmin();
});
```

**Commit:** `feat(phase7): YearTransitionPolicy + gate registration`

---

### Task 5: `PreviewRequest` + `ExecuteRequest` validation

**Files created:**
- `src/app/Http/Requests/YearTransition/PreviewRequest.php`
- `src/app/Http/Requests/YearTransition/ExecuteRequest.php`

**`PreviewRequest.php`:**
```php
<?php

namespace App\Http\Requests\YearTransition;

use Illuminate\Foundation\Http\FormRequest;

class PreviewRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('manage_year_transition');
    }

    public function rules(): array
    {
        return [
            'source_academic_year_id'  => 'required|integer|exists:academic_years,id',
            'target_academic_year_id'  => [
                'required', 'integer', 'exists:academic_years,id',
                'different:source_academic_year_id',
            ],
            'overrides'                => 'nullable|array',
            'overrides.*.action'       => 'required|string|in:promote,graduate,retain,transfer_out,dropout',
            'overrides.*.reason'       => 'nullable|string|max:500',
        ];
    }

    public function messages(): array
    {
        return [
            'target_academic_year_id.different' => 'Tahun ajaran tujuan harus berbeda dari tahun sumber.',
            'overrides.*.action.in'             => 'Tindakan tidak valid. Pilih: promote, graduate, retain, transfer_out, atau dropout.',
        ];
    }
}
```

**`ExecuteRequest.php`:**
```php
<?php

namespace App\Http\Requests\YearTransition;

use Illuminate\Foundation\Http\FormRequest;

class ExecuteRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('manage_year_transition');
    }

    public function rules(): array
    {
        return [
            'source_academic_year_id'  => 'required|integer|exists:academic_years,id',
            'target_academic_year_id'  => [
                'required', 'integer', 'exists:academic_years,id',
                'different:source_academic_year_id',
            ],
            'overrides'                => 'nullable|array',
            'overrides.*.action'       => 'required|string|in:promote,graduate,retain,transfer_out,dropout',
            'overrides.*.reason'       => 'nullable|string|max:500',
            'confirmation_word'        => 'required|string|in:TERAPKAN',
        ];
    }

    public function messages(): array
    {
        return [
            'confirmation_word.in' => 'Ketik "TERAPKAN" untuk mengkonfirmasi.',
        ];
    }
}
```

**Commit:** `feat(phase7): PreviewRequest + ExecuteRequest validation`

---

### Task 6: `YearTransitionController` + routes + feature tests

**Files created:**
- `src/app/Http/Controllers/YearTransitionController.php`
- `src/tests/Feature/YearTransition/PreviewTest.php`
- `src/tests/Feature/YearTransition/ExecuteTest.php`

**Step 1 — Write failing feature tests:**

**`PreviewTest.php`:**
```php
<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\User;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

function adminForTransition(): User
{
    return User::factory()->create(['role' => 'school_admin']);
}

function teacherForTransition(): User
{
    return User::factory()->create(['role' => 'teacher']);
}

it('guest cannot access preview (redirect to login)', function () {
    $this->postJson(route('year-transition.preview'), [])
        ->assertUnauthorized();
});

it('teacher cannot access preview (403)', function () {
    $teacher = teacherForTransition();
    $source = AcademicYear::factory()->create(['is_active' => true]);
    $target = AcademicYear::factory()->create();

    $this->actingAs($teacher)
        ->postJson(route('year-transition.preview'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
        ])
        ->assertForbidden();
});

it('preview returns 422 when source and target are the same', function () {
    $admin  = adminForTransition();
    $source = AcademicYear::factory()->create();

    $this->actingAs($admin)
        ->postJson(route('year-transition.preview'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $source->id,
        ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['target_academic_year_id']);
});

it('preview returns 200 with mutation plan structure', function () {
    $admin  = adminForTransition();
    $source = AcademicYear::factory()->create(['is_active' => true]);
    $target = AcademicYear::factory()->create();
    $class  = SchoolClass::factory()->create(['academic_year_id' => $source->id, 'grade_level' => 4]);
    Student::factory()->count(5)->create(['class_id' => $class->id, 'status' => 'active']);

    $this->actingAs($admin)
        ->postJson(route('year-transition.preview'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
        ])
        ->assertOk()
        ->assertJsonStructure(['mutations', 'summary', 'new_classes']);
});
```

**`ExecuteTest.php`:**
```php
<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\StudentMutation;
use App\Models\User;
use App\Models\YearTransitionLog;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

it('execute returns 422 without TERAPKAN confirmation word', function () {
    $admin  = User::factory()->create(['role' => 'school_admin']);
    $source = AcademicYear::factory()->create();
    $target = AcademicYear::factory()->create();

    $this->actingAs($admin)
        ->postJson(route('year-transition.execute'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
            'confirmation_word'        => 'SALAH',
        ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['confirmation_word']);
});

it('execute commits transition and returns log id', function () {
    $admin  = User::factory()->create(['role' => 'school_admin']);
    $source = AcademicYear::factory()->create(['is_active' => true]);
    $target = AcademicYear::factory()->create();
    $class  = SchoolClass::factory()->create(['academic_year_id' => $source->id, 'grade_level' => 3]);
    Student::factory()->count(4)->create(['class_id' => $class->id, 'status' => 'active']);

    $response = $this->actingAs($admin)
        ->postJson(route('year-transition.execute'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
            'confirmation_word'        => 'TERAPKAN',
        ])
        ->assertOk()
        ->assertJsonStructure(['log_id', 'summary']);

    expect(YearTransitionLog::count())->toBe(1);
    expect(StudentMutation::where('type', 'promotion')->count())->toBe(4);
});

it('execute returns 403 for non-admin users', function () {
    $teacher = User::factory()->create(['role' => 'teacher']);
    $source  = AcademicYear::factory()->create();
    $target  = AcademicYear::factory()->create();

    $this->actingAs($teacher)
        ->postJson(route('year-transition.execute'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
            'confirmation_word'        => 'TERAPKAN',
        ])
        ->assertForbidden();
});

it('execute rolls back and returns 500 on service exception', function () {
    // Use a mock to force a RuntimeException inside executeTransition
    $admin  = User::factory()->create(['role' => 'school_admin']);
    $source = AcademicYear::factory()->create(['is_active' => true]);
    $target = AcademicYear::factory()->create();
    $class  = SchoolClass::factory()->create(['academic_year_id' => $source->id, 'grade_level' => 5]);
    Student::factory()->count(2)->create(['class_id' => $class->id, 'status' => 'active']);

    $this->instance(
        \App\Services\YearTransitionService::class,
        \Mockery::mock(\App\Services\YearTransitionService::class, function ($mock) {
            $mock->shouldReceive('previewTransition')->andReturn([
                'source_ay' => null, 'target_ay' => null,
                'new_classes' => [], 'mutations' => [],
                'summary' => ['promoted' => 0, 'graduated' => 0, 'retained' => 0, 'excluded' => 0],
            ]);
            $mock->shouldReceive('executeTransition')
                ->andThrow(new \RuntimeException('Forced failure'));
        })
    );

    $this->actingAs($admin)
        ->postJson(route('year-transition.execute'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
            'confirmation_word'        => 'TERAPKAN',
        ])
        ->assertStatus(500);

    expect(YearTransitionLog::count())->toBe(0);
});
```

**Controller implementation:**

```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\YearTransition\ExecuteRequest;
use App\Http\Requests\YearTransition\PreviewRequest;
use App\Models\YearTransitionLog;
use App\Services\YearTransitionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;
use Inertia\Inertia;
use Inertia\Response;

class YearTransitionController extends Controller
{
    public function __construct(private YearTransitionService $service)
    {
        //
    }

    public function index(): Response
    {
        Gate::authorize('manage_year_transition');

        return Inertia::render('YearTransition/Wizard', [
            'academicYears' => \App\Models\AcademicYear::orderByDesc('start_date')->get(),
        ]);
    }

    public function preview(PreviewRequest $request): JsonResponse
    {
        $plan = $this->service->previewTransition(
            $request->integer('source_academic_year_id'),
            $request->integer('target_academic_year_id'),
            $request->array('overrides', []),
        );

        return response()->json($plan);
    }

    public function execute(ExecuteRequest $request): JsonResponse
    {
        try {
            $log = $this->service->executeTransition(
                $request->integer('source_academic_year_id'),
                $request->integer('target_academic_year_id'),
                $request->array('overrides', []),
                $request->user(),
            );

            return response()->json([
                'log_id'  => $log->id,
                'summary' => [
                    'promoted'  => $log->promoted_count,
                    'graduated' => $log->graduated_count,
                    'retained'  => $log->retained_count,
                    'excluded'  => $log->excluded_count,
                ],
            ]);
        } catch (\RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 500);
        }
    }

    public function logs(): Response
    {
        Gate::authorize('manage_year_transition');

        return Inertia::render('YearTransition/Logs', [
            'logs' => YearTransitionLog::with(['executor', 'sourceAcademicYear', 'targetAcademicYear'])
                ->orderByDesc('executed_at')
                ->paginate(20),
        ]);
    }

    public function showLog(YearTransitionLog $log): Response
    {
        Gate::authorize('manage_year_transition');

        return Inertia::render('YearTransition/LogDetail', [
            'log' => $log->load(['executor', 'sourceAcademicYear', 'targetAcademicYear']),
        ]);
    }
}
```

**Routes (add to `src/routes/web.php` inside `auth` middleware group):**

```php
use App\Http\Controllers\YearTransitionController;

Route::prefix('year-transition')->name('year-transition.')->group(function () {
    Route::get('/',            [YearTransitionController::class, 'index'])->name('index');
    Route::post('/preview',    [YearTransitionController::class, 'preview'])->name('preview');
    Route::post('/execute',    [YearTransitionController::class, 'execute'])->name('execute');
    Route::get('/logs',        [YearTransitionController::class, 'logs'])->name('logs');
    Route::get('/logs/{log}',  [YearTransitionController::class, 'showLog'])->name('logs.show');
});
```

Add to `HandleInertiaRequests.php` permissions array:
```php
'manage_year_transition' => $user->isSchoolAdmin(),
```

**Commit:** `feat(phase7): YearTransitionController + routes + feature tests`

---

### Task 7: Vue Wizard Shell (`Wizard.vue`)

**File created:** `src/resources/js/Pages/YearTransition/Wizard.vue`

```vue
<script setup>
import { ref, computed } from 'vue';
import { router, usePage } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';
import SelectYears from './Steps/SelectYears.vue';
import ClassStructure from './Steps/ClassStructure.vue';
import StudentReview from './Steps/StudentReview.vue';
import Preview from './Steps/Preview.vue';
import Confirm from './Steps/Confirm.vue';

defineOptions({ layout: AppLayout });

defineProps({ academicYears: Array });

const currentStep = ref(1);
const totalSteps = 5;

const stepLabels = [
    'Pilih Tahun Ajaran',
    'Struktur Kelas',
    'Review Siswa',
    'Preview Mutasi',
    'Konfirmasi',
];

// Shared wizard state — passed down to each step
const wizardData = ref({
    sourceAyId: null,
    targetAyId: null,
    newClasses: [],      // editable class list from Step 2
    overrides: {},       // { student_id: { action, reason } }
    plan: null,          // dry-run result from /preview
});

function next() { currentStep.value = Math.min(currentStep.value + 1, totalSteps); }
function back() { currentStep.value = Math.max(currentStep.value - 1, 1); }
</script>

<template>
    <Head title="Transisi Tahun Ajaran" />
    <div class="p-6 max-w-5xl mx-auto">
        <h1 class="text-2xl font-semibold text-slate-800 mb-6">Transisi Tahun Ajaran</h1>

        <!-- Step indicator -->
        <div class="flex items-center mb-8 gap-2">
            <template v-for="(label, i) in stepLabels" :key="i">
                <div class="flex items-center gap-2">
                    <div :class="['w-7 h-7 rounded-full flex items-center justify-center text-sm font-semibold',
                                  currentStep === i+1 ? 'bg-orange-500 text-white' :
                                  currentStep > i+1  ? 'bg-green-500 text-white' :
                                                       'bg-slate-200 text-slate-500']">
                        {{ i + 1 }}
                    </div>
                    <span class="text-sm hidden md:block" :class="currentStep === i+1 ? 'font-semibold text-slate-800' : 'text-slate-400'">
                        {{ label }}
                    </span>
                </div>
                <div v-if="i < stepLabels.length - 1" class="flex-1 h-px bg-slate-200" />
            </template>
        </div>

        <!-- Step content -->
        <SelectYears    v-if="currentStep === 1" :academicYears="academicYears" v-model="wizardData" @next="next" />
        <ClassStructure v-if="currentStep === 2" v-model="wizardData" @next="next" @back="back" />
        <StudentReview  v-if="currentStep === 3" v-model="wizardData" @next="next" @back="back" />
        <Preview        v-if="currentStep === 4" v-model="wizardData" @next="next" @back="back" />
        <Confirm        v-if="currentStep === 5" v-model="wizardData" @back="back" />
    </div>
</template>
```

**Acceptance:** Wizard renders with step indicator. Clicking next/back advances/retreats steps. Each step component slot renders without console errors.

**Commit:** `feat(phase7): Wizard.vue shell with step indicator`

---

### Task 8: Steps 1 & 2 Vue components

**Files created:**
- `src/resources/js/Pages/YearTransition/Steps/SelectYears.vue`
- `src/resources/js/Pages/YearTransition/Steps/ClassStructure.vue`

**`SelectYears.vue`** — key behavior:
- Props: `academicYears` (array), `modelValue` (wizardData)
- Two `<select>` dropdowns: source AY (pre-selected to active AY), target AY
- If no target AY exists or "Buat Baru" selected: show inline create fields (name, start_date, end_date) and call `router.post(route('academic-years.store'))` before advancing
- Emits `update:modelValue` with `{ sourceAyId, targetAyId }` on "Lanjutkan"
- Validation: source ≠ target; both required

**`ClassStructure.vue`** — key behavior:
- Calls `/year-transition/preview` on mount to get `new_classes`
- Renders editable table: columns = Nama Kelas | Tingkat | Wali Kelas
- Wali Kelas column: "(Belum ditentukan)" — read-only note (not editable here)
- Admin can edit class name inline (updates local `wizardData.newClasses` array)
- Checkboxes to exclude specific classes
- Info callout: "Kelas 1 untuk siswa baru perlu dibuat terpisah setelah proses ini."
- Emits updated class list via `update:modelValue`

**Acceptance:** Step 2 shows auto-generated class list matching source AY structure; admin can rename a class; changes persist in wizardData across step navigation.

**Commit:** `feat(phase7): SelectYears + ClassStructure step components`

---

### Task 9: Steps 3 & 4 Vue components

**Files created:**
- `src/resources/js/Pages/YearTransition/Steps/StudentReview.vue`
- `src/resources/js/Pages/YearTransition/Steps/Preview.vue`
- `src/resources/js/Components/YearTransition/StudentRow.vue`

**`StudentReview.vue`** — key behavior:
- On mount: calls `POST /year-transition/preview` with current `wizardData` to fetch students grouped by class
- Renders grouped accordion per source class
- Per student row: `StudentRow.vue` component
- Loading skeleton while preview fetch in progress
- Emits updated `overrides` map to wizardData

**`StudentRow.vue`** — key behavior:
- Props: `mutation` object from preview result
- Shows: student name, NIS, from_class_name, action select (Naik Kelas / Lulus / Mengulang / Mutasi Keluar / Putus Sekolah), reason textarea (shown when not default action)
- Warning badge if `mutation.warnings.length > 0`
- Emits `change` with `{ studentId, action, reason }` to parent

**`Preview.vue`** — key behavior:
- Displays summary cards: big number + label for each category
- Calls `POST /year-transition/preview` again with final overrides (or re-uses cached plan from wizardData)
- Full mutation table: Name | NIS | From Class | Action | Target Class | Reason
- "Unduh Rencana (JSON)" button: `Blob` download of `JSON.stringify(wizardData.plan)`
- Info box: "Belum ada perubahan data. Klik Konfirmasi untuk menerapkan."

**Acceptance:** Step 3 shows all active students with correct default action (Grade 6 = Lulus, others = Naik Kelas). Changing a student to "Mengulang" updates the override map. Step 4 shows accurate summary counts matching overrides.

**Commit:** `feat(phase7): StudentReview + Preview steps + StudentRow component`

---

### Task 10: Step 5 Confirm component

**File created:** `src/resources/js/Pages/YearTransition/Steps/Confirm.vue`

**Key behavior:**
- Props: `modelValue` (wizardData with plan)
- Summary repeat: X Naik Kelas / Y Lulus / Z Mengulang
- Red warning box: "Proses ini tidak dapat dibatalkan secara otomatis. Pastikan semua data sudah benar sebelum melanjutkan."
- `<input type="text" placeholder="Ketik TERAPKAN untuk mengkonfirmasi" v-model="confirmWord" />`
- Button "Konfirmasi & Terapkan Transisi": disabled until `confirmWord === 'TERAPKAN'`
- On click: `isSubmitting = true`, calls `router.post(route('year-transition.execute'), payload, { onSuccess, onError })`
- `onSuccess`: flash message rendered by AppLayout toast, redirect to `/year-transition/logs`
- `onError`: display error alert, `isSubmitting = false`
- Spinner on button while submitting

**Acceptance:** Button stays disabled until exact string "TERAPKAN" is typed. Submitting shows spinner. On success, redirects to logs page with flash. On 500 error, shows error message without losing page state.

**Commit:** `feat(phase7): Confirm step with TERAPKAN gate`

---

### Task 11: Logs pages

**Files created:**
- `src/resources/js/Pages/YearTransition/Logs.vue`
- `src/resources/js/Pages/YearTransition/LogDetail.vue`

**`Logs.vue`:**
- Props: `{ logs: Object }` (paginated)
- Table: Tanggal | Tahun Sumber → Tahun Tujuan | Dijalankan Oleh | Naik | Lulus | Mengulang | Aksi
- "Lihat Detail" link per row → `route('year-transition.logs.show', log.id)`
- Pagination component
- Empty state: "Belum ada riwayat transisi."

**`LogDetail.vue`:**
- Props: `{ log: Object }`
- Summary header cards
- "Unduh Snapshot JSON" button
- Full mutation table from `log.plan_snapshot.mutations`
- Back link to logs index

**Acceptance:** Logs page lists executed transitions. Detail page shows all per-student mutations from the snapshot. JSON download works.

**Commit:** `feat(phase7): Logs + LogDetail pages`

---

### Task 12: Nav menu + permission wiring + `StudentMutationFactory`

**Files modified:**
- `src/resources/js/Layouts/AppLayout.vue`
- `src/app/Http/Middleware/HandleInertiaRequests.php` (already added in Task 6)

**File created:**
- `src/database/factories/StudentMutationFactory.php`

**Nav entry** — add under `AKADEMIK` divider (school_admin only):
```javascript
{
  name: 'Kenaikan Kelas',
  href: '/year-transition',
  icon: 'arrow-up-circle',
  show: permissions.manage_year_transition,
},
```
Check existing icon keys in AppLayout's SVG switch; use the closest matching key or add new `arrow-up-circle` SVG case.

**`StudentMutationFactory.php`** (needed by Task 2/3 tests):
```php
<?php

namespace Database\Factories;

use App\Models\Student;
use Illuminate\Database\Eloquent\Factories\Factory;

class StudentMutationFactory extends Factory
{
    public function definition(): array
    {
        return [
            'student_id'       => Student::factory(),
            'type'             => $this->faker->randomElement(['promotion', 'retention', 'graduated', 'transfer_in', 'transfer_out']),
            'from_class_id'    => null,
            'to_class_id'      => null,
            'date'             => $this->faker->dateTimeBetween('-1 year', 'now')->format('Y-m-d'),
            'reason'           => $this->faker->optional()->sentence(),
            'reference_number' => null,
            'notes'            => null,
        ];
    }
}
```

**Commit:** `feat(phase7): nav item + StudentMutationFactory`

---

### Task 13: `SchoolClassFactory` check + regression run + tag

**Verify factory exists:**
```bash
ls /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/database/factories/ | grep SchoolClass
```

If missing, create `SchoolClassFactory.php`:
```php
<?php

namespace Database\Factories;

use App\Models\AcademicYear;
use Illuminate\Database\Eloquent\Factories\Factory;

class SchoolClassFactory extends Factory
{
    public function definition(): array
    {
        return [
            'name'                => 'Kelas ' . $this->faker->randomElement(['1A','2A','3A','4A','5A','6A']),
            'grade_level'         => $this->faker->numberBetween(1, 6),
            'academic_year_id'    => AcademicYear::factory(),
            'homeroom_teacher_id' => null,
            'max_students'        => 32,
            'status'              => 'active',
        ];
    }
}
```

**Full regression run:**
```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest
```

Expected: all pre-existing tests green + 20+ new Phase 7 tests pass.

**Tag:**
```bash
git tag v0.phase7-year-transition
```

**Commit:** `test(phase7): regression green + SchoolClassFactory if missing`

---

## Definition of Done

- [ ] `year_transition_logs` migration runs without error; table visible in DB
- [ ] `YearTransitionLog` model: relationships to User + 2 AcademicYears work; `totalMutations()` correct
- [ ] `previewTransition` returns correct mutation plan for 30 students with 5 graduates and 2 retentions
- [ ] `previewTransition` excludes `transferred` and `dropout` students
- [ ] `previewTransition` flags `transfer_in` mid-year students with warnings
- [ ] `previewTransition` writes ZERO rows to any DB table
- [ ] `executeTransition` creates new-AY classes from source structure
- [ ] `executeTransition` re-points `class_id` for promoted students to next-grade class in new AY
- [ ] `executeTransition` sets `status=graduated`, `class_id=NULL` for Kelas 6 graduates
- [ ] `executeTransition` assigns retained students to same-grade class in new AY
- [ ] `executeTransition` writes one `StudentMutation` row per student
- [ ] `executeTransition` writes one `YearTransitionLog` row with full `plan_snapshot` JSON
- [ ] Simulated mid-execution exception causes full rollback; no partial DB state
- [ ] `POST /year-transition/execute` without "TERAPKAN" confirmation word returns 422
- [ ] `POST /year-transition/execute` as teacher returns 403
- [ ] Wizard renders all 5 steps with step indicator
- [ ] Step 3 defaults Grade 6 students to "Lulus", others to "Naik Kelas"
- [ ] Step 5 button disabled until exact string "TERAPKAN" typed
- [ ] `/year-transition/logs` lists all executed transitions with correct counts
- [ ] Nav "Kenaikan Kelas" visible for `school_admin` only
- [ ] Old-AY class records NOT deleted; grades/attendance/report-cards intact after transition
- [ ] Full pest suite passes (no regressions)

---

## Test Count Expectation

| Suite | Tests | Key scenarios |
|-------|-------|---------------|
| Unit — `YearTransitionLogTest` | 3 | relationships, totalMutations, JSON cast |
| Unit — `YearTransitionServiceTest` | 10 | preview structure, class mirroring, 30-student scenario, exclusions, grade-6 override, transfer_in warning, no-DB-write, execute happy path, execute rollback, retention grade |
| Feature — `PreviewTest` | 4 | guest 401, teacher 403, same-AY 422, valid 200 |
| Feature — `ExecuteTest` | 4 | wrong word 422, happy path 200+log, teacher 403, service exception 500+rollback |
| **Total** | **21+** | |

---

## Risk Register

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Grade-level mismatch: source has Grade 1–6 but new-AY class names don't follow convention | Medium | `applyPromotion` falls back to first class matching `grade_level`, not just name; test covers this |
| `DB::transaction` swallows `RuntimeException` (Laravel catches and re-throws as 500 only if not caught) | Low | Controller catches `\RuntimeException` explicitly; transaction still rolls back because exception propagates before return |
| Admin runs wizard twice: duplicate new-AY classes created | Medium | `executeTransition` should check `SchoolClass::where('academic_year_id', $targetAyId)->exists()` and throw if already populated; add guard before class creation loop |
| `attendance.class_id` CASCADE: if admin later deletes old-AY class, attendance history lost | High (if admin unaware) | Add class-deletion guard in `SchoolClassController::destroy()`: block delete if `Attendance::where('class_id', $id)->exists()` — separate task, note in controller |
| `Semester::where('is_active', true)->first()` returns wrong semester during wizard (13+ callers) | Medium | Wizard does NOT flip `is_active` on any semester — admin does this separately via existing semester activate flow AFTER wizard completes |
| `previewTransition` called with `targetAyId` that already has classes (re-run scenario) | Medium | Preview is safe (no writes); execute guard (risk above) prevents double-execution |
| Grade-7 promotion error: a Grade-6 student with `promote` action (admin forgot to set graduate) | Low | `GRADE_STEP` has no key for 6 → `applyPromotion` throws `RuntimeException` → full rollback; preview must surface this as a warning before execute |

---

## Out of Scope (Phase 7.5+)

- "Import TAs from previous year" helper button (blocked by Meeting auto-generation in TA `booted()` hook)
- Auto-generate new-AY Semester 1 dates (admin uses existing `/academic-years/{id}/semesters/create`)
- Undo/restore UI endpoint (`restoreFromLog` stub exists but not wired to any route)
- Bulk wali kelas assignment in wizard (admin assigns one-by-one via existing class edit page)
- Mobile parent notification when student is promoted (Phase 6+ push notification layer)
- PPDB (new Grade 1 intake) workflow — entirely separate from this wizard
- Dapodik sync / export (separate data-export concern)
- Per-student post-transition reassignment UI (admin uses Student edit page directly)
