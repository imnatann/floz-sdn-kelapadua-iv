<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\StudentMutation;
use App\Services\YearTransitionService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

// ── helpers ───────────────────────────────────────────────────────────────────

function makeAY(string $name, bool $active = false): AcademicYear
{
    return AcademicYear::factory()->create([
        'name'       => $name,
        'is_active'  => $active,
        'start_date' => '2025-07-14',
        'end_date'   => '2026-06-19',
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

// ── preview: basic structure ──────────────────────────────────────────────────

it('preview returns expected top-level keys', function () {
    $sourceAy = makeAY('2025/2026', true);
    $targetAy = makeAY('2026/2027');
    $class1a  = makeClass($sourceAy, 1, 'Kelas 1A');
    makeStudents($class1a, 3);

    $service = new YearTransitionService();
    $result  = $service->previewTransition($sourceAy->id, $targetAy->id, []);

    expect($result)->toHaveKeys(['source_ay', 'target_ay', 'new_classes', 'mutations', 'summary']);
});

// ── preview: class mirroring ──────────────────────────────────────────────────

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

// ── preview: 30 students with promotion + graduation + retention ──────────────

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
    $class4a = makeClass($sourceAy, 4, 'Kelas 4A');
    $grade4s = makeStudents($class4a, 5);
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

// ── preview: transferred-out students are excluded ────────────────────────────

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

// ── preview: grade-6 override to retain (extraordinary case) ─────────────────

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

// ── preview: transfer_in mid-year triggers warning ────────────────────────────

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

// ── preview: no DB writes occur ───────────────────────────────────────────────

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

// ── BLOCK-4: multi-section promotion — 4A→5A, 4B→5B not both to same class ──

it('preview sets correct to_class_name for multi-section promotion', function () {
    $sourceAy = makeAY('2025/2026', true);
    $targetAy = makeAY('2026/2027');
    $class4a  = makeClass($sourceAy, 4, 'Kelas 4A');
    $class4b  = makeClass($sourceAy, 4, 'Kelas 4B');
    $student4a = Student::factory()->create(['class_id' => $class4a->id, 'status' => 'active']);
    $student4b = Student::factory()->create(['class_id' => $class4b->id, 'status' => 'active']);

    $service = new YearTransitionService();
    $result  = $service->previewTransition($sourceAy->id, $targetAy->id, []);

    $mut4a = collect($result['mutations'])->firstWhere('student_id', $student4a->id);
    $mut4b = collect($result['mutations'])->firstWhere('student_id', $student4b->id);

    // 4A → 5A, 4B → 5B
    expect($mut4a['to_class_name'])->toBe('Kelas 5A');
    expect($mut4b['to_class_name'])->toBe('Kelas 5B');
});

// ── EDGE: orphan students (class_id = null) excluded ─────────────────────────

it('preview excludes students with null class_id', function () {
    $sourceAy   = makeAY('2025/2026', true);
    $targetAy   = makeAY('2026/2027');
    $class5a    = makeClass($sourceAy, 5, 'Kelas 5A');
    makeStudents($class5a, 3);

    // Orphan student — no class_id, no way to determine source AY
    Student::factory()->create(['class_id' => null, 'status' => 'active']);

    $service = new YearTransitionService();
    $result  = $service->previewTransition($sourceAy->id, $targetAy->id, []);

    // Orphan is not in the mutations list (excluded from source AY query)
    expect($result['mutations'])->toHaveCount(3);
    expect($result['summary']['excluded'])->toBe(0); // excluded from mutations, not counted here
});

// ── executeTransition: happy path ─────────────────────────────────────────────

it('executeTransition creates new classes, re-points class_id, writes mutations and log', function () {
    $sourceAy  = makeAY('2025/2026', true);
    $targetAy  = makeAY('2026/2027');
    $class5a   = makeClass($sourceAy, 5, 'Kelas 5A');
    $class6a   = makeClass($sourceAy, 6, 'Kelas 6A');
    $promoted  = makeStudents($class5a, 5);
    $graduates = makeStudents($class6a, 3);
    $admin     = \App\Models\User::factory()->create(['role' => 'school_admin']);

    $service = new YearTransitionService();
    $log = $service->executeTransition($sourceAy->id, $targetAy->id, [], $admin);

    // New classes created
    expect(SchoolClass::where('academic_year_id', $targetAy->id)->count())->toBe(2);

    // Promoted students: class_id → new grade-6 class in targetAy
    $newGrade6Class = SchoolClass::where('academic_year_id', $targetAy->id)
        ->where('grade_level', 6)
        ->where('name', 'Kelas 6A')
        ->first();
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

// ── executeTransition: atomicity — partial failure rolls back ─────────────────

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

// ── executeTransition: retention keeps same grade in new AY ──────────────────

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

// ── executeTransition: throws when target AY already has classes (BLOCK-1) ───

it('executeTransition throws when target AY already has classes', function () {
    $sourceAy = makeAY('2025/2026', true);
    $targetAy = makeAY('2026/2027');
    $class5a  = makeClass($sourceAy, 5, 'Kelas 5A');
    makeStudents($class5a, 3);
    $admin    = \App\Models\User::factory()->create(['role' => 'school_admin']);

    // Pre-populate target AY with a class (simulating prior execution)
    makeClass($targetAy, 6, 'Kelas 6A');

    $service = new YearTransitionService();

    expect(fn () => $service->executeTransition($sourceAy->id, $targetAy->id, [], $admin))
        ->toThrow(\RuntimeException::class, 'sudah memiliki kelas');
});

// ── executeTransition: multi-section — 4A→5A, 4B→5B (BLOCK-4) ───────────────
// The source AY must contain BOTH grade-4 classes (4A, 4B) AND grade-5 classes (5A, 5B)
// so the classMap has grade-5 entries that promoted grade-4 students can land in.

it('executeTransition routes multi-section students to correct target class', function () {
    $sourceAy  = makeAY('2025/2026', true);
    $targetAy  = makeAY('2026/2027');
    // Source has 4A, 4B, 5A, 5B — classMap will mirror all 4 into target AY
    $class4a   = makeClass($sourceAy, 4, 'Kelas 4A');
    $class4b   = makeClass($sourceAy, 4, 'Kelas 4B');
    makeClass($sourceAy, 5, 'Kelas 5A'); // needed so classMap has grade-5 entry for 4A → 5A
    makeClass($sourceAy, 5, 'Kelas 5B'); // needed so classMap has grade-5 entry for 4B → 5B
    $student4a = Student::factory()->create(['class_id' => $class4a->id, 'status' => 'active']);
    $student4b = Student::factory()->create(['class_id' => $class4b->id, 'status' => 'active']);
    $admin     = \App\Models\User::factory()->create(['role' => 'school_admin']);

    $service = new YearTransitionService();
    $service->executeTransition($sourceAy->id, $targetAy->id, [], $admin);

    $new5A = SchoolClass::where('academic_year_id', $targetAy->id)->where('name', 'Kelas 5A')->first();
    $new5B = SchoolClass::where('academic_year_id', $targetAy->id)->where('name', 'Kelas 5B')->first();

    expect($student4a->fresh()->class_id)->toBe($new5A->id);
    expect($student4b->fresh()->class_id)->toBe($new5B->id);
});

// ── executeTransition: audit log inside transaction — rollback cleans it ──────

it('it_writes_audit_log_inside_transaction — rollback removes audit entries', function () {
    $sourceAy = makeAY('2025/2026', true);
    $targetAy = makeAY('2026/2027');
    $class4a  = makeClass($sourceAy, 4, 'Kelas 4A');
    makeStudents($class4a, 3);
    $admin    = \App\Models\User::factory()->create(['role' => 'school_admin']);

    $auditCountBefore = \App\Models\AuditLog::count();

    $boom = new class extends YearTransitionService {
        protected function applyMutation(array $mutation, array $classMap): void
        {
            parent::applyMutation($mutation, $classMap);
            // Throw after first mutation to simulate partial failure
            throw new \RuntimeException('Forced audit test failure');
        }
    };

    expect(fn () => $boom->executeTransition($sourceAy->id, $targetAy->id, [], $admin))
        ->toThrow(\RuntimeException::class);

    // Rollback must have removed all audit entries created inside the transaction
    expect(\App\Models\AuditLog::count())->toBe($auditCountBefore);
});

// ── W-04: computePlanHash — deterministic SHA-256 ────────────────────────────

it('computePlanHash returns same hash for identical plan data', function () {
    $sourceAy = makeAY('2025/2026', true);
    $targetAy = makeAY('2026/2027');
    $class4a  = makeClass($sourceAy, 4, 'Kelas 4A');
    makeStudents($class4a, 3);

    $service = new YearTransitionService();
    $plan    = $service->previewTransition($sourceAy->id, $targetAy->id, []);

    $hash1 = $service->computePlanHash($plan, $sourceAy->id, $targetAy->id);
    $hash2 = $service->computePlanHash($plan, $sourceAy->id, $targetAy->id);

    expect($hash1)->toBe($hash2);
    expect(strlen($hash1))->toBe(64); // SHA-256 hex = 64 chars
});

it('computePlanHash returns different hash when mutations differ', function () {
    $sourceAy  = makeAY('2025/2026', true);
    $targetAy  = makeAY('2026/2027');
    $class4a   = makeClass($sourceAy, 4, 'Kelas 4A');
    $students  = makeStudents($class4a, 3);

    $service = new YearTransitionService();
    $plan1   = $service->previewTransition($sourceAy->id, $targetAy->id, []);

    // Override one student to retain
    $override = [$students->first()->id => ['action' => 'retain', 'reason' => null]];
    $plan2    = $service->previewTransition($sourceAy->id, $targetAy->id, $override);

    $hash1 = $service->computePlanHash($plan1, $sourceAy->id, $targetAy->id);
    $hash2 = $service->computePlanHash($plan2, $sourceAy->id, $targetAy->id);

    expect($hash1)->not->toBe($hash2);
});
