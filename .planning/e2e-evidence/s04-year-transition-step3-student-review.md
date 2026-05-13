# Scenario: s04-year-transition-step3-student-review
_Run: 2026-05-08T11:08:54Z → 11:10:14Z | Result: PASS_

## Screenshots
| # | File | Moment |
|---|------|--------|
| 01 | `01_step3_initial.png` | Step 3 initial load — Kelas 3A, 4 siswa, all "Naik Kelas" |
| 02 | `02_student_retain_no_reason.png` | Student 1 set to "Tinggal Kelas" — red border, no reason, override banner visible |
| 03 | `03_advanced_to_step4.png` | App advanced to Step 4 despite 2 students with empty reason fields |
| 04 | `04_reasons_filled.png` | Both reason inputs filled, red borders cleared |
| 05 | `05_step4_reached.png` | Step 4 "Preview Mutasi (Dry Run)" reached with reasons filled |

---

## Test Data Context
- Source AY: **2070/2071** (Aktif, id=15)
- Target AY: **2065/2066** (id=16)
- Students loaded: **4** students in **1 group** (Kelas 3A)
- No Kelas 6 students in dataset, no orphan students

---

## Checks

| Check | Result | Notes |
|-------|--------|-------|
| Step 1 → 2 navigation | PASS | |
| Step 2 → 3 navigation | PASS | |
| Step 3 heading "Langkah 3: Review Per Siswa" | PASS | |
| Table groups students by grade | PASS | 1 group: "Kelas 3A — 4 siswa" |
| Groups sorted ascending by grade level | PASS | only grade 3 in dataset |
| Column: Nama / NIS | PASS | name + NIS sub-line rendered |
| Column: Kelas Asal | PASS | |
| Column: Tindakan (action dropdown) | PASS | 5 options: Naik/Lulus/Tinggal/Mutasi/Putus |
| Column: Alasan (reason) | PASS | hidden when action is default |
| Column: Keterangan (warning) | PASS | dash when no warnings |
| Kelas 6 defaults to "Lulus" (graduate) | SKIP | no Kelas 6 students in active AY |
| Non-grade-6 students default to "Naik Kelas" | PASS | all 4 Kelas 3A students = promote |
| Reason input hidden for default action | PASS | |
| Reason input visible after non-default action | PASS | appears immediately on select change |
| Red border on empty required reason | PASS | `border-red-300` class applied |
| Red border clears after filling reason | PASS | |
| Override summary banner ("X siswa non-default") | PASS | appeared after first action change |
| Orphan student warning ("Tidak ada kelas") | SKIP | no students without from_class_id |
| "Tanpa Kelas" group visible | SKIP | no orphan data |
| Step 3 → Step 4 navigation ("Buat Preview") | PASS | |

---

## Findings

### FINDING F1 — MEDIUM: No client-side validation gate before "Buat Preview"
**Severity:** Medium  
**Observed:** When 2 students had non-default actions (retain + transfer_out) with empty reason
fields, clicking "Buat Preview" advanced the wizard to Step 4 without blocking or showing a modal.
The red borders on empty reason inputs are purely cosmetic — the `handleNext()` function in
`StudentReview.vue` emits `next` unconditionally without checking `localOverrides` for missing reasons.  
**Impact:** Overrides without reasons reach the preview/execute API, which may silently discard them
or create audit records with blank justifications.  
**Location:** `src/resources/js/Pages/YearTransition/Steps/StudentReview.vue` — `handleNext()`  
**Recommendation:** Before emitting `next`, validate that all `localOverrides` entries have a
non-empty `reason`. Show an inline error or toast blocking navigation.

### FINDING F2 — LOW: "Lewati" action absent from dropdown
**Severity:** Low / by-design  
**Observed:** Scenario spec referenced a "Lewati" action. The actual dropdown options are:
`promote` (Naik Kelas), `graduate` (Lulus), `retain` (Tinggal Kelas), `transfer_out` (Mutasi Keluar),
`dropout` (Putus Sekolah). There is no "Lewati/Skip" option.  
**Impact:** If spec intent was a "skip/no-action" sentinel, it is unimplemented. Orphan students
without a class are auto-skipped at the API level ("akan dilewati") rather than via a user-selectable action.  
**Recommendation:** Clarify whether a distinct "Lewati" action value is needed, or document that
orphan-student skip is implicit.

### FINDING F3 — LOW: Academic year list has duplicate labels
**Severity:** Low / data quality  
**Observed:** The source dropdown shows 12 entries all labeled "2026/2027 - Ganjil" with distinct
IDs (1–13 except some). This makes it impossible for an operator to distinguish between them.  
**Impact:** Operator cannot reliably identify which AY to select as source; wrong selection could
trigger a transition from the wrong dataset.  
**Recommendation:** Academic year names should be unique (enforce at DB level or via UI validation
on `academic-years.store`). Alternatively, append the ID or a suffix to disambiguate.

### FINDING F4 — INFO: WebSocket/Pusher noise in console
**Severity:** Info  
**Observed:** Every page load produces 2 `console.error` entries:
- `WebSocket ws://localhost:8080 … 404`
- `WebSocket wss://localhost:8080 … ERR_SSL_PROTOCOL_ERROR`  
**Impact:** None in dev environment, but would flood Sentry/error tracking in staging.  
**Recommendation:** Disable Pusher in dev config (`BROADCAST_DRIVER=log`) or configure a local
Soketi/Reverb instance.

### FINDING F5 — INFO: Kelas 6 / orphan student paths untestable with current seed data
**Severity:** Info  
**Observed:** Active AY (2070/2071) has only Kelas 3A students. No Kelas 6 students exist to
verify the `graduate` default logic, and no orphan students exist to verify the `from_class_id`
warning path.  
**Impact:** The `from_grade_level === 6 ? 'graduate' : 'promote'` logic in `StudentRow.vue`
is correct by code review but cannot be E2E verified without seed data.  
**Recommendation:** Add seed data to `2070/2071` with at least 2 Kelas 6 students and 1 student
with `from_class_id = null` to cover these branches.

---

## Summary Table

| ID | Severity | Title |
|----|----------|-------|
| F1 | Medium | No validation gate blocks "Buat Preview" when reasons are empty |
| F2 | Low | "Lewati" action not in dropdown (by design or gap) |
| F3 | Low | Duplicate AY labels make source selection ambiguous |
| F4 | Info | WebSocket/Pusher console errors on every page load |
| F5 | Info | Kelas 6 and orphan student branches not covered by current seed data |
