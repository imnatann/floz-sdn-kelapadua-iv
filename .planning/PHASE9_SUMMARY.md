# Phase 9 — Execute-Path Coverage Sprint

**Date:** 2026-05-08
**Branch:** `chore/remove-tenant-leftovers`
**Tag:** `phase9-execute-coverage-complete`
**Driven by:** `.planning/PHASE9_GAP.md` audit (10 missing scenarios)
**Mode:** GSD pipeline — 1 audit agent → 2 parallel test executors (Sonnet)

---

## Goal

Close the biggest known coverage gap from the Phase 7 e2e audit: the YearTransition execute path had 8 covered scenarios and 10 missing — including the critical BLOCK-5 Cache::lock concurrent guard with **zero** test coverage.

---

## Tests Added (10/10 ✅)

### HTTP-Layer (Feature) — `tests/Feature/YearTransition/ExecuteTest.php` (commit `46d745b`)

| ID | Test | Severity Closed |
|----|------|-----------------|
| T1 | `execute returns 409 when cache lock is already held` | **CRITICAL** — BLOCK-5 was untested |
| T2 | `execute returns 422 when source and target academic year are the same` | HIGH — `different` rule had no regression guard |
| T10 | `execute with overrides for transfer_out returns 200 and excluded_count in summary` | MEDIUM — exit-mutation HTTP path |

### Service-Layer (Unit) — `tests/Unit/Services/YearTransitionServiceTest.php` (commit `496b96b`)

| ID | Test | Severity Closed |
|----|------|-----------------|
| T3 | `executeTransition with zero eligible students writes empty log` | MEDIUM |
| T4 | `executeTransition grade 6 retained via override stays in new kelas 6` | HIGH — execute-level retain panic risk |
| T5 | `executeTransition transfer_out override sets class_id null and status transferred` | MEDIUM — applyExit path |
| T6 | `executeTransition full grade ladder K1-K6 creates 6 classes and correct mutation counts` | MEDIUM — atomic 6-grade promote |
| T7 | `executeTransition audit log retained_count matches actual retained students` | LOW — log integrity |
| T8 | `executeTransition audit log records executed_by and plan_snapshot` | LOW — audit field completeness |
| T9 | `executeTransition orphaned students in source AY are excluded at execute time` | MEDIUM — orphan handling |

---

## Helper Added

`makeFullGradeLadder(AcademicYear $ay)` — file-level helper at top of YearTransitionServiceTest.php. Creates Kelas 1A-6A with N students each. Reusable for future multi-grade scenarios.

---

## Test Status

| Suite | Before Phase 9 | After Phase 9 | Delta |
|-------|----------------|---------------|-------|
| **Pest** | 282 (1183 assertions) | **292 (1237 assertions)** | +10 tests, +54 assertions |
| **Flutter** | 122 | 122 | unchanged |
| **Vite build** | OK | OK | clean |

---

## Bugs Found

**Zero.** All 10 tests pass against existing implementation — the code paths were correct, they just had no regression guard.

---

## Browser TERAPKAN E2E (Skipped)

The original Phase 9 plan included a Playwright E2E that clicks the actual TERAPKAN button against an isolated DB. This was skipped because:

1. **Auto-mode safety constraints** prevent unsupervised DB sandbox creation/destruction.
2. **Pest service + feature tests now provide deep coverage** of every execute branch including the concurrent lock, retention edge cases, and audit log integrity — the value of clicking through a browser is incremental.
3. **The wizard click flow** was already verified end-to-end in Phase 7 e2e audit (S06, S11) up to and including the TERAPKAN button enable state. The remaining click-and-mutate is exactly what the Pest feature test exercises via HTTP.

If desired in a future phase, the recommended setup is a separate Postgres `floz_e2e` database with explicit user-driven setup/teardown commands, not auto-managed.

---

## Phase 9 Commits

```
38a10d0 docs(phase9): execute path test coverage gap analysis
46d745b test(year-transition): comprehensive HTTP-layer execute coverage (T1, T2, T10)
496b96b test(year-transition): comprehensive service-layer execute coverage (T3-T9)
[next] docs(phase9): Phase 9 summary
```

---

## Cumulative State (post Phase 7 → Phase 9)

| Phase | Description | Tests | Tag |
|-------|-------------|-------|-----|
| Phase 7 | School-year transition wizard + backend | 269 → 269 | `phase7-school-year-transition-complete` |
| Phase 7 e2e | 11 parallel Playwright scenarios | 269 → 269 | `phase7-e2e-audit-complete` |
| Phase 8 | 8 WARN + 7 LOW fixes | 269 → 282 | `phase8-warn-fixes-complete` |
| Phase 9 | Execute-path coverage | 282 → **292** | `phase9-execute-coverage-complete` |

---

## Ship Verdict (Cumulative)

**SHIP — production-ready** for the school's July 2026 deployment, subject to the deployment checklist (`docs/DEPLOYMENT_CHECKLIST.md`) and post-deploy `php artisan migrate --force`.

The original highest-priority gap (BLOCK-5 concurrent execute) is now under regression coverage. The wizard flow is comprehensively tested at unit, integration, HTTP, and (for read paths) browser levels.

---

## Recommended Phase 10+ Candidates

1. **Phase 6 — Parent Mobile App** — original PRD candidate, builds on Phase 5 mobile foundation
2. **Phase 8.5 — Production Readiness Infra** — backup cron, monitoring, deploy automation (W-05 covered docs only)
3. **Phase 9.5 — Browser TERAPKAN E2E** — only worthwhile after a sandboxed DB approach is sanctioned
4. **Phase 11 — Reporting & Analytics Dashboard** — admin school-wide stats (NEXT_PHASE_CANDIDATES.md candidate #4)
