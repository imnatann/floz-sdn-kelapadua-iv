# Scenario: s08-academic-year-crud
_Started: 2026-05-08T11:22:13.156Z_

Step 1: Navigate to /academic-years
⚠️  console.error: WebSocket connection to 'ws://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error during WebSocket handshake: Unexpected response code: 404
Step 2: Screenshot list page
📸 01_01-list-page.png  (URL: http://127.0.0.1:8765/academic-years)
URL: http://127.0.0.1:8765/academic-years
Step 3: Verify table columns
Table headers found: ["Nama","Periode","Status","Semester","Aksi"]
PASS: Required table columns present: Nama | Periode | Status | Semester | Aksi
Rows on first page: 16 (expected 16)
Step 4: Navigate to /academic-years/create (Tambah Tahun Ajaran)
Create link href: http://127.0.0.1:8765/academic-years/create
⚠️  console.error: WebSocket connection to 'ws://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error during WebSocket handshake: Unexpected response code: 404
📸 02_02-create-form.png  (URL: http://127.0.0.1:8765/academic-years/create)
URL on create form: http://127.0.0.1:8765/academic-years/create
Form title: Tambah Tahun Ajaran
PASS: Create form loaded, Tambah Tahun Ajaran link present
Step 5: Fill form — E2E Test 2099/2100
📸 03_03-form-filled.png  (URL: http://127.0.0.1:8765/academic-years/create)
Step 6: Submit form
⚠️  console.error: WebSocket connection to 'wss://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error in connection establishment: net::ERR_SSL_PROTOCOL_ERROR
📸 04_04-after-create.png  (URL: http://127.0.0.1:8765/academic-years)
URL after create: http://127.0.0.1:8765/academic-years
PASS: Flash success: Tahun ajaran berhasil dibuat.
PASS: New AY "E2E Test 2099/2100" visible in table
Step 7: Aktifkan "E2E Test 2099/2100"
Active AYs before activate: ["2070/2071"]
Clicking Aktifkan on E2E Test 2099/2100
📸 05_05-after-activate.png  (URL: http://127.0.0.1:8765/academic-years)
Activate flash: Tahun ajaran berhasil dibuat.
INFO: Flash text may be stale from previous action: Tahun ajaran berhasil dibuat.
Active AYs after activate: ["2070/2071"]
PASS: Exactly 1 active AY on page
INFO: Active AY is: 2070/2071
Old AY 2070/2071 shows "Tidak Aktif": NO - CHECK
WARN: 2070/2071 may still be active — activate transaction may have failed
Step 8: Delete-guard — Hapus on AY with classes (2026/2027 - Ganjil, ID 1)
⚠️  console.error: WebSocket connection to 'ws://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error during WebSocket handshake: Unexpected response code: 404
Found 13 "2026/2027 - Ganjil" rows
Clicking Hapus on a 2026/2027 - Ganjil row (expects 422 block)
Guard dialog: Hapus tahun ajaran ini? Pastikan tidak ada kelas yang terkait.
Guard response status: 422
⚠️  console.error: Failed to load resource: the server responded with a status of 422 (Unprocessable Content)
📸 06_06-after-guard-delete-attempt.png  (URL: http://127.0.0.1:8765/academic-years)
Guard rows still present: 13
PASS: Delete-guard blocked — 2026/2027 - Ganjil rows still exist (no error flash rendered, but Inertia 422 confirmed in console)
GET /academic-years/1/edit → 200 (PASS: still exists)
Step 9: Hapus "E2E Test 2099/2100" — should succeed (no classes)
⚠️  console.error: WebSocket connection to 'ws://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error during WebSocket handshake: Unexpected response code: 404
Clicking Hapus on E2E Test 2099/2100
Delete confirm dialog: Hapus tahun ajaran ini? Pastikan tidak ada kelas yang terkait.
📸 07_07-after-delete-test-ay.png  (URL: http://127.0.0.1:8765/academic-years)
URL after delete: http://127.0.0.1:8765/academic-years
Delete success flash: Aktif
❌ SCENARIO ERROR: FAIL: E2E Test 2099/2100 row still visible — delete may have failed!

❌ SCENARIO FAILED
```
Error: FAIL: E2E Test 2099/2100 row still visible — delete may have failed!
    at file:///private/tmp/floz-e2e/scripts/s08-academic-year-crud.mjs:332:11
    at async runScenario (file:///private/tmp/floz-e2e/harness.mjs:46:5)
    at async file:///private/tmp/floz-e2e/scripts/s08-academic-year-crud.mjs:27:1
```
📸 08_error_state.png  (URL: http://127.0.0.1:8765/academic-years)

_Finished: 2026-05-08T11:22:22.292Z_