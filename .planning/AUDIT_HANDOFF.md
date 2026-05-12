# E2E Permission Audit — Handoff (4 paralel role agents)

**Date:** 2026-05-13
**Branch:** `chore/remove-tenant-leftovers` (origin synced through `43ab9b2`)
**Audit method:** 4 paralel Playwright headless agents, 1 per role, 18 pages each, screenshots + findings per role

## Per-Role Audit Results

| Role | Pages tested | OK | Leaks | Findings file |
|------|---|---|---|---|
| Admin | 18 | 18 | 0 (1 cosmetic) | `/tmp/floz-e2e/role-audit/findings/admin.md` |
| Wali Kelas (mariam.s) | 17 | 9 | **8** | `/tmp/floz-e2e/role-audit/findings/wali.md` |
| Guru biasa (siti.aminah) | 16 | 11 | **5** | `/tmp/floz-e2e/role-audit/findings/guru.md` |
| Siswa | DID NOT RUN | — | — | Script ready at `/tmp/floz-e2e/role-audit/scripts/siswa.mjs` |

Screenshots: `/tmp/floz-e2e/role-audit/<role>/*.png` (Admin=18, Wali=19, Guru=multiple)

## Fixed This Session

| Commit | Fix |
|---|---|
| `9c25854` | Siswa scope: Schedule/Tasks/Exams index limited to own class |
| `43ab9b2` | `/year-transition`, `/academic-years`, `/audit-logs` wrapped in `role:school_admin` middleware (closes 3 wali + 2 guru leaks) |

## Fixed in follow-up session (2026-05-13)

| Commit | Fix |
|---|---|
| `5e17f4d` | Classes/Subjects/Staff/ReportCards: hide Tambah/Edit/Hapus + Generate/Terbitkan for non-admin/non-wali (UI + backend guard on ReportCardController::generate/publish) |
| `efa8132` | Announcements: hide Buat Baru/Edit/Hapus from siswa |
| `f3cca80` | Replace `$user->role === 'string'` (always false vs UserRole enum) with `isTeacher()/isStudent()` across 6 controllers; scope class dropdown + report-card rows to teacher's visible classes (homeroom + TA) |

## Outstanding (closed in follow-up — see above)

~~1. /classes CRUD buttons leak~~ — closed by `5e17f4d`
~~2. /subjects Tambah leak~~ — closed by `5e17f4d`
~~3. /report-cards Generate/Terbitkan leak~~ — closed by `5e17f4d` (+ backend guard)
~~4. /staff CRUD buttons leak~~ — closed by `5e17f4d`
~~5. Wali kelas dropdown scoping~~ — closed by `f3cca80`
~~6. Siswa announcement CRUD~~ — closed by `efa8132`

### 🟡 Cosmetic / non-blocking (still open)

7. **`/analytics/reports` 4× 404 AJAX** to `/analytics/data/w4..w7` widget endpoints — implement or rename routes
8. **Admin password change discoverability** — currently in avatar dropdown only

### Feature requests (not security)

9. Add mapel + tahun ajaran filter dropdowns to student-facing Tasks/Exams views (user request)

## Siswa Audit Resume Instructions

Script at `/tmp/floz-e2e/role-audit/scripts/siswa.mjs` stalled because login navigation needed `waitForNavigation` not `waitForLoadState('networkidle')`. Inertia uses client-side nav.

Fix pattern (apply when resuming):
```js
const [resp] = await Promise.all([
  page.waitForResponse(r => r.url().endsWith('/login') && r.request().method() === 'POST'),
  page.click('button[type="submit"]'),
]);
await page.waitForURL(url => !url.toString().endsWith('/login'), { timeout: 10000 }).catch(() => {});
```

Credentials: `24001@siswa.sekolah.id` / `password` (note: student password is `password` not `password123`).

## Reference: Test User Accounts

| Role | Email | Password |
|---|---|---|
| Admin | admin@floz.test | password123 |
| Wali Kelas 1A | mariam.s@sdkelapadua4.sch.id | password123 |
| Wali Kelas 2A | hendra.w@sdkelapadua4.sch.id | password123 |
| Non-wali teacher | siti.aminah@sdkelapadua4.sch.id | password123 |
| Siswa | 24001@siswa.sekolah.id | password |

## Dev environment

- Server: `http://127.0.0.1:8765` (php artisan serve)
- Ngrok tunnel: `https://1cd4-2404-c0-2426-e1fc-f59d-ec72-3bd2-fb57.ngrok-free.app` (may have rotated)
- DB: postgres `floz_sdn_kelapadua_iv` — has 90 students, 6 classes, 10 teachers, etc.
- Active semester: Genap 2025/2026 (id=4)

## Recommended next-session priority

1. Hide UI CRUD buttons (#1, #2, #3, #4) — ~30 min
2. Run siswa audit, verify #6 — ~15 min
3. Wali kelas dropdown scoping (#5) — ~45 min
4. Filter dropdowns for student views (#9) — ~30 min

Total ~2h work to close all outstanding leaks from this audit.
