# Phase 7 E2E Test Report

**Date:** 2026-05-08
**Branch:** chore/remove-tenant-leftovers
**Tag:** phase7-school-year-transition-complete
**Test mode:** Headless Chromium via Playwright, 11 parallel Sonnet sub-agents

---

## Executive Summary

Phase 7's school-year transition wizard (5-step) and its supporting CRUD surfaces (Academic Year, Semester) were exercised across 11 parallel scenarios covering: wizard happy path, per-step isolation, edge cases (CSRF, stale plan hash, concurrent preview, browser back), authorization, and logs page. Of 11 scenarios, **9 passed and 2 failed**. The wizard core is functionally sound — navigation, state preservation across back/forward, and the dry-run preview are all correct. The TERAPKAN gate (type-to-confirm) is working. DB integrity is confirmed clean (zero mutations written during preview).

Two failures require attention before production: `/year-transition/logs` returns HTTP 500 because the `year_transition_logs` migration was not run in the dev environment, and the Academic Year CRUD delete flow has an automation-detected regression (row still visible after delete). Neither is a data-corruption risk, but the migration gap would prevent any admin from viewing transition history on first deploy. Three WARN-class issues — no `beforeunload` guard on wizard back, no server-side plan integrity hash between preview and execute, and `APP_DEBUG=true` leaking stack traces on 419 — require fixes before production traffic. The missing "estimated student count" column in Step 2 is a spec deviation that reduces admin visibility.

**Ship verdict: BLOCK-UNTIL-FIXED** on the migration gap (HIGH) and delete regression (WARN). All wizard-flow WARNs can ship with risk acknowledged if timeline pressure exists, but the migration must run and the delete must be verified before any real school data is touched.

---

## Scope: 11 Scenarios Run

| # | Scenario | Slug | Verdict | Top Severity |
|---|----------|------|---------|--------------|
| S01 | Dashboard smoke | s01-dashboard | PASS | INFO |
| S02 | Wizard Step 1 — SelectYears | s02-year-transition-step1-select-years | PASS | WARN |
| S03 | Wizard Step 2 — ClassStructure | s03-year-transition-step2-class-structure | PASS* | WARN |
| S04 | Wizard Step 3 — StudentReview | s04-year-transition-step3-student-review | PASS | MEDIUM |
| S05 | Wizard Step 4 — Preview (Dry Run) | s05-year-transition-step4-preview | PASS | INFO |
| S06 | Wizard Step 5 — Confirm | s06-year-transition-step5-confirm | PASS | INFO |
| S07 | Transition Logs page | s07-year-transition-logs | FAIL | HIGH |
| S08 | Academic Year CRUD | s08-academic-year-crud | FAIL | WARN |
| S09 | Semester CRUD | s09-semester-crud | PASS | LOW |
| S10 | Authorization & Role Gating | s10-authorization | PASS | PASS |
| S11 | Wizard E2E Happy Path (full flow) | s11-wizard-e2e-happy-path | PASS | INFO |
| S12 | Edge Cases (7 sub-tests) | s12-edge-cases | PASS | WARN |

\* S03 passed functionally but flagged a BLOCK-candidate finding (Step 3 skeleton visible) that was subsequently resolved by S04/S11 data confirming Step 3 does load student data — downgraded to WARN.

---

## Findings by Severity

### HIGH (must fix before first production deploy)

| ID | Scenario | Issue | Location | Fix |
|----|----------|-------|----------|-----|
| H-01 | S07 | `year_transition_logs` table missing → HTTP 500 on `/year-transition/logs` | DB migration not run | `php artisan migrate` in every deploy environment; add to deploy checklist |

### WARN (should fix before production traffic)

| ID | Scenario | Issue | Location | Fix |
|----|----------|-------|----------|-----|
| W-01 | S08 | AY delete flow: row still visible after delete — Playwright harness assertion failure; possible Inertia page reload timing issue or a real delete bug | `AcademicYearController::destroy` / Playwright timing | Verify delete backend; add `waitForURL` / Inertia reload wait in test; screenshot `08_error_state.png` |
| W-02 | S08 | Activate swap may not deactivate old AY — `2070/2071` remained `is_active=true` after activating new AY in test; flash message showed stale text | `AcademicYearController::activate` | Audit activate transaction; confirm DB swap is atomic; screenshot `05_05-after-activate.png` |
| W-03 | S12/EC-7 | No `beforeunload` guard in Wizard — browser back from any step loses all wizard state silently | `Wizard.vue` | Add `window.onbeforeunload` on steps 2–5; clear on Step 5 execute |
| W-04 | S12/EC-5 | No server-side plan integrity hash between preview and execute — data changed between the two steps runs silently | `ExecuteRequest` + execute controller | Store a session/cache hash of preview summary at preview time; compare on execute |
| W-05 | S12/EC-4 | `APP_DEBUG=true` leaks full PHP stack trace on 419 CSRF — exposes internal paths | `.env` / `APP_DEBUG` | Set `APP_DEBUG=false` in staging/prod; already expected but must be verified in deploy |
| W-06 | S03 | Missing "Jumlah Siswa Estimasi" column in Step 2 class table — spec deviation, admins cannot see estimated student counts per new class | `ClassStructure.vue` template | Add student count column sourced from preview payload |
| W-07 | S02/S03/S04 | 16 academic years in dev DB with 12+ entries sharing label `"2026/2027 - Ganjil"` — admins cannot reliably select the right source AY | Seed data + no uniqueness constraint on `name` | Add `unique` constraint to `academic_years.name`; clean up dev seed |
| W-08 | S02 | Stale validation error persists after user selects valid AY — red banner stays until button clicked again | `SelectYears.vue` | Add `watch([sourceAyId, targetAyId], () => { error.value = '' })` |

### LOW / NIT (defer, cosmetic)

| ID | Scenario | Issue | Severity |
|----|----------|-------|----------|
| L-01 | S04 | No client-side gate blocks "Buat Preview" when override reasons are empty — red borders are cosmetic only | MEDIUM |
| L-02 | S04 | "Lewati" (skip) action absent from student action dropdown | LOW |
| L-03 | S07 | Logs table missing `excluded_count` column — detail page has it, list does not | LOW |
| L-04 | S07 | Empty state uses inline table row, not shared `EmptyState` component | MEDIUM |
| L-05 | S07 | Download button has no null-check on `plan_snapshot` | LOW |
| L-06 | S09 | Flash message after semester activate shows truncated `"Aktif"` | LOW |
| L-07 | S03 | Wali kelas cell shows `"(Belum ditentukan)"` vs spec text `"Wali kelas akan diisi setelahnya"` | NIT |
| L-08 | S06 | Button label `"Konfirmasi & Terapkan Transisi"` differs from spec `"TERAPKAN PERUBAHAN"` | NIT |
| L-09 | S02 | Step label text truncation in step indicator bar | NIT |
| L-10 | S02 | `<FormSelect>` missing `<label for>`/`id` pairing — a11y gap | NIT |
| L-11 | ALL | WebSocket/Pusher/Reverb `localhost:8080` 404/SSL errors on every page load | INFO (dev env) |

---

## Findings by Component

### `/year-transition` Wizard

**Step 1 — SelectYears:** Functional. Two WARNs: stale error banner (W-08) and ambiguous duplicate AY labels (W-07). Navigation to Step 2 correct.

**Step 2 — ClassStructure:** Functional. Missing estimated student count column (W-06). Sparse dev seed (1 class) limits coverage of multi-grade scenarios. No validation when all classes excluded — user can proceed to Step 3 with empty selection.

**Step 3 — StudentReview:** Functional — S04 and S11 both confirm student data loads. Original S03 BLOCK (skeleton-only within 1s timeout) is a test timing artifact, not a real bug. LOW gap: override-reason validation is cosmetic only (L-01).

**Step 4 — Preview (Dry Run):** Clean. All 4 stat cards render. Tab navigation (Naik Kelas, Lulus, etc.) works. Download button functional. DB confirmed zero mutations written. State preserved correctly on back/forward re-navigation.

**Step 5 — Confirm:** Clean. Type-to-confirm gate (`TERAPKAN`, case-sensitive, emerald highlight) works correctly. Back navigation resets confirm input (correct security behavior). Execute button never triggered in test — DB integrity confirmed.

### `/year-transition/logs` Pages

FAIL — 500 on page load due to missing migration (H-01). Static code review found: missing `excluded_count` column in list table (L-03), non-standard empty state (L-04), no null-guard on download (L-05). Logs detail page (not testable in dev) was reviewed statically only.

### `/academic-years` CRUD

FAIL — delete regression (W-01). Create/read/activate covered: create with flash message PASS, activate swap suspicious (W-02). Delete guard (blocked when AY has classes) tested and worked. 16-row dev DB with 12 duplicate labels (W-07).

### `/academic-years/{ay}/semesters` CRUD

PASS. All steps: list, create (2 semesters), max-2 UI gate, activate (per-AY scoped), uniqueness validation (server 302 redirect-back), delete. Only LOW finding: truncated flash message (L-06).

### Authorization & Role Gating

PASS. Teacher and student: nav item hidden, `/year-transition` returns 403, `/academic-years` accessible (read-only, by design). School admin: nav visible, `/year-transition` accessible, CRUD gated. No privilege escalation found.

---

## Recurring Themes (cross-cutting)

### 1. Dev DB data hygiene

16 academic years exist; 12–13 share the identical label `"2026/2027 - Ganjil"`. This affects every wizard step that shows an AY dropdown and makes E2E results hard to interpret. **Fix:** add `UNIQUE` constraint on `academic_years.name`; run a cleanup migration to deduplicate; revise seeders. This is a dev-only issue but will become a real user problem if name uniqueness is not enforced in `StoreAcademicYearRequest`.

### 2. Plan integrity (preview ↔ execute drift)

`plan_hash` visible in Step 5 UI is a client-side djb2 hash of summary counts only. `ExecuteRequest::rules()` has no `plan_hash` field — server ignores it. The execute endpoint re-runs `previewTransition()` inside its DB transaction, so the executed plan is always fresh, but the preview shown to the admin may differ from what actually executes if student enrollments change in the interval. No warning is surfaced. **Fix:** store a cache-keyed preview snapshot hash at preview POST time; compare on execute POST; return 409 with "Data changed since preview" if mismatch.

### 3. Validation surface gaps

Two unrelated surfaces have cosmetic-only validation: (a) Step 3 "Buat Preview" emits `next` unconditionally even when override reasons are blank — red borders are decorative; (b) Step 2 allows advancing with zero classes selected. Both reach server with potentially invalid/incomplete data. Server may or may not catch them; the UX should block navigation.

### 4. UX polish gaps

Label inconsistencies: nav button changes from "Berikutnya" (Steps 1-2) to "Buat Preview" (Step 3) without clear UX rationale. Spec/implementation mismatches on button label (Step 5), wali-kelas cell text (Step 2). Step indicator bar truncates long step labels on narrow viewports. None are blockers, but collectively create an inconsistent feel.

---

## Screenshots Manifest

| Scenario | Key Screenshots |
|----------|----------------|
| S01 | `01_dashboard_initial.png`, `02_dashboard_full.png` |
| S02 | `01_initial_wizard.png`, `02_validation_error.png` ← stale error, `03_years_selected.png` |
| S03 | `03_step2_class_structure.png`, `05_step3_initial.png` ← skeleton state |
| S04 | `04_step3_student_review.png` (full student list visible) |
| S05 | `06_step4_preview_loaded.png` ← stats, `07_step4_table_and_tabs.png`, `10_step4_after_download.png` |
| S06 | `11_11_step5_terapkan_typed_button_enabled.png` ← gate active, `12_12_step5_safe_state.png`, `14_14_step5_after_return.png` |
| S07 | `01_logs_index_initial.png`, `02_unexpected_state.png` ← 500 error |
| S08 | `05_05-after-activate.png` ← activate suspect, `06_06-after-guard-delete-attempt.png`, `08_error_state.png` ← delete fail |
| S09 | `04_07-after-activate.png`, `06_09-after-uniqueness-test.png`, `12_12-final-state-ay15.png` |
| S10 | `02_teacher_year_transition_attempt.png` ← 403, `08_school_admin_year_transition_attempt.png` ← 200 |
| S11 | `05_step4_preview.png` ← stat cards, `06_step5_confirm.png`, `11_refwd_step4.png` ← state consistency |
| S12 | `05_ec4_result.png` ← 419+stack trace, `09_ec7_after_browser_back.png` ← state loss, `06_ec5_result.png` ← plan_hash gap |

---

## Phase 8 Fix Plan (Recommended)

**Critical fixes (before any production deploy):**
1. **Run migrations** — `php artisan migrate` for `year_transition_logs` table; add to deploy runbook (resolves H-01).
2. **Verify AY delete** — confirm `AcademicYearController::destroy` actually deletes; add Inertia page-reload wait in E2E harness; re-run S08 (resolves W-01).
3. **Audit AY activate swap** — ensure the activate transaction sets old active AY to inactive atomically; add DB assertion to S08 (resolves W-02).
4. **`APP_DEBUG=false` in staging/prod** — enforce via environment check or deploy gate (resolves W-05).

**High-priority fixes (next sprint):**
5. **`beforeunload` guard** in `Wizard.vue` for steps 2–5 (resolves W-03).
6. **Server-side plan hash** — cache preview summary hash in session at `/preview` POST; validate at `/execute` POST; return 409 on mismatch (resolves W-04).
7. **Estimated student count column** in Step 2 `ClassStructure.vue` (resolves W-06).
8. **AY name uniqueness constraint** — add `UNIQUE` to `academic_years.name` in migration + `StoreAcademicYearRequest`; clean up dev seed (resolves W-07).
9. **Stale error clear** in `SelectYears.vue` — `watch([sourceAyId, targetAyId], () => { error.value = '' })` (resolves W-08).

**Nice-to-have polish:**
10. Step 3 `handleNext()` — validate all `localOverrides` have non-empty reasons before emitting `next` (resolves L-01).
11. Step 2 — block "Lanjutkan" when zero classes are selected.
12. Logs list — add `excluded_count` column (resolves L-03).
13. Logs list — replace inline empty-state table row with shared `EmptyState` component (resolves L-04).
14. Logs download — null-check `plan_snapshot` before `createObjectURL` (resolves L-05).
15. `FormSelect` — add `id`/`for` label pairing for a11y (resolves L-10).

---

## Test Coverage Gaps

| Gap | Risk | Notes |
|-----|------|-------|
| Execute (actual commit) not triggered | HIGH | S06 typed "TERAPKAN" but never clicked submit — real execute path untested |
| `/year-transition/logs` detail page | HIGH | Untestable until H-01 migration fixed |
| Multi-grade school (5–6 classes) | MEDIUM | Dev seed has 1 class in active AY; full promotion matrix untested |
| Mid-execute crash recovery | MEDIUM | No rollback/resume scenario tested |
| 100+ student dataset | MEDIUM | Only 4 students in test AY; pagination and performance untested |
| Kelas 6 graduation path | MEDIUM | No Grade 6 students in seed; graduated=0 in all runs |
| Orphan student (no class enrollment) | LOW | F5 flagged, no seed data to test |
| Parent role mobile | LOW | No parent role tested; mobile viewport not used |
| Semester activate when AY is active | LOW | Activation interaction between AY status and semester status not covered |
| Concurrent wizard execution | LOW | Only concurrent preview tested (EC-6); concurrent execute not tested |

---

## Appendix: Per-Scenario Detail

### S01 — Dashboard Smoke

PASS. Nav item "Kenaikan Kelas" visible for admin. 4 stat cards rendered. Only finding: WebSocket 404 on every page load (dev environment, INFO).
Screenshots: `01_dashboard_initial.png`, `02_dashboard_full.png`.

### S02 — Wizard Step 1: SelectYears

PASS. Source/target dropdowns render. Validation fires on empty submit ("Pilih tahun ajaran tujuan." error message). Valid selection advances to Step 2.
Findings: duplicate AY labels in dropdown (W-07, 12 of 16 entries identical); stale error banner after valid re-selection (W-08); step label truncation (L-09); FormSelect a11y gap (L-10).
Screenshots: `02_validation_error.png` (stale error), `03_years_selected.png`.

### S03 — Wizard Step 2: ClassStructure

PASS (functionally). Step 2 table renders with correct columns (checkbox, Nama Kelas, Tingkat, Wali Kelas). Defaults pre-selected. "Lanjutkan" advances.
Findings: missing estimated student count column (W-06); wali kelas text mismatch NIT (L-07); sparse 1-class dev seed limits coverage; original BLOCK (skeleton in Step 3 within 1s) resolved by S04/S11 data — downgraded to WARN timing gap.
Screenshots: `03_step2_class_structure.png`.

### S04 — Wizard Step 3: StudentReview

PASS. Student list loads (4 students, all grade 3, action "promote"). Action dropdowns functional.
Findings: "Buat Preview" emits `next` unconditionally even with empty override reasons — red borders are cosmetic only (L-01, MEDIUM); "Lewati" missing from dropdown (L-02); duplicate AY labels repeated (W-07 cross-reference).
Screenshots: `04_step3_student_review.png`.

### S05 — Wizard Step 4: Preview (Dry Run)

PASS. Preview stat cards: promoted=4, graduated=0, retained=0, excluded=0. Tab navigation (per-action tabs) works. Download button triggers file download. StudentMutation DB count delta=0 confirmed (dry run does not write).
No new findings beyond INFO (WebSocket noise). Step 4 re-navigation from back/forward shows consistent stats.
Screenshots: `06_step4_preview_loaded.png`, `07_step4_table_and_tabs.png`, `10_step4_after_download.png`.

### S06 — Wizard Step 5: Confirm

PASS (7/7 checks). Warning banner visible. 4 summary stat cards correct. Type-confirm input gate works (wrong word → disabled; "TERAPKAN" → enabled, emerald highlight). Back navigation resets input. Execute not triggered — DB clean.
Findings: INFO only — `year_transition_logs` table not yet created (same root as H-01); button label differs from spec (L-08).
Screenshots: `11_11_step5_terapkan_typed_button_enabled.png`, `14_14_step5_after_return.png`.

### S07 — Transition Logs Page

FAIL. HTTP 500 on `/year-transition/logs` — `SQLSTATE[42P01]: relation "year_transition_logs" does not exist`. Migration not run (H-01). Page UI exercised via static code review only.
Findings: missing `excluded_count` column in list (L-03); non-standard empty state (L-04); no null-guard on download (L-05); no "Kembali ke Wizard" button (LOW, by design).
Screenshots: `02_unexpected_state.png` (500 page).

### S08 — Academic Year CRUD

FAIL. Create: PASS. Activate: suspicious — old AY `2070/2071` remained active after activating test AY (W-02). Delete: Playwright assertion failure — test AY row still visible after delete (W-01). Delete guard (blocked on AY with classes): PASS. 16-row table with 12 duplicate labels confirmed (W-07).
Screenshots: `05_05-after-activate.png`, `08_error_state.png`.

### S09 — Semester CRUD

PASS. Create 2 semesters for AY 15: PASS. Max-2 UI gate (create button hidden): PASS. Activate scoped per `academic_year_id` (no cross-AY leakage): PASS. Uniqueness per AY (server 302 redirect-back on duplicate): PASS. Delete with confirm dialog: PASS.
Findings: truncated flash after activate (L-06); WebSocket 404 INFO.
Screenshots: `07_07-after-activate.png`, `09_09-after-uniqueness-test.png`, `12_12-final-state-ay15.png`.

### S10 — Authorization & Role Gating

PASS. Teacher: "Kenaikan Kelas" nav hidden, `/year-transition` → 403, `/academic-years` → 200 (read-only, by design). Student: same gates as teacher. School admin: nav visible, all mutation endpoints accessible. No privilege escalation. RBAC gates functioning correctly.
Screenshots: `02_teacher_year_transition_attempt.png`, `08_school_admin_year_transition_attempt.png`.

### S11 — Wizard E2E Happy Path (Full Flow)

PASS (13/13 checkpoints). Complete flow S1→S2→S3→S4→S5; back navigation S5→S1; re-forward to S4 with consistent stats. DB integrity: `year_transition_logs` delta=0, `student_mutations` delta=0. Execute gate: PASS (button disabled throughout — correct).
Preview payload: source AY `2070/2071` (active, id=15), target `2065/2066` (id=16 — older year, test data anomaly not a bug). 4 students all promoted.
Screenshots: `05_step4_preview.png`, `06_step5_confirm.png`, `11_refwd_step4.png`.

### S12 — Edge Cases (7 sub-tests)

PASS overall. No BLOCK issues found.

| EC | Result |
|----|--------|
| EC-1 Source=Target AY | PASS — client filters + server 422 both fire |
| EC-2 No active AY | PASS — blank dropdown, no crash |
| EC-3 Empty source AY | PASS — 200 empty plan, graceful |
| EC-4 No CSRF token | PASS — 419, but stack trace leaked (W-05) |
| EC-5 Mutated plan_hash | WARN — server ignores hash entirely (W-04) |
| EC-6 Concurrent preview | PASS — both 200, idempotent, 393ms wall |
| EC-7 Browser back | WARN — wizard state lost, no beforeunload guard (W-03) |

Screenshots: `05_ec4_result.png`, `06_ec5_result.png`, `09_ec7_after_browser_back.png`.

---

## Ship Verdict

**BLOCK-UNTIL-FIXED**

Mandatory before production:
- Run `year_transition_logs` migration (H-01) — logs page 500 blocks audit trail visibility.
- Verify AY delete and activate swap correctness (W-01, W-02) — data integrity risk on CRUD used to set up transition.

All wizard flow WARNs (W-03 through W-08) can ship with risk acknowledged if forced by timeline, but W-04 (stale plan) and W-03 (no back guard) are strongly recommended pre-launch fixes.
