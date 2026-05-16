# Scenario: s11-wizard-e2e-happy-path
_Started: 2026-05-08T11:13:31.727Z_

DB: year_transition_logs table exists: true
DB: year_transition_logs BEFORE = 0
DB: student_mutations BEFORE = 0
⚠️  console.error: WebSocket connection to 'ws://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error during WebSocket handshake: Unexpected response code: 404
⚠️  console.error: WebSocket connection to 'wss://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error in connection establishment: net::ERR_SSL_PROTOCOL_ERROR
📸 01_step1_initial.png  (URL: http://127.0.0.1:8765/year-transition)
Step 1 heading: Langkah 1: Pilih Tahun Ajaran
Source options: Pilih tahun ajaran sumber | 2070/2071 (Aktif) | 2065/2066 | 2026/2027 - Ganjil | 2026/2027 - Ganjil | ...
Source pre-selected value: 15 (2070/2071 — Aktif)
Picking target AY: 16 (2065/2066)
📸 02_step1_years_selected.png  (URL: http://127.0.0.1:8765/year-transition)
Step 1: source and target selected
Step 2 heading: Langkah 2: Struktur Kelas Baru
📸 03_step2_class_structure.png  (URL: http://127.0.0.1:8765/year-transition)
Step 2: ClassStructure loaded, accepting defaults
Step 3 heading: Langkah 3: Review Per Siswa
📸 04_step3_student_review.png  (URL: http://127.0.0.1:8765/year-transition)
Step 3: StudentReview loaded, leaving defaults
Step 4 heading: Langkah 4: Preview Mutasi (Dry Run)
📸 05_step4_preview.png  (URL: http://127.0.0.1:8765/year-transition)
Stat[0] Naik Kelas: 4
Stat[1] Lulus: 0
Stat[2] Tinggal Kelas: 0
Stat[3] Dikecualikan: 0
Preview stats: {"promoted":4,"graduated":0,"retained":0,"excluded":0}
Preview JSON: fetched via Node HTTP with session cookie (page.request got 419 — Playwright APIRequestContext does not auto-inject XSRF header)
Preview API status: 200 (via direct HTTP call with session cookies)
Preview payload saved to: /tmp/floz-e2e/findings/s11-preview-payload.json

Backend service contract validation:
  source_ay: id=15 (2070/2071, is_active=true)
  target_ay: id=16 (2065/2066, is_active=false)
  new_classes: [{"source_class_id":14,"name":"Kelas 3A","grade_level":3}]
  mutations: 4 students, all action=promote, from Kelas 3A (grade 3) → to Kelas 4A (grade 4)
  summary: {"promoted":4,"graduated":0,"retained":0,"excluded":0}
  UI stats match API summary: YES (promoted=4 displayed on all 4 stat cards correctly)

Step 4 next button text: Lanjutkan ke Konfirmasi
Step 5 heading: Langkah 5: Konfirmasi & Terapkan
📸 06_step5_confirm.png  (URL: http://127.0.0.1:8765/year-transition)
TERAPKAN button disabled (gate active): true
Gate verified: TERAPKAN disabled until "TERAPKAN" typed in confirm input
Confirm input value: (empty — correct)
Step 5 verified. NOT clicking TERAPKAN (preview-only test).

=== BEGIN BACK NAVIGATION TEST ===
Back to Step 4 heading: Langkah 4: Preview Mutasi (Dry Run)
📸 07_back_step4.png  (URL: http://127.0.0.1:8765/year-transition)
Step 4 stat cards after back nav: 4 (should be 4)
Cached promoted count: 4 — plan retained in wizardData.plan, no re-fetch
Back to Step 3 heading: Langkah 3: Review Per Siswa
📸 08_back_step3.png  (URL: http://127.0.0.1:8765/year-transition)
Back to Step 2 heading: Langkah 2: Struktur Kelas Baru
📸 09_back_step2.png  (URL: http://127.0.0.1:8765/year-transition)
Step 2 class rows on back nav: 1 (cached from first visit, no API re-fetch)
Back to Step 1 heading: Langkah 1: Pilih Tahun Ajaran
📸 10_back_step1.png  (URL: http://127.0.0.1:8765/year-transition)
Step 1 state after back nav — source: 15 target: 16
State preservation: source and target AY values preserved

=== BEGIN FORWARD RE-NAVIGATION TEST ===
Forward Step 2 heading: Langkah 2: Struktur Kelas Baru
Forward Step 3 heading: Langkah 3: Review Per Siswa
Forward Step 4 heading (re-navigate): Langkah 4: Preview Mutasi (Dry Run)
Step 4 stat cards on re-forward: 4
Re-forward Step 4 stats — promoted: 4, graduated: 0, retained: 0, excluded: 0
State consistency: re-forward Step 4 stats MATCH initial preview
📸 11_refwd_step4.png  (URL: http://127.0.0.1:8765/year-transition)

DB: year_transition_logs table exists: true
DB: year_transition_logs AFTER = 0
DB: year_transition_logs DELTA = 0 (MUST BE 0)
DB: student_mutations AFTER = 0
DB: student_mutations DELTA = 0 (MUST BE 0)
DB integrity: PASS — no year_transition_logs written (preview-only confirmed)

=== FINAL SUMMARY ===
promoted: 4
graduated: 0
retained: 0
excluded: 0
year_transition_logs delta: 0 (must be 0)
TERAPKAN gate: PASS (button disabled)
Back navigation state preservation: source=preserved, target=preserved

## Flow Smoothness Assessment

| Checkpoint | Result | Notes |
|---|---|---|
| Step 1 → 2 transition | PASS | ClassStructure API call completes, defaults loaded |
| Step 2 → 3 transition | PASS | StudentReview API call completes |
| Step 3 → 4 transition | PASS | Preview POST (dry-run) fetches correctly |
| Step 4 → 5 transition | PASS | Confirm UI renders with plan hash |
| TERAPKAN gate | PASS | Button disabled until "TERAPKAN" typed |
| Back 5→4→3→2→1 | PASS | All step headings correct, state preserved |
| Step 2 cache on back | PASS | newClasses served from wizardData, no API re-fetch |
| Step 4 cache on back | PASS | plan stored in wizardData, stat cards show cached data |
| Step 1 AY values on back | PASS | source=15, target=16 preserved in wizardData |
| Re-forward 1→4 | PASS | Stats consistent: promoted=4 on both visits |
| DB integrity | PASS | year_transition_logs delta=0, student_mutations delta=0 |
| 500 errors | NONE | No server errors in network log |
| WebSocket errors | INFO | Reverb WS not running (localhost:8080 404/SSL) — non-fatal, irrelevant to wizard |

## Issues Found

| Severity | Issue |
|---|---|
| LOW | page.request.post gets 419 (CSRF) — Playwright APIRequestContext doesn't auto-inject X-XSRF-TOKEN from cookie. Workaround: use page.evaluate(fetch) or Node http with cookie jar. |
| INFO | WebSocket (Reverb) not running — console.error on ws/wss localhost:8080. Non-blocking for wizard. |
| INFO | Source AY 2070/2071 (active) paired with target 2065/2066 (older year) — test data anomaly, not a bug. Only 4 students in source AY (test dataset). |

✅ SCENARIO PASSED

_Finished: 2026-05-08T11:14:04.472Z_
