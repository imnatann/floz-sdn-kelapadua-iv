# Scenario: s02-year-transition-step1-select-years
_Started: 2026-05-08T11:06:46.110Z_

⚠️  console.error: WebSocket connection to 'ws://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error during WebSocket handshake: Unexpected response code: 404
⚠️  console.error: WebSocket connection to 'wss://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error in connection establishment: net::ERR_SSL_PROTOCOL_ERROR
📸 01_initial_wizard.png  (URL: http://127.0.0.1:8765/year-transition)
Heading: Transisi Tahun Ajaran
Step circles found: 5 ✅
Step labels: ["Pilih Tahun Ajaran","Struktur Kelas","Review Siswa","Preview Mutasi","Konfirmasi"]
Step 1 section heading: Langkah 1: Pilih Tahun Ajaran
Source label found: ✅
Source dropdown options: [{"value":"","label":"Pilih tahun ajaran sumber"},{"value":"15","label":"2070/2071 (Aktif)"},{"value":"16","label":"2065/2066"},{"value":"3","label":"2026/2027 - Ganjil"},{"value":"4","label":"2026/2027 - Ganjil"},{"value":"5","label":"2026/2027 - Ganjil"},{"value":"6","label":"2026/2027 - Ganjil"},{"value":"7","label":"2026/2027 - Ganjil"},{"value":"8","label":"2026/2027 - Ganjil"},{"value":"10","label":"2026/2027 - Ganjil"},{"value":"11","label":"2026/2027 - Ganjil"},{"value":"12","label":"2026/2027 - Ganjil"},{"value":"13","label":"2026/2027 - Ganjil"},{"value":"9","label":"2026/2027 - Ganjil"},{"value":"2","label":"2026/2027 - Ganjil"},{"value":"1","label":"2026/2027 - Ganjil"},{"value":"14","label":"2025/2026"}]
Target label found: ✅
Target dropdown options: [{"value":"","label":"Pilih tahun ajaran tujuan"},{"value":"16","label":"2065/2066"},{"value":"3","label":"2026/2027 - Ganjil"},{"value":"4","label":"2026/2027 - Ganjil"},{"value":"5","label":"2026/2027 - Ganjil"},{"value":"6","label":"2026/2027 - Ganjil"},{"value":"7","label":"2026/2027 - Ganjil"},{"value":"8","label":"2026/2027 - Ganjil"},{"value":"10","label":"2026/2027 - Ganjil"},{"value":"11","label":"2026/2027 - Ganjil"},{"value":"12","label":"2026/2027 - Ganjil"},{"value":"13","label":"2026/2027 - Ganjil"},{"value":"9","label":"2026/2027 - Ganjil"},{"value":"2","label":"2026/2027 - Ganjil"},{"value":"1","label":"2026/2027 - Ganjil"},{"value":"14","label":"2025/2026"}]
Lanjutkan button found: ✅
Validation error shown: ✅ | Pilih tahun ajaran tujuan.
📸 02_validation_error.png  (URL: http://127.0.0.1:8765/year-transition)
Selected source year: 2070/2071 (Aktif) (value: 15 )
Target options after source selection: [{"value":"","label":"Pilih tahun ajaran tujuan"},{"value":"16","label":"2065/2066"},{"value":"3","label":"2026/2027 - Ganjil"},{"value":"4","label":"2026/2027 - Ganjil"},{"value":"5","label":"2026/2027 - Ganjil"},{"value":"6","label":"2026/2027 - Ganjil"},{"value":"7","label":"2026/2027 - Ganjil"},{"value":"8","label":"2026/2027 - Ganjil"},{"value":"10","label":"2026/2027 - Ganjil"},{"value":"11","label":"2026/2027 - Ganjil"},{"value":"12","label":"2026/2027 - Ganjil"},{"value":"13","label":"2026/2027 - Ganjil"},{"value":"9","label":"2026/2027 - Ganjil"},{"value":"2","label":"2026/2027 - Ganjil"},{"value":"1","label":"2026/2027 - Ganjil"},{"value":"14","label":"2025/2026"}]
Selected target year: 2065/2066 (value: 16 )
📸 03_years_selected.png  (URL: http://127.0.0.1:8765/year-transition)
After Next click — h3 heading: Langkah 2: Struktur Kelas Baru
Orange active circle count: 1 (should be 1 for step 2)
Emerald completed circles: 1 (should be 1 — step 1 done)
Step 2 active: ✅ — Langkah 2: Struktur Kelas Baru
📸 04_step2_active.png  (URL: http://127.0.0.1:8765/year-transition)

=== FINDINGS SUMMARY ===
Step indicator: 5 circles found = PASS
Source label visible: PASS
Target label visible: PASS
Lanjutkan button: PASS
Validation fires on empty: PASS
Source options count: 16
Target options count after source select: 15
Step 2 reached after Next: PASS

✅ SCENARIO PASSED

_Finished: 2026-05-08T11:06:53.470Z_

---

## Extended Analysis

### Visual Review (from screenshots)
- Layout renders cleanly at 1440×900. Side nav, breadcrumb ("Kenaikan Kelas"), and wizard header all present.
- Step indicator bar: 5 circles with truncated text labels visible on desktop. Step 1 circle shows orange/active; inactive steps show slate-300 border. Correct.
- Source dropdown pre-populated with active year "2070/2071 (Aktif)" on load. Good UX default.
- Validation error banner (red, with icon) appears inline below the dropdowns — visible and well-styled.
- After Next: Step 1 circle turns emerald with checkmark; Step 2 circle activates in orange. Step indicator transition is correct.
- Step 3/4/5 labels truncate to "Preview Mut..." and "Konfirmasi" — readable at 1440px. No overflow issues observed.

### Findings

#### WARN-01: Duplicate academic year names in dropdown (severity: WARN)
- 12 of 16 options in the source dropdown share the identical label `"2026/2027 - Ganjil"` (ids 1-13 excluding 14-16).
- Users cannot distinguish between them. This is a seed/data quality issue, but the UI provides no disambiguation (e.g., no ID suffix shown).
- Recommend: Add a unique identifier or semester suffix to `AcademicYear.name` at the DB level, or display `id` next to duplicate names.

#### WARN-02: Stale validation error persists after valid selection (severity: WARN)
- When the user clicks "Lanjutkan" with no target selected (triggers red error "Pilih tahun ajaran tujuan."), then selects a valid target year, the red error banner remains visible until the button is clicked again.
- The `error` ref in `SelectYears.vue` is only cleared inside `validate()`, which is only called on button click. No reactive watcher clears the error when selections change.
- Recommend: Add `watch([sourceAyId, targetAyId], () => { error.value = ''; })` to clear error on any selection change.

#### NIT-01: Step label text truncation in indicator bar (severity: NIT)
- "Preview Mutasi" truncates to "Preview Mut..." in the step indicator at 1440px due to `max-w-[100px]`.
- Not a functional issue but could confuse users unfamiliar with the wizard flow.

#### NIT-02: WebSocket noise in console (severity: NIT)
- Two console.error entries on every page load for failed WebSocket connections to `localhost:8080` (Pusher/Laravel Echo dev key).
- These are expected in dev without a running Reverb/Pusher server, but should be suppressed or documented to avoid confusion in E2E logs.

#### INFO: No `<label for>` / `id` pairing observed in FormSelect (severity: NIT / A11y)
- `FormSelect` generates random `id` via `Math.random()` on each render. This means `<label for="select-xxx">` correctly references its `<select>`, so the a11y pairing is technically present.
- However, the random ID means each page load generates a new ID — this is fine functionally but makes automated a11y selectors fragile (cannot target by stable id). Not a blocking issue.
