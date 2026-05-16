# Phase 7 Plan Check — 2026-05-08

## Verdict: BLOCK

---

## Critical Findings (BLOCK — must fix before execute)

### BLOCK-1: Double-execute / idempotency — no guard, no DB unique constraint

**Location:** `executeTransition()` Task 3 implementation; migration Task 1.

The Risk Register acknowledges "Admin runs wizard twice" (Medium likelihood) but the proposed mitigation — `SchoolClass::where('academic_year_id', $targetAyId)->exists()` check — is **not in the plan's migration, service code, or any test**. It is mentioned in prose only.

Consequences of a double-execute on the same source→target pair:
- A second set of new-AY classes is created (duplicate "Kelas 5A" in 2026/2027).
- `applyPromotion` selects `collect($classMap)->first(fn ($c) => $c->grade_level === $targetGrade)` — the `$classMap` from the second run contains *only* the new second-run classes, so students get re-pointed again to new duplicates.
- Two `YearTransitionLog` rows written; no uniqueness constraint on `(source_academic_year_id, target_academic_year_id)`.

**Remediation:**
1. Add to migration: `$table->unique(['source_academic_year_id', 'target_academic_year_id'], 'ytl_unique_transition');`
2. Add to `executeTransition()` **before** the `DB::transaction`:
   ```php
   if (SchoolClass::where('academic_year_id', $targetAyId)->exists()) {
       throw new \RuntimeException('Transisi ke tahun ajaran ini sudah pernah dijalankan. Periksa riwayat transisi.');
   }
   ```
3. Add test: `it('executeTransition throws when target AY already has classes', ...)`.

---

### BLOCK-2: `Auditable` trait fires `AuditLog::create()` outside DB transaction for every `Student::update()` and `StudentMutation::create()`

**Location:** `src/app/Traits/Auditable.php` lines 12–23; `Student` uses `Auditable`; `StudentMutation` uses `Auditable`; `SchoolClass` uses `Auditable`.

The `Auditable` trait hooks `created`/`updated` model events. `AuditLog::create()` executes immediately when the event fires — it uses its own DB write that is part of the **same** connection and therefore IS inside the Laravel `DB::transaction` closure. This is actually safe for rollback.

**However:** if the `AuditLog` table itself has a constraint violation (e.g. `url` or `ip_address` unexpectedly null in a CLI/test context, or `user_id` FK constraint if `Auth::id()` is null and FK is not nullable), the `AuditLog::create()` will throw **inside** the transaction, causing a rollback of all student mutations — with a misleading error message pointing at audit logs rather than the actual business logic.

The plan has **no test** for the `AuditLog`-writes-during-transaction scenario and no `Auth::shouldUse()` / `Auth::setUser()` call in the service before executing (the service receives `$admin` but never sets `Auth::user()` — so `Auth::id()` inside the trait returns `null` during `executeTransition` if called from a queue job or test without `actingAs`).

**Remediation:**
```php
// In executeTransition(), before DB::transaction:
\Illuminate\Support\Facades\Auth::shouldUse('web');
// OR pass admin into auth context explicitly, OR wrap AuditLog::create in a null-guard:
// In Auditable trait audit() method — already partially handled with comment "user_id might be null"
// but verify audit_logs.user_id FK is nullable in migration.
```
Check `audit_logs` migration: if `user_id` is a non-nullable FK and `Auth::id()` returns null in a test/job context, every `StudentMutation::create()` will throw inside the transaction. Verify and add test coverage for this path.

---

### BLOCK-3: `previewTransition` called **before** the DB transaction; overrides can change between preview and execute — plan snapshot is wrong

**Location:** `executeTransition()` Task 3, line:
```php
$plan = $this->previewTransition($sourceAyId, $targetAyId, $overrides);

return DB::transaction(function () use ($plan, ...) {
```

The preview runs outside the transaction. Between preview completion and transaction start, a concurrent admin could:
- Edit a student's `status` or `class_id`.
- Add a new active student to the source AY class.

The `$plan` snapshot baked before the transaction will now be stale. The student being mutated inside the transaction may no longer exist or may have already been moved. `Student::findOrFail()` in `applyMutation()` will find the student but the mutation applied may no longer be correct (e.g., student was already transferred out — their status is now 'transferred' but the plan still says 'promote').

**The plan snapshot stored in `YearTransitionLog.plan_snapshot` also reflects the pre-transaction state**, not the actual state at time of write — making the audit log unreliable for forensics.

**Remediation:** Move `previewTransition()` call **inside** the `DB::transaction` closure, and add `SELECT ... FOR UPDATE` (pessimistic lock) on student rows being mutated:
```php
return DB::transaction(function () use ($sourceAyId, $targetAyId, $overrides, $admin) {
    $plan = $this->previewTransition($sourceAyId, $targetAyId, $overrides);
    // lock rows
    Student::whereIn('id', collect($plan['mutations'])->pluck('student_id'))
           ->lockForUpdate()->get(); // holds lock for duration of transaction
    // ... rest of execution
});
```

---

### BLOCK-4: `applyPromotion` class-resolution logic is ambiguous when multiple classes share the same `grade_level`

**Location:** `applyPromotion()` Task 3 implementation:
```php
$newClass = collect($classMap)->first(
    fn ($c) => $c->grade_level === $targetGrade && $c->name === $mutation['to_class_name']
) ?? collect($classMap)->first(fn ($c) => $c->grade_level === $targetGrade);
```

**The fallback** (`first(fn ($c) => $c->grade_level === $targetGrade)`) fires when a class name doesn't match. In a school with Kelas 5A and Kelas 5B (both `grade_level=5`), all students from both 4A and 4B whose class name doesn't exactly match a grade-5 target class name will be silently assigned to whichever grade-5 class `collect()->first()` returns — which is indeterminate (insertion order).

The preview stage sets `to_class_name = $student->class->name` (the **source** class name, not the target). A student in Kelas 4A would get `to_class_name = 'Kelas 4A'` but the target is `Kelas 5A` — the name never matches the first condition. The fallback always fires. In a multi-section school all grade-4 students land on the same arbitrary grade-5 class.

**Remediation:** Preview must set `to_class_name` to the **target** grade's matching class name (by convention or explicit mapping), not the source class name. Or use source-class → target-class explicit mapping built during class creation loop. Simplest fix: in `previewTransition`, set:
```php
$toClassName = $student->class->name; // same label, different grade — wrong
// Fix:
$toClassName = str_replace((string)$grade, (string)$nextGrade, $student->class->name);
// e.g. "Kelas 4A" → "Kelas 5A"
```
Add multi-section test: two grade-4 classes (4A, 4B) promoting to grade-5; assert 4A students land in 5A, 4B in 5B.

---

### BLOCK-5: No concurrent-execution prevention (two admins, simultaneous POSTs)

**Location:** `execute()` controller; `executeTransition()` service.

Two admins clicking "Konfirmasi & Terapkan" within the same second — or one admin with a double-click / network retry — will launch two concurrent `executeTransition()` calls. MySQL's default isolation level (REPEATABLE READ) does **not** prevent this: both transactions will pass the BLOCK-1 guard check (if added) simultaneously before either commits. Both will create classes and mutate students.

The plan has no advisory lock, no `INSERT IGNORE` idempotency key, and no DB-level unique constraint on the transition log (see BLOCK-1 for the migration fix).

**Remediation (must combine with BLOCK-1):**
```php
// At top of executeTransition(), before previewTransition call:
$lockKey = "year_transition_{$sourceAyId}_{$targetAyId}";
$lock = \Illuminate\Support\Facades\Cache::lock($lockKey, 120);
if (! $lock->get()) {
    throw new \RuntimeException('Transisi sedang berjalan. Tunggu hingga selesai.');
}
try {
    return DB::transaction(function () use (...) { ... });
} finally {
    $lock->release();
}
```

---

## Warning Findings (WARN — should fix, not blocking)

### WARN-1: `SuperAdmin` locked out of wizard

`YearTransitionPolicy::manage()` returns `$user->isSchoolAdmin()` only. `UserRole::SuperAdmin` (`super_admin`) cannot run or view transitions. This is almost certainly unintentional — SuperAdmin should have at minimum read access to the logs.

**Fix:** `return $user->isSchoolAdmin() || $user->isSuperAdmin();`

---

### WARN-2: `plan_snapshot` stores Eloquent model objects (non-serializable edge case)

`$plan` returned by `previewTransition()` includes `source_ay` and `target_ay` as `AcademicYear` Eloquent model instances. When Laravel casts `plan_snapshot` to JSON, Eloquent models serialize to their attribute arrays — this works today but `YearTransitionLog.plan_snapshot` should not contain raw Eloquent objects for API stability. If `AcademicYear` gains hidden fields or appends, the snapshot silently changes shape.

**Fix:** Convert to plain arrays before storing: `'plan_snapshot' => ['source_ay' => $plan['source_ay']->toArray(), ...]`.

---

### WARN-3: No navigation-away / unsaved-work guard in the Vue wizard

The Wizard.vue shell uses `currentStep` as in-memory Vue state. If the admin navigates to another Inertia page (browser back, sidebar click) and returns, the wizard resets to Step 1. All overrides and the dry-run plan are lost with no warning.

**Fix:** Add `onBeforeUnload` / Inertia `router.on('before', ...)` guard in `Wizard.vue` to show a browser confirm dialog when `currentStep > 1 && !submitted`.

---

### WARN-4: UX — no progress indication during `executeTransition` (potentially 10–30 seconds)

For a school with 200 students, the transaction loops 200 `Student::findOrFail()` + `Student::update()` + `StudentMutation::create()` — each triggering `Auditable` writes (audit log rows). Estimated: 600+ individual DB writes. At 5ms/write this is 3 seconds minimum; with network latency and audit overhead realistically 10–30s.

`Confirm.vue` sets `isSubmitting = true` and shows a spinner, which is correct. But `router.post()` (Inertia) has no progress streaming — the user sees a spinner for up to 30s with no feedback. Risk of admin thinking it hung and clicking again (race with BLOCK-5).

**Fix:** Convert `POST /year-transition/execute` to return a job dispatch ID; poll for completion. Or at minimum add explicit copy: "Proses membutuhkan waktu ~30 detik untuk 200 siswa. Jangan tutup halaman ini."

---

### WARN-5: `StudentMutationFactory` placed in Task 12 but needed by Task 2/3 tests — ordering risk

The factory is created in Task 12 (nav menu task) but is required in `YearTransitionServiceTest.php` (Task 2, the `transfer_in` warning test). If tasks are executed in order and Task 2's tests are run before Task 12, they will fail with a factory-not-found error.

**Fix:** Move `StudentMutationFactory` creation to Task 1 (alongside model setup) or Task 2.

---

### WARN-6: `applyExit` sets `class_id = null` but plan's write coverage is silent about grades/attendance FK impact

When a student with `action=transfer_out` or `dropout` has their `class_id` set to `null`, existing attendance rows (which have `class_id` as a non-nullable FK with `cascadeOnDelete`) are **not** affected by `SET NULL` on the student — they hold their own `class_id` FK independently. This is correct and safe. However the plan does not explicitly state this, creating uncertainty during code review. Add a comment in `applyExit()`.

---

## Approved Strengths (PASS)

- `students.class_id` confirmed nullable in migration `2024_01_05_000001_create_students_table.php` — "set NULL for graduates" is valid.
- `TeachingAssignment` is NOT touched by this plan — `Meeting::generateForTeachingAssignment()` auto-fire trap is correctly avoided. Out-of-scope note in plan is accurate.
- `AuditLog` model does NOT use the `Auditable` trait — no infinite audit loop risk.
- `DB::transaction` wraps all class creation + student mutations + log write — core atomicity shape is correct (subject to BLOCK-2/BLOCK-3 caveats).
- `isSchoolAdmin()` method confirmed to exist on `User` model and returns correct enum comparison.
- `students.class_id` FK is `SET NULL` on class delete — historical grades/attendance/report_cards keep their own `class_id` FK and are unaffected by student re-pointing.
- `confirmation_word: required|in:TERAPKAN` validated server-side in `ExecuteRequest` — TERAPKAN gate enforced at API layer, not just UI.
- `different:source_academic_year_id` rule in both FormRequests — source=target AY correctly rejected.
- Old-AY classes are never deleted; plan explicitly states this throughout — no cascade risk to historical data.
- `restoreFromLog` stub throws `RuntimeException` — safe placeholder, no accidental partial restore.
- TDD structure (RED → GREEN commits) is sound; 21 planned tests are meaningful.

---

## Test Coverage Gaps to Add

1. **Double-execute guard** — execute on (source, target) pair that already has target-AY classes → expect `RuntimeException`.
2. **Multi-section promotion** — Kelas 4A + 4B both exist; assert 4A students → 5A, 4B students → 5B (not both to 5A). This will expose BLOCK-4.
3. **Student with `class_id = null` (orphan)** — active student with no class; preview must handle gracefully (currently `$student->class->grade_level` throws `null` property access).
4. **Source AY has zero students** — preview returns empty mutations, execute creates classes but writes no mutations or log? Or should it throw?
5. **Kelas 6 retained student** — retain override on grade-6 student; `$classMap` must contain a grade-6 class in the new AY (it will — copied from source); assert student lands in new grade-6 class, not graduated.
6. **Auth::id() = null in service context** — call `executeTransition` without `actingAs`; assert `AuditLog::create` does not throw (verify `audit_logs.user_id` is nullable).
7. **Target AY already has classes from partial prior run** — same as gap 1 but tests the specific state where 2 of 3 source classes already exist in target AY.
8. **Inconsistent state: student status='active' but has a `transfer_out` mutation as most recent** — plan says "pre-filtered by status", but this edge case slips through the status filter. Preview should flag with warning.
9. **`confirmation_word = 'terapkan'` (lowercase)** — must return 422 (case-sensitive, confirmed by `in:TERAPKAN` rule — add test to document intent).
10. **Empty class (no students)** — source AY has Kelas 3A with 0 active students; new-AY class should still be created; summary counts all 0.

---

## Recommended Plan Edits

### 1. Migration — add unique constraint (fixes BLOCK-1 + BLOCK-5)
```diff
  $table->json('plan_snapshot');
  $table->string('ip_address', 45)->nullable();
  $table->timestamps();
+ $table->unique(['source_academic_year_id', 'target_academic_year_id'], 'ytl_unique_transition');
```

### 2. `executeTransition` — guard + lock + move preview inside transaction (fixes BLOCK-1, BLOCK-3, BLOCK-5)
```diff
 public function executeTransition(int $sourceAyId, int $targetAyId, array $overrides, User $admin): YearTransitionLog
 {
-    $plan = $this->previewTransition($sourceAyId, $targetAyId, $overrides);
-
-    return DB::transaction(function () use ($plan, $sourceAyId, $targetAyId, $overrides, $admin) {
+    $lockKey = "year_transition_{$sourceAyId}_{$targetAyId}";
+    $lock = \Illuminate\Support\Facades\Cache::lock($lockKey, 120);
+    if (! $lock->get()) {
+        throw new \RuntimeException('Transisi sedang berjalan oleh pengguna lain. Coba lagi sebentar.');
+    }
+    try {
+        return DB::transaction(function () use ($sourceAyId, $targetAyId, $overrides, $admin) {
+            if (SchoolClass::where('academic_year_id', $targetAyId)->exists()) {
+                throw new \RuntimeException('Target tahun ajaran sudah memiliki kelas. Transisi mungkin sudah dijalankan.');
+            }
+            $plan = $this->previewTransition($sourceAyId, $targetAyId, $overrides);
+            // Lock student rows for duration of transaction
+            Student::whereIn('id', collect($plan['mutations'])->pluck('student_id'))
+                   ->lockForUpdate()->get();
             // 1. Create new-AY classes
             ...
-    });
+        });
+    } finally {
+        $lock->release();
+    }
 }
```

### 3. `previewTransition` — fix `to_class_name` for promotions (fixes BLOCK-4)
```diff
 if ($action === 'promote') {
     $nextGrade   = self::GRADE_STEP[$grade] ?? null;
-    $toClassName = $nextGrade ? $student->class->name : null;
+    // Replace source grade digit(s) with target grade in class name
+    // e.g. "Kelas 4A" → "Kelas 5A"
+    $toClassName = $nextGrade
+        ? preg_replace('/\b' . $grade . '\b/', (string)$nextGrade, $student->class->name)
+        : null;
```

### 4. `YearTransitionPolicy` — include SuperAdmin (fixes WARN-1)
```diff
 public function manage(User $user): bool
 {
-    return $user->isSchoolAdmin();
+    return $user->isSchoolAdmin() || $user->isSuperAdmin();
 }
```

### 5. Move `StudentMutationFactory` to Task 1 (fixes WARN-5)

Move the factory definition from Task 12 body into Task 1's "Files created" list.

---

## Final Recommendation

**EDIT-AND-PROCEED**

Five blockers require edits before execution begins. None requires a rewrite — the plan's architecture is sound. Fix order:

1. BLOCK-4 first (affects preview logic that all tests depend on).
2. BLOCK-1 + BLOCK-5 together (migration + service guard + cache lock — one coherent change).
3. BLOCK-3 (move preview inside transaction).
4. BLOCK-2 (verify `audit_logs.user_id` nullability; add auth context note to service).
5. Add missing tests (gaps 1–4 are the most critical).

Estimated additional work: **3–4 hours** on top of the planned 12–16h.
