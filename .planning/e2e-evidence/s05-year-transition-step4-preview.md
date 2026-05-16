# Scenario: s05-year-transition-step4-preview
_Started: 2026-05-08T11:11:40.507Z_

DB: StudentMutation count BEFORE = 0
Navigate to /year-transition/
⚠️  console.error: WebSocket connection to 'ws://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error during WebSocket handshake: Unexpected response code: 404
📸 01_step1_initial.png  (URL: http://127.0.0.1:8765/year-transition/)
Step 1: Selecting source=14 (2025/2026) and target=15 (2070/2071)
Found 2 <select> element(s) on Step 1
⚠️  console.error: WebSocket connection to 'wss://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error in connection establishment: net::ERR_SSL_PROTOCOL_ERROR
📸 02_step1_years_selected.png  (URL: http://127.0.0.1:8765/year-transition/)
Step 1: Clicking "Lanjutkan"
Waiting for Step 2 to load...
[NET] POST /year-transition/preview #1 → 200
📸 03_step2_class_structure.png  (URL: http://127.0.0.1:8765/year-transition/)
Step 2: Class structure loaded
Step 2: Clicking "Lanjutkan"
Waiting for Step 3 to load...
[NET] POST /year-transition/preview #2 → 200
📸 04_step3_student_review.png  (URL: http://127.0.0.1:8765/year-transition/)
Step 3: Student review loaded
Step 3: Clicking "Buat Preview"
Waiting for Step 4 to load...
[NET] POST /year-transition/preview #3 → 200
📸 05_step4_entering.png  (URL: http://127.0.0.1:8765/year-transition/)
Loading skeleton visible on Step 4 entry: false
Waiting for preview data...
📸 06_step4_preview_loaded.png  (URL: http://127.0.0.1:8765/year-transition/)
Step 4: Preview data loaded
Stat card "Naik Kelas" visible: true
Stat card "Lulus" visible: true
Stat card "Tinggal Kelas" visible: true
Stat card "Dikecualikan" visible: true
  Promoted count: 32
  Graduated count: 0
  Retained count: 0
  Excluded count: 0
PASS: All 4 stat cards present
Tab "Semua" visible: true
Tab "Naik Kelas" visible: true
Tab "Lulus" visible: true
Tab "Tinggal Kelas" visible: true
Tab "Dikecualikan" visible: true
Tabs found: 5/5
Mutation table visible: true
  Table rows (tbody): 32
📸 07_step4_table_and_tabs.png  (URL: http://127.0.0.1:8765/year-transition/)
Clicking "Naik Kelas" tab...
  Buttons with text "Naik Kelas": 1
📸 08_step4_tab_naik_kelas.png  (URL: http://127.0.0.1:8765/year-transition/)
Clicking "Lulus" tab...
📸 09_step4_tab_lulus.png  (URL: http://127.0.0.1:8765/year-transition/)
"Unduh JSON" button visible: true
PASS: Download button present
Clicking "Unduh JSON"...
PASS: Download event fired — filename: year-transition-preview-1778238710179.json
📸 10_step4_after_download.png  (URL: http://127.0.0.1:8765/year-transition/)
Clicking "Refresh" button...
Refresh button visible: true
Waiting for re-fetch after Refresh...
[NET] POST /year-transition/preview #4 → 200
Preview API calls delta after Refresh: 1 (expected ≥1)
PASS: Refresh triggered re-fetch
📸 11_step4_after_refresh.png  (URL: http://127.0.0.1:8765/year-transition/)
"Belum ada perubahan data" info alert visible: true
Checking DB for writes...
DB: StudentMutation count AFTER = 0
DB: Delta = 0 (expected 0)
PASS: No DB writes — dry-run confirmed
Total POST /preview calls: 4
Last preview response status: 200
Clicking "Lanjutkan ke Konfirmasi" → Step 5
"Lanjutkan ke Konfirmasi" visible: true, disabled: false
📸 12_step5_confirm.png  (URL: http://127.0.0.1:8765/year-transition/)
Landed on Step 5: true
PASS: Navigation to Step 5 succeeded

=== SUMMARY ===
All 4 stat cards: PASS
  Promoted=32, Graduated=0, Retained=0, Excluded=0
Tabbed mutations table: PASS
Download JSON button: PASS
Refresh re-fetches: PASS
StudentMutation delta (must be 0): 0 → PASS
Advanced to Step 5: PASS

✅ SCENARIO PASSED

_Finished: 2026-05-08T11:11:56.230Z_