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

## Outstanding (next session)

### 🔴 Critical security/permission leaks

1. **`/classes` shows Tambah/Edit/Hapus to non-admin teachers** (both wali + guru reported)
   - Fix: Hide buttons in `Pages/Classes/Index.vue` behind `v-if="$page.props.auth.user.role === 'school_admin'"` or `permissions.manage_classes`
   - Backend `SchoolClassPolicy::create/update/delete` already returns `isSchoolAdmin()` — backend safe, UI noise

2. **`/subjects` shows Tambah to non-admin** (both wali + guru)
   - Fix: Same pattern in `Pages/Subjects/Index.vue`

3. **`/report-cards` Generate + Terbitkan (Publish) visible to non-wali teacher** (guru leak — kritis)
   - Pages/ReportCards/Index.vue + Show.vue
   - Should be: admin always; teacher only if wali kelas of that class
   - Add `v-if` checks based on `auth.user.teacher_id === reportCard.student.class.homeroom_teacher_id`

4. **`/staff` (teachers) — need verify if leak exists**
   - Likely same Tambah/Edit/Hapus visible to non-admin
   - Fix UI gate per `permissions.manage_teachers`

### 🟠 Scope filtering UI

5. **8 page dropdowns show all classes (1A-6A) for wali kelas** — should default to/limit to wali's class
   - Pages: Schedules, Attendance, Tasks (when present), Exams, Grades, Report Cards, Analytics Reports
   - Backend `9c25854` only scoped student role; wali still sees full dropdown

### ⚠️ User-reported items not yet verified

6. **Siswa CRUD pengumuman** (user complaint)
   - Backend `AnnouncementPolicy::create` returns `isSchoolAdmin() || isTeacher()` — student should be 403
   - Verify UI in `Pages/Announcements/Index.vue` hides Tambah button for student
   - Run siswa audit script to confirm

### 🟡 Cosmetic / non-blocking

7. **`/analytics/reports` 4× 404 AJAX** to `/analytics/data/w4..w7` widget endpoints — implement or rename routes
8. **Admin password change discoverability** — currently in avatar dropdown only

### Tasks/Exams filter dropdowns (mapel + tahun ajaran)

9. Add filter dropdowns to student-facing Tasks/Exams views (user request)

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
