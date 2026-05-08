# Scenario: s03-year-transition-step2-class-structure
_Started: 2026-05-08T11:07:14.024Z_

1. Navigate to /year-transition
⚠️  console.error: WebSocket connection to 'ws://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error during WebSocket handshake: Unexpected response code: 404
⚠️  console.error: WebSocket connection to 'wss://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error in connection establishment: net::ERR_SSL_PROTOCOL_ERROR
📸 01_01_step1_initial.png  (URL: http://127.0.0.1:8765/year-transition)
2. Read academic year options
   Found 16 AY options: 2070/2071 (Aktif), 2065/2066, 2026/2027 - Ganjil, 2026/2027 - Ganjil, 2026/2027 - Ganjil, 2026/2027 - Ganjil, 2026/2027 - Ganjil, 2026/2027 - Ganjil, 2026/2027 - Ganjil, 2026/2027 - Ganjil, 2026/2027 - Ganjil, 2026/2027 - Ganjil, 2026/2027 - Ganjil, 2026/2027 - Ganjil, 2026/2027 - Ganjil, 2025/2026
3. Select source and target AY
   Source: 2070/2071 (Aktif) (id=15)
   Target: 2065/2066 (id=16)
📸 02_02_step1_ay_selected.png  (URL: http://127.0.0.1:8765/year-transition)
4. Click Lanjutkan to go to Step 2
   Step 2 loaded
📸 03_03_step2_initial.png  (URL: http://127.0.0.1:8765/year-transition)
5. Verify class table renders
   Table rows: 1
   OK: 1 class rows rendered
6. Inspect row columns: grade level, section name input, wali kelas column
   Row 1: grade="Kelas 3" name="Kelas 3A" disabled=false wali="(Belum ditentukan)" checked=true
   OK: All grade labels match "Kelas N" pattern
   OK: All wali kelas cells show "(Belum ditentukan)"
   OK: All name inputs are enabled by default
   OK: No grades above 6 — source grade-6 classes correctly excluded (they graduate)
   Grade range in proposed list: min=3 max=3
7. Edit first section name
   Original: "Kelas 3A" → Edited: "Kelas 3A-EDITED"
   OK: Section name editing works
📸 04_04_step2_name_edited.png  (URL: http://127.0.0.1:8765/year-transition)
8. Test exclude checkbox
   Checkbox: true → false, name input disabled: true
   OK: Unchecking checkbox disables name input (excluded row)
9. Check info callout
   PPDB note visible: true
   Wali kelas note visible: true
10. Click Lanjutkan to advance to Step 3
   Lanjutkan button disabled: false
   OK: Advanced to Step 3
📸 05_05_step3_initial.png  (URL: http://127.0.0.1:8765/year-transition)
   Step 3 heading: "Langkah 3: Review Per Siswa"

=== Summary ===
Total proposed classes: 1
Grade range: 3-3
Grade-6 classes in proposal: 0 (promoted from grade 5)
INFO: No grade-5→6 promotion visible. Source AY may not have grade-5 classes, or all grade-5 students have been excluded.

✅ SCENARIO PASSED

_Finished: 2026-05-08T11:07:25.180Z_

---

## Manual Analysis — Extended Findings

### Data Correctness

- Active AY is `2070/2071` (id=15). Dev DB appears to be seeded with future/test years.
- Source AY `2070/2071` has only **1 class**: Kelas 3A (grade 3). Preview API returns `grade_level=3` (promoted from grade 2 in source — i.e., source class was grade 2 and proposed is grade 3).
- Grade-6 classes correctly absent from proposed list (graduating students excluded at API layer). **[VERIFY]** Cannot confirm from test run alone since no grade-5→6 promotion was observed; source AY may only have a single grade-2 class.
- No classes above grade 6 → SD (6-year primary) constraint respected. ✅
- Column "Tingkat" shows `Kelas 3` which is the **proposed** grade level (grade+1). Column header and data are consistent.

### UX / Layout Issues

**WARN — Estimated Student Count column missing (NIT→WARN)**
- Spec required: "estimated student count" per row.
- Actual table has columns: [checkbox] | Nama Kelas | Tingkat | Wali Kelas.
- **No "Jumlah Siswa Estimasi" / student count column** is rendered. The `ClassStructure.vue` template omits it entirely.
- Severity: **WARN** — spec deviation; admins have no visibility into how many students will be promoted to each new class.

**NIT — "Wali kelas akan diisi setelahnya" phrasing mismatch**
- Spec says each row should show note: "Wali kelas akan diisi setelahnya"
- Actual cell content: "(Belum ditentukan)" (italic, slate-400)
- Info callout says: "Wali kelas dapat diisi setelah transisi selesai melalui halaman edit kelas."
- Both convey the same meaning but the row cell uses a different string than spec expected.
- Severity: **NIT** — functionally fine, spec wording imprecise.

**NIT — Duplicate AY options in Step 1 select**
- Found 13 entries all labeled "2026/2027 - Ganjil" — seed data issue. Users cannot distinguish between them.
- Severity: **NIT** (dev-only DB seed artifact, not a code bug).

**WARN — Sparse source AY: only 1 class in active year**
- Active AY `2070/2071` has a single class (grade 3 only). This is an extreme sparse-data scenario. The wizard renders correctly with 1 row, but the real risk is admins using this with a fully populated school would see 5 rows (grades 1→2, 2→3, 3→4, 4→5, 5→6) — that case is untested.
- Severity: **WARN** — happy path only partially exercised due to thin dev seed data.

**BLOCK — Step 3 "Review Per Siswa" loads with skeleton-only state (no content visible)**
- Screenshot `05_step3_initial.png` shows Step 3 heading but **three large gray loading skeleton blocks** and no actual student data rendered within the test timeout (1 second post-click).
- If the API is slow or returns empty, students could be waiting indefinitely with no feedback.
- The nav button in Step 3 is "Buat Preview" (not "Berikutnya") — navigation label differs from Step 2.
- Severity: **BLOCK** — need to verify Step 3 eventually loads student data (not just skeletons); cannot confirm within E2E run.

### Edge Cases

- **Source has only grade-6 classes**: proposed list would be empty (all graduate). Empty state UI exists (`Tidak ada kelas ditemukan di tahun ajaran sumber.`) and renders correctly. Lanjutkan would still be clickable, passing `newClasses: []` to Step 3 — downstream behavior untested.
- **Source has no classes at all**: same empty-state path as above.
- **All classes excluded via checkbox**: `handleNext` filters excluded classes; `newClasses` passed to downstream would be `[]`. No validation prevents proceeding with zero active classes.
  - Severity: **WARN** — user could accidentally exclude all classes and proceed without warning.

### What Works

- Step indicator correctly shows Step 1 complete (green checkmark), Step 2 active (orange circle).
- Section name input: editable, orange focus ring on interaction. ✅
- Exclude checkbox: disables name input and applies `opacity-50` + `bg-slate-50` to row. ✅
- Info callout with PPDB note and wali kelas note: present and visible. ✅
- "Berikutnya" / "Lanjutkan" advances to Step 3 correctly. ✅
- "Sebelumnya" button present for back navigation. ✅

### Severity Summary

| # | Issue | Severity |
|---|-------|----------|
| 1 | No estimated student count column | WARN |
| 2 | Row wali kelas text "Belum ditentukan" vs spec "Wali kelas akan diisi setelahnya" | NIT |
| 3 | Duplicate AY labels in seed data | NIT |
| 4 | Only 1 class in active AY — sparse coverage | WARN |
| 5 | Step 3 loads with skeleton only; data not confirmed | BLOCK |
| 6 | No validation when all classes excluded | WARN |