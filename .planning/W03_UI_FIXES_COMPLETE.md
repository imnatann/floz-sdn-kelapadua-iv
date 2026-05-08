# Phase 7 UI/UX Audit Fixes — Complete

**Date:** 2026-05-08
**Branch:** chore/remove-tenant-leftovers

## Items Addressed (10/10)

| ID   | File(s)                                         | Commit   | Status   |
|------|-------------------------------------------------|----------|----------|
| W-03 | Wizard.vue                                      | 2a37046  | Done     |
| W-06 | ClassStructure.vue + YearTransitionService.php  | ef6b061  | Done     |
| W-08 | SelectYears.vue                                 | 96cbac3  | Done     |
| L-04 | Logs.vue                                        | 8f30700  | Done     |
| L-05 | LogDetail.vue                                   | 7fb6899  | Done     |
| L-06 | Toast.vue                                       | 1b6656c  | Done     |
| L-07 | ClassStructure.vue                              | ef6b061  | Done (bundled with W-06) |
| L-08 | PLAN_phase7_school_year_transition.md           | f6394e9  | Done     |
| L-09 | Wizard.vue                                      | 2a37046  | Done (bundled with W-03) |
| L-10 | FormSelect.vue                                  | 84e747f  | Done     |

## Detail

### W-03: beforeunload guard
- Watches `currentStep`; adds `beforeunload` listener when step >= 2
- Removed on `onUnmounted` and when transition completes
- Step 4 label "Preview Mutasi" shortened to "Pratinjau" (also fixes L-09)

### W-06: Jumlah Siswa column in Step 2
- `YearTransitionService::previewTransition` now annotates each `new_class` entry with `student_count` (count of promote/retain mutations targeting that class name)
- ClassStructure.vue adds "Jumlah Siswa" column between Tingkat and Wali Kelas; shows count or `—` if zero

### W-08: Validation banner watcher
- `watch([sourceAyId, targetAyId], () => { error.value = ''; })` clears red banner on any selection change

### L-04: EmptyState component
- Replaced 14-line inline empty-state `<tr>` in Logs.vue with `<EmptyState icon="📋" ...>`

### L-05: null-guard on snapshot download
- Button is `v-if="log.plan_snapshot"` — hidden entirely when null

### L-06: Flash truncation
- Root cause: Toast flex container had `w-0 flex-1` without `min-w-0`; long messages could be squeezed by flexbox
- Fix: added `min-w-0` to message container and `break-words` to message `<p>`
- Note: the "Aktif" text in the Status column is the Badge component (by design, not flash)

### L-07: Wali kelas placeholder
- Changed `(Belum ditentukan)` to `Wali kelas akan diisi setelahnya`

### L-08: Confirm button label note
- Added comment to PLAN_phase7 at line 61 noting the implementation label is correct Bahasa Indonesia; spec was loosely worded

### L-09: Step indicator truncation
- Changed `max-w-[100px]` to `max-w-[140px]` on step label span
- Shortened step 4 label to "Pratinjau"

### L-10: FormSelect random id
- Replaced `Math.random().toString(36)` with module-level counter (`_selectIdCounter`)
- Used dual `<script>` + `<script setup>` pattern to keep counter at module scope
- All callers work unchanged; explicit `id` prop still overrides

## Build & Test

- `npm run build`: clean (3.43s, no errors)
- `pest --parallel`: 282 passed, 0 failures, 1183 assertions
