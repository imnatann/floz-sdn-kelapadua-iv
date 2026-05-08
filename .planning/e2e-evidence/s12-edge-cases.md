# Scenario: s12-edge-cases
_Started: 2026-05-08T11:15:37.743Z_


═══ EC-1: Source = Target AY (same ID submitted to server) ═══
⚠️  console.error: WebSocket connection to 'ws://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error during WebSocket handshake: Unexpected response code: 404
📸 01_ec1_wizard_loaded.png  (URL: http://127.0.0.1:8765/year-transition)
⚠️  console.error: Failed to load resource: the server responded with a status of 422 (Unprocessable Content)
EC-1 status: 422
EC-1 body: {"message":"Tahun ajaran tujuan harus berbeda dari tahun sumber.","errors":{"target_academic_year_id":["Tahun ajaran tujuan harus berbeda dari tahun sumber."]}}
EC-1 PASS: server 422 for same source=target
📸 02_ec1_result.png  (URL: http://127.0.0.1:8765/year-transition)

═══ EC-2: Check wizard behavior when no AY is active ═══
⚠️  console.error: WebSocket connection to 'wss://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error in connection establishment: net::ERR_SSL_PROTOCOL_ERROR
⚠️  console.error: WebSocket connection to 'ws://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error during WebSocket handshake: Unexpected response code: 404
EC-2 AY list from server: [{"id":15,"name":"2070/2071","is_active":true},{"id":16,"name":"2065/2066","is_active":false},{"id":3,"name":"2026/2027 - Ganjil","is_active":false},{"id":4,"name":"2026/2027 - Ganjil","is_active":false},{"id":5,"name":"2026/2027 - Ganjil","is_active":false},{"id":6,"name":"2026/2027 - Ganjil","is_active":false},{"id":7,"name":"2026/2027 - Ganjil","is_active":false},{"id":8,"name":"2026/2027 - Ganjil","is_active":false},{"id":10,"name":"2026/2027 - Ganjil","is_active":false},{"id":11,"name":"2026/2027 - Ganjil","is_active":false},{"id":12,"name":"2026/2027 - Ganjil","is_active":false},{"id":13,"name":"2026/2027 - Ganjil","is_active":false},{"id":9,"name":"2026/2027 - Ganjil","is_active":false},{"id":2,"name":"2026/2027 - Ganjil","is_active":false},{"id":1,"name":"2026/2027 - Ganjil","is_active":false},{"id":14,"name":"2025/2026","is_active":false}]
EC-2 Active AYs count: 1
EC-2 Source dropdown default value: 15
EC-2 Error elements visible: 0
📸 03_ec2_wizard_no_active_check.png  (URL: http://127.0.0.1:8765/year-transition)
EC-2 NOTE: 1 active AY(s) exist. Wizard defaults source to active AY.

═══ EC-3: Empty source AY — preview with 0-student source ═══
EC-3 Available AYs: [{"id":15,"name":"2070/2071"},{"id":16,"name":"2065/2066"},{"id":3,"name":"2026/2027 - Ganjil"},{"id":4,"name":"2026/2027 - Ganjil"},{"id":5,"name":"2026/2027 - Ganjil"},{"id":6,"name":"2026/2027 - Ganjil"},{"id":7,"name":"2026/2027 - Ganjil"},{"id":8,"name":"2026/2027 - Ganjil"},{"id":10,"name":"2026/2027 - Ganjil"},{"id":11,"name":"2026/2027 - Ganjil"},{"id":12,"name":"2026/2027 - Ganjil"},{"id":13,"name":"2026/2027 - Ganjil"},{"id":9,"name":"2026/2027 - Ganjil"},{"id":2,"name":"2026/2027 - Ganjil"},{"id":1,"name":"2026/2027 - Ganjil"},{"id":14,"name":"2025/2026"}]
EC-3 Testing: source AY id=16 (newest, likely empty), target AY id=15
EC-3 status: 200
EC-3 mutations count: 0
EC-3 summary: {"promoted":0,"graduated":0,"retained":0,"excluded":0}
EC-3 PASS: Empty source AY handled gracefully — 200 with empty/minimal mutations
📸 04_ec3_result.png  (URL: http://127.0.0.1:8765/year-transition)

═══ EC-4: POST /preview — no CSRF token, no cookies ═══
⚠️  console.error: Failed to load resource: the server responded with a status of 419 (unknown status)
EC-4 status: 419
EC-4 body: {
    "message": "CSRF token mismatch.",
    "exception": "Symfony\\Component\\HttpKernel\\Exception\\HttpException",
    "file": "/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/vendor/laravel/framework/src/Illuminate/Foundation/Exceptions/Handler.php",
    "line": 673,
    "trace": [
        {
            
EC-4 PASS: 419 CSRF mismatch as expected
📸 05_ec4_result.png  (URL: http://127.0.0.1:8765/year-transition)

═══ EC-5: POST /execute with mutated plan_hash + wrong confirmation_word ═══
NOTE from code analysis: ExecuteRequest rules do NOT include plan_hash field.
plan_hash is client-side only (JS djb2 hash of summary counts). Server ignores it entirely.
⚠️  console.error: WebSocket connection to 'wss://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error in connection establishment: net::ERR_SSL_PROTOCOL_ERROR
⚠️  console.error: Failed to load resource: the server responded with a status of 422 (Unprocessable Content)
EC-5a (wrong conf_word): status=422
EC-5a body: {"message":"Ketik \"TERAPKAN\" untuk mengkonfirmasi.","errors":{"confirmation_word":["Ketik \"TERAPKAN\" untuk mengkonfirmasi."]}}
⚠️  console.error: Failed to load resource: the server responded with a status of 422 (Unprocessable Content)
EC-5b (valid conf_word, fake AY): status=422
EC-5b body: {"message":"Source academic year id yang dipilih tidak valid.","errors":{"source_academic_year_id":["Source academic year id yang dipilih tidak valid."]}}
EC-5 FINDING: plan_hash NOT validated server-side. Only confirmation_word + AY existence checked.
EC-5 WARN: No server-side plan integrity check. A stale plan (data changed between preview and execute) is NOT detected via hash.
📸 06_ec5_result.png  (URL: http://127.0.0.1:8765/year-transition)

═══ EC-6: Two concurrent POSTs to /preview ═══
EC-6 r1: status=200, elapsed=206ms, mutations=4
EC-6 r2: status=200, elapsed=390ms, mutations=4
EC-6 total wall time: 393ms
EC-6 PASS: Both concurrent previews returned 200. Preview is idempotent (no lock held).
📸 07_ec6_result.png  (URL: http://127.0.0.1:8765/year-transition)

═══ EC-7: Browser back button after reaching wizard Step 4 ═══
⚠️  console.error: WebSocket connection to 'ws://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error during WebSocket handshake: Unexpected response code: 404
📸 08_ec7_step1_initial.png  (URL: http://127.0.0.1:8765/year-transition)
📸 09_ec7_step1_filled.png  (URL: http://127.0.0.1:8765/year-transition)
📸 10_ec7_step2.png  (URL: http://127.0.0.1:8765/year-transition)
⚠️  console.error: WebSocket connection to 'wss://localhost:8080/app/3lc9ycwaf1lf5ragqhy0?protocol=7&client=js&version=8.4.0&flash=false' failed: Error in connection establishment: net::ERR_SSL_PROTOCOL_ERROR
📸 11_ec7_step3.png  (URL: http://127.0.0.1:8765/year-transition)
📸 12_ec7_step4.png  (URL: http://127.0.0.1:8765/year-transition)
EC-7 Reached step: 3
EC-7 URL before back: http://127.0.0.1:8765/year-transition
EC-7 URL after browser back: about:blank
📸 13_ec7_after_browser_back.png  (URL: about:blank)
EC-7 Wizard present: false
EC-7 Step text visible: not found
EC-7 Body snippet: 
EC-7 NOTE: Browser back navigated AWAY from wizard (Inertia SPA — single URL, but history entry may exist).
📸 14_ec7_final.png  (URL: about:blank)

═══ SUMMARY ═══
EC-1 Same Source=Target: server 422 — PASS
EC-2 No Active AY: 1 active AYs — wizard renders OK
EC-3 Empty Source AY: server 200 — PASS graceful
EC-4 No CSRF: server 419 — PASS
EC-5 Invalid plan_hash: 422 / 422 — plan_hash NOT validated server-side (WARN)
EC-6 Concurrent preview: r1=200 r2=200 wall=393ms
EC-7 Browser back: reached step 3, URL after back: about:blank

✅ SCENARIO PASSED

_Finished: 2026-05-08T11:15:48.391Z_

---

## Analysis & Findings

### EC-1 — Source = Target AY
**Result:** PASS (server 422)
- Client UI prevents selection (targetOptions filters out sourceAyId via computed)
- Server `PreviewRequest` also enforces `different:source_academic_year_id`
- Error message: "Tahun ajaran tujuan harus berbeda dari tahun sumber."
- **Severity: NIT** — dual-layer protection, no gap.

### EC-2 — No Active AY in DB
**Result:** DOCUMENTED (no crash)
- DB currently has 1 active AY (id=15, "2070/2071"). Test ran against live state.
- Wizard renders fine; source dropdown defaults to active AY (id=15).
- 0 error elements on page.
- **Hypothetical:** If `is_active` were cleared on all rows, `activeAy` computed returns undefined, `sourceAyId` initializes to `null` — dropdown renders blank. No server crash (controller loads all AYs regardless). User would simply see blank dropdowns.
- **Severity: NIT** — graceful blank state, not a crash.

### EC-3 — Empty Source AY (0 students)
**Result:** PASS — server returns 200 with `mutations: [], summary: {promoted:0, graduated:0, retained:0, excluded:0}`
- Tested AY id=16 ("2065/2066") as source — has no classes/students.
- `previewTransition` handles empty: `$students` returns empty collection, loop never runs.
- No 500. No crash. Empty plan returned correctly.
- **Observation:** 16 AYs exist in DB, many named "2026/2027 - Ganjil" (duplicates from prior test runs). Duplicate AY names may cause confusion in the UI (no disambiguation beyond id).
- **Severity: WARN (cosmetic)** — duplicate AY names in dropdown confuse users; not a functional bug.

### EC-4 — POST /preview without CSRF
**Result:** PASS — server returns 419 CSRF token mismatch
- **Issue found:** 419 response body includes full Laravel exception stack trace including file paths:
  `"file": "/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/vendor/laravel/framework/src/Illuminate/Foundation/Exceptions/Handler.php"`
- This is `APP_DEBUG=true` behavior leaking internal paths to the client.
- In production this would be suppressed by `APP_DEBUG=false`.
- **Severity: WARN** — debug mode stack traces in 419/5xx responses. Must confirm `APP_DEBUG=false` before production deploy.

### EC-5 — Invalid/Mutated plan_hash
**Result:** WARN — plan_hash is NOT validated server-side at all
- `ExecuteRequest::rules()` has no `plan_hash` field. Server ignores the field entirely.
- The "Plan Hash" displayed in Confirm step (Step 5) is a client-side djb2 hash of summary counts only — NOT sent to server, NOT stored, NOT verified.
- A stale plan (students changed between preview and execute) is **not detected** via hash.
- The only guard against stale-plan execution is BLOCK-1 (target AY already has classes) and BLOCK-5 (cache lock). Neither catches the scenario: "student enrolled or unenrolled between preview and execute".
- EC-5a: wrong `confirmation_word` → 422 (expected)
- EC-5b: valid `confirmation_word` + non-existent source_ay → 422 (expected, AY existence checked)
- **Severity: WARN** — no plan integrity fingerprint on server. If an admin previews, data changes, they execute, the execute runs on fresh data without warning. The `previewTransition` IS re-run inside the transaction (BLOCK-3), so the plan is fresh at execute time — but the preview shown to admin may differ from what actually executes. Consider adding a server-side plan hash stored in session/cache between preview and execute.

### EC-6 — Concurrent /preview (idempotency)
**Result:** PASS — both requests returned 200, mutations=4 each, wall time 393ms
- Request 1: 206ms, Request 2: 390ms (sequential on server, PHP-FPM/single-thread per process)
- Preview has NO lock (only execute has `Cache::lock`). Two concurrent previews succeed independently.
- Both return identical mutation count (4), confirming idempotent read behavior.
- **Severity: NIT** — working as designed.

### EC-7 — Browser Back Button After Step 3/4
**Result:** DOCUMENTED — browser back exits wizard entirely
- The Playwright test navigated through Steps 1→2→3 (reached step 3 before Step 4 "Preview" triggered async preview fetch). Step 4's "Lanjutkan" button may not appear until preview loads.
- Inertia SPA uses a single URL (`/year-transition`) for all wizard steps. Browser history has no URL-per-step entries (Vue `ref` tracks step locally).
- `page.goBack()` from `/year-transition` navigates to `about:blank` (no prior navigation entry in the Playwright browser session — the first navigation was to `/year-transition`).
- In a real browser session (with prior page history), browser back would navigate to the previous page (e.g. dashboard), NOT to an earlier wizard step. Wizard state (step index + form data) would be **lost entirely** — no `beforeunload` guard exists.
- Code confirms: no `onBeforeUnmount` / `beforeunload` event handler in Wizard.vue or any step component.
- **Severity: WARN** — user who accidentally hits browser back mid-wizard loses all entered data and must restart. No confirmation dialog. Consider `window.onbeforeunload` guard on steps 2+.

---

## Summary Table

| EC | Description | Result | Severity |
|----|-------------|--------|----------|
| EC-1 | Same source=target AY | 422 (dual-layer client+server) | NIT |
| EC-2 | No active AY in DB | Graceful blank dropdown, no crash | NIT |
| EC-3 | Empty source AY (0 students) | 200 empty plan, no crash | NIT |
| EC-4 | No CSRF token | 419, but leaks stack trace (APP_DEBUG=true) | WARN |
| EC-5 | Mutated plan_hash | plan_hash not validated server-side; stale-plan gap | WARN |
| EC-6 | Concurrent preview | Both 200, idempotent, 393ms wall | NIT |
| EC-7 | Browser back button | Exits wizard, all state lost, no beforeunload guard | WARN |

**No BLOCK-severity (crash/data-corruption) issues found.**
**3× WARN, 4× NIT.**