# Scenario: s09-semester-crud — Semester CRUD

_Run date: 2026-05-08 | Status: PASSED_

---

## Test Targets

| AY | Name | Purpose |
|----|------|---------|
| 14 | 2025/2026 | Read-only: table structure, existing Sem1 (inactive) + Sem2 (active) |
| 15 | 2070/2071 | CRUD: create, activate, uniqueness test, delete |

---

## Results by Step

### STEP 1 — List Table Structure (AY 14)
- URL: `/academic-years/14/semesters`
- Columns verified: **Semester, Periode, Status, Aksi** — all 4 present ✅
- 2 semester rows visible ✅
- Status badges: `{"Semester 1":"Tidak Aktif","Semester 2":"Aktif"}` ✅
- Action buttons: `Aktifkan` (for inactive), `Edit`, `Hapus` ✅

### STEP 2 — Create Semester (AY 15)
- Route: `GET /academic-years/15/semesters/create` → `POST /academic-years/15/semesters`
- Fields filled: `semester_number=1`, `start_date=2070-07-01`, `end_date=2070-12-20`
- Redirected to index on success: `Semester berhasil dibuat.` flash shown ✅
- Semester 1 appears in list as `Tidak Aktif` ✅

### STEP 3 — UI Gate (max 2 semesters)
- `Tambah Semester` link hidden when `semesters.length >= 2` ✅
- Note: button visible when < 2 semesters (correct per source: `v-if="canManage && semesters.length < 2"`)

### STEP 4 — Activate (per-AY scope)
- Activated Semester 1 in AY 15
- Before: `{"Semester 1":"Tidak Aktif"}`
- After: `{"Semester 1":"Aktif"}` ✅
- Server-side: `WHERE academic_year_id = ?` scoped deactivation — confirmed in controller
- AY 14 unaffected after AY 15 activation: `{"Semester 1":"Tidak Aktif","Semester 2":"Aktif"}` ✅
- **Cross-AY isolation: CONFIRMED** — activation does NOT touch semesters of other years

### STEP 5 — Uniqueness Validation
- POSTed `semester_number=1` again to AY 15 (already had Sem 1)
- Server returned HTTP 302 redirect-back (Inertia validation response pattern)
- URL stayed on `/semesters/create` → server rejected duplicate ✅
- Validation rule: `Rule::unique('semesters')->where('academic_year_id', $ayId)` confirmed in `StoreSemesterRequest`
- Error message defined: `"Semester ini sudah ada untuk tahun ajaran ini."`
- Note: Inertia returns 302+redirect-back for validation errors (not raw 422) — errors surfaced via shared error bag, not JSON response; direct `fetch()` approach returned 419 (XSRF mismatch) in early attempts

### STEP 6 — Delete
- Deleted Semester 1 from AY 15 via `router.delete(route('semesters.destroy', sem.id))`
- Confirm dialog shown: `"Hapus Semester 1? Pastikan tidak ada nilai atau rapor yang terkait."` ✅
- Semester removed from list ✅
- Final AY 15 state: empty (`"Belum ada semester untuk tahun ajaran ini."`) ✅
- DB count after cleanup: `Semester::count() = 2` (only AY14's Sem1+Sem2 remain) ✅

---

## Findings & Observations

### BUG (Low) — Flash message after activate shows truncated text
- Flash banner shows `"Aktif"` (one word) instead of `"Semester N sekarang aktif."` — the `Aktif` text may be leaking from the Badge component rendered before flash fades. Low severity, cosmetic.

### INFO — Semester number limited to 1 or 2 (by design)
- Form `<select>` only offers options 1 and 2. No "Semester 3" possible via UI or validated server-side (`Rule::in([1, 2])`).
- UI gate hides "Tambah Semester" button when 2 semesters already exist — prevents creation entirely via UI.

### INFO — Activate scoped correctly to academic_year_id (CONFIRMED)
- `Semester::where('academic_year_id', $semester->academic_year_id)->update(['is_active' => false])` — scope is per-AY, not global.

### INFO — Uniqueness per AY (CONFIRMED)
- `Rule::unique('semesters')->where('academic_year_id', $ayId)` — same semester_number CAN exist across different AYs.

### INFO — WebSocket console errors (non-blocking)
- All pages emit `WebSocket connection failed: 404` errors — Pusher/Laravel Echo not running in dev. No functional impact.

### INFO — Delete guard
- Controller checks `$semester->grades()->exists() || $semester->reportCards()->exists()` before delete — returns 422 if data exists. Not triggered in this test (clean test semesters).

---

## Screenshots

| File | Description |
|------|-------------|
| `01_01-semester-list-ay14.png` | Semester list for AY14 — table structure |
| `02_02-semester-list-ay15-before.png` | AY15 empty state before create |
| `03_03-create-form.png` | Create form |
| `04_04-form-filled.png` | Form with data filled |
| `05_05-after-create.png` | After create — Sem1 in list |
| `06_06-semester-list-ay15-full.png` | Full list state |
| `07_07-after-activate.png` | After activating Sem1 |
| `08_08-ay14-isolation-check.png` | AY14 unchanged after AY15 activation |
| `09_09-after-uniqueness-test.png` | After duplicate submit (rejected) |
| `10_10-before-cleanup.png` | Before cleanup |
| `11_11-after-delete-Semester1.png` | After delete |
| `12_12-final-state-ay15.png` | Final empty state |

---

## Severity Summary

| # | Finding | Severity |
|---|---------|----------|
| 1 | Flash message shows truncated `"Aktif"` after activate | Low (cosmetic) |
| 2 | Activate scoped correctly per AY — no cross-AY leakage | ✅ Pass |
| 3 | Uniqueness per AY enforced (server-side Rule::unique) | ✅ Pass |
| 4 | UI gate (max 2 semesters, button hidden) working | ✅ Pass |
| 5 | Delete with confirm dialog working | ✅ Pass |
| 6 | WebSocket 404 errors on all pages | Info (dev env) |
