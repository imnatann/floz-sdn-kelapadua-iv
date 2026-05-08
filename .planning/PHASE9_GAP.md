# Phase 9 — Execute Path Test Coverage Gap Analysis
_Audited: 2026-05-08 | Auditor: Claude Code_

---

## 1. Test Inventory

### Feature/YearTransition/ExecuteTest.php (10 tests)
| # | Test name | Scenario |
|---|-----------|----------|
| 1 | execute returns 422 without TERAPKAN confirmation word | Wrong confirmation word |
| 2 | execute returns 422 with lowercase terapkan (case-sensitive) | Lowercase confirmation |
| 3 | execute commits transition and returns log id | Happy path (shallow — 5A+6A only) |
| 4 | execute returns 403 for non-admin users | Auth gate |
| 5 | execute rolls back and returns 500 on service exception | Mock-based 500 path |
| 6 | execute returns 422 when plan_hash is missing | Missing plan_hash field |
| 7 | execute with valid plan_hash (from preview) succeeds | W-04 hash happy path |
| 8 | execute with stale plan_hash returns 409 | W-04 garbage hash |
| 9 | execute with expired/missing cache returns 409 | W-04 TTL expiry (Cache::flush) |
| 10 | execute returns 409 when target AY already has classes (idempotency) | BLOCK-1 double-execute |

### Unit/Services/YearTransitionServiceTest.php — executeTransition tests (7 tests)
| # | Test name | Scenario |
|---|-----------|----------|
| 1 | executeTransition creates new classes, re-points class_id, writes mutations and log | Happy path — grades 5+6, checks log counts |
| 2 | executeTransition rolls back all changes when an exception occurs mid-execution | Mid-flight DB error → full rollback |
| 3 | executeTransition assigns retained student to same-grade class in target AY | Retention routing (grade 3) |
| 4 | executeTransition throws when target AY already has classes | BLOCK-1 in service |
| 5 | executeTransition routes multi-section students to correct target class | Multi-section (4A/4B → 5A/5B) |
| 6 | it_writes_audit_log_inside_transaction — rollback removes audit entries | AuditLog inside txn |
| 7 | computePlanHash returns same/different hash | Hash determinism (2 tests) |

### Feature/YearTransition/PreviewTest.php (relevant only)
Covers preview-only paths — not the execute path. Not re-listed here.

---

## 2. Code Path Coverage Matrix

### executeTransition() — full branch map

| Branch / Block | Location | Status | Covered by |
|---|---|---|---|
| BLOCK-5: Cache::lock fails → RuntimeException 'sedang berjalan' | Service L182-184 | **MISSING** | No test acquires lock then calls execute |
| BLOCK-5: Controller maps lock exception → 409 | Controller catch block | **MISSING** | No feature test for concurrent 409 |
| BLOCK-1: Target AY already has classes → RuntimeException | Service L188-190 | COVERED | ServiceTest#4 + ExecuteTest#10 |
| BLOCK-3: previewTransition re-run inside txn (fresh data) | Service L192 | PARTIAL | No test verifies data changed between preview→execute is picked up |
| BLOCK-3: lockForUpdate on student rows | Service L194-197 | MISSING | No test verifies row-lock semantics |
| Create new-AY classes (classMap built) | Service L199-215 | COVERED | ServiceTest#1 |
| applyMutation → promote (grades 1-5) | Service L252/260 | PARTIAL | ServiceTest#1 (only grade 5→6), #5 (4→5) |
| applyMutation → promote, no grade step found → RuntimeException | Service L263-266 | MISSING | No test for unknown grade (e.g., grade 7) |
| applyMutation → graduate (grade 6 default) | Service L253/312 | COVERED | ServiceTest#1 (3 students) |
| applyMutation → retain (any grade) | Service L254/356 | COVERED | ServiceTest#3 |
| applyMutation → retain (grade 6 explicit override) | Service L254/356 | MISSING | No execute-level test — only preview-level |
| applyMutation → transfer_out/dropout → applyExit | Service L255/372 | MISSING | No execute-level test verifying student status+class_id |
| Zero students (source AY empty) → empty plan, no mutations | Service L219 | MISSING | No execute test (only preview E2E manual) |
| Audit log (YearTransitionLog::create) fields correct | Service L224-235 | PARTIAL | ServiceTest#1 checks counts; ip_address/executed_by NOT asserted |
| AuditLog (model-level) inside txn → rollback removes it | Service L223+ | COVERED | ServiceTest#6 |
| Rollback on mid-flight failure — no partial mutations | Service L274 | COVERED | ServiceTest#2 |
| Lock released in finally block | Service L239-241 | MISSING | No test verifies lock is released after success |
| plan_hash W-04: cache miss → 409 | Controller | COVERED | ExecuteTest#9 |
| plan_hash W-04: stale hash → 409 | Controller | COVERED | ExecuteTest#8 |
| plan_hash W-04: valid hash → proceed | Controller | COVERED | ExecuteTest#7 |
| source_academic_year_id = target → 422 (different rule) | ExecuteRequest | MISSING | No feature test (only E2E manual confirmed) |
| Active AY swap (source→inactive, target→active) | Service/Controller | **N/A** | Service does NOT implement this — no `is_active` update exists |
| Activate target semester after transition | Service/Controller | **N/A** | Not implemented in service |
| Multi-grade full ladder K1-K6 all populated | Service | MISSING | No test with all 6 grades simultaneously |
| Audit log count matches actual mutations | Service | PARTIAL | ServiceTest#1 checks promoted+graduated counts; retained_count not asserted |

---

## 3. Scenario Coverage Matrix (as requested)

| Scenario | Status | Test name |
|---|---|---|
| Source AY = target AY (validation `different`) | MISSING | — |
| Source AY has zero eligible students | MISSING | — |
| Some students orphaned (class_id null) — execute path | PARTIAL | preview-only (ServiceTest `preview excludes students with null class_id`) |
| Some students transferred mid-year (status=transferred) | PARTIAL | preview-only (ServiceTest `preview excludes students with status transferred`) |
| Multi-grade school (K-1 through K-6 all populated) | MISSING | — |
| Kelas 6 promotion → graduated (status=graduated, class_id=null) | COVERED | ServiceTest `executeTransition creates new classes...` |
| Kelas 6 retained (stays kelas 6 in new AY via override) | MISSING | Only in preview; no execute-level test |
| Concurrent execute → 409 via Cache::lock | MISSING | — |
| Stale plan_hash → 409 | COVERED | ExecuteTest `execute with stale plan_hash returns 409` |
| Expired plan_hash cache → 409 | COVERED | ExecuteTest `execute with expired/missing cache returns 409` |
| Mid-flight DB error → full rollback (no partial mutations) | COVERED | ServiceTest `executeTransition rolls back all changes...` |
| Audit log integrity (count matches actual mutations) | PARTIAL | ServiceTest#1 — promoted+graduated only; retained_count not asserted in isolation |
| Activate target semester after all mutations | N/A | Service does not implement; not testable |
| Active AY swap atomicity (target becomes active, source inactive) | N/A | Service does not implement `is_active` update |

---

## 4. Top Missing Scenarios by Risk

1. **Concurrent execute → 409** (CRITICAL) — BLOCK-5 lock path is live production code with zero test coverage. A race condition between two admin sessions could result in double-execution with no regression signal.

2. **Source AY = target AY validation** (HIGH) — `ExecuteRequest` has `different:source_academic_year_id` but no feature test exercises it. The rule is there; it just lacks a regression guard.

3. **Kelas 6 retained execute-path** (HIGH) — The override path for retaining a grade-6 student through `executeTransition` is untested. Preview covers it but the actual mutation writing (applyRetention with grade 6 + no classMap entry panic) has no coverage.

4. **Zero students — execute path** (MEDIUM) — Source AY with no classes/students causes `executeTransition` to run with empty `$plan['mutations']`; no class created, no log counts. Behavior is correct but unverified at execute level.

5. **Multi-grade full ladder K1→K6** (MEDIUM) — No test validates that all 6 promotion steps work atomically in one execute call (class naming correctness across all grades, correct StudentMutation count = N students).

6. **transfer_out/dropout execute mutation** (MEDIUM) — `applyExit` sets `class_id=null` + `status=transferred/dropout`. No unit or feature test asserts this at execute time.

7. **Audit log field completeness** (LOW) — `ip_address`, `executed_by`, `plan_snapshot` structure not asserted in any test.

---

## 5. Recommended New Tests (~10)

| # | File | Proposed name | Scope |
|---|------|---------------|-------|
| T1 | ExecuteTest | `execute returns 409 when cache lock is already held` | Mock `Cache::lock` to return false; assert 409 + Indonesian message |
| T2 | ExecuteTest | `execute returns 422 when source and target academic year are the same` | Same id for both fields; assert `different` validation error |
| T3 | ServiceTest | `executeTransition with zero eligible students writes empty log` | Source AY has classes but no active students; assert log counts all zero, no mutations |
| T4 | ServiceTest | `executeTransition grade 6 retained via override stays in new kelas 6` | Kelas 6A student + retain override; assert class_id points to new Kelas 6A in target AY |
| T5 | ServiceTest | `executeTransition transfer_out student gets class_id null and status transferred` | Student with transfer_out override; assert class_id=null, status='transferred', StudentMutation written |
| T6 | ServiceTest | `executeTransition full grade ladder K1-K6 creates 6 classes and correct mutation counts` | All grades 1-6 populated; assert 6 new classes, promotion chain correct, grade-6 → graduated |
| T7 | ServiceTest | `executeTransition audit log retained_count matches actual retained students` | Mix of promote/graduate/retain; assert log->retained_count == actual retained count |
| T8 | ServiceTest | `executeTransition audit log records executed_by and plan_snapshot` | Assert log->executed_by == admin->id, log->plan_snapshot is array with 'mutations' key |
| T9 | ServiceTest | `executeTransition orphaned students in source AY are excluded at execute time` | Orphan (class_id=null) coexists with normal students; assert orphan not in mutations, not in log count |
| T10 | ExecuteTest | `execute with overrides for transfer_out returns 200 and excluded_count in summary` | HTTP-level: override one student to transfer_out; assert summary.excluded == 1 |

---

## 6. Helper Utilities Needed

- **`makeFullGradeLadder(AcademicYear $ay): array`** — creates Kelas 1A–6A (6 classes) each with N students; returns `['classes' => [...], 'students' => [...]]`. Reusable across T6 and future tests.
- **`makeSchoolWithStudents(int $grade, string $className, int $count, ?AcademicYear $ay): array`** — already partially done by existing `makeClass`/`makeStudents` helpers; just needs a facade that returns both.
- **Cache lock helper** — a simple `Cache::lock($key, 120)->get()` pre-acquire in test setup to simulate a held lock; no new class needed, just a documented pattern.

---

## 7. Out of Scope (Skip-Acceptable for MVP)

- `lockForUpdate` semantics — requires parallel DB connections; SQLite test driver doesn't support. Acceptable to rely on integration/manual testing.
- Activate target semester — not implemented in service; out of scope until feature is built.
- Active AY `is_active` swap — service intentionally omits this (school admin manually switches AY); out of scope.
- `restoreFromLog` / undo — explicitly not implemented (`throw` in service); skip.
- Cross-user cache isolation — `cacheKey` scoped by `user->id`; low-risk, skip for MVP.
