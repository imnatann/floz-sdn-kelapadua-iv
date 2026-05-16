# Next Phase Candidates — FLOZ LMS (Post Phase 5)

_Generated: 2026-05-08. Branch: chore/remove-tenant-leftovers._
_Phase 5 delivered: Flutter mobile app for Student + Teacher (auth, dashboard, schedules, grades, report cards, courses, attendance input, grade input, recap, notifications)._

---

## Phase 6 — Parent Mobile App (Orang Tua)

**Description:** Build the Flutter screens for the `parent` role so guardians can monitor their child's grades, attendance, and report cards from the same mobile app.

**Why now:** `parent` role already exists in RBAC (`UserRole` enum), PRD explicitly lists parents as a first-class user, and the REST API + Sanctum auth layer (Phase 5) is in place — it just needs parent-scoped endpoints and Flutter screens.

**Effort:** M (4–7 days)
- ~4 new API endpoints (child profile, grades, attendance history, report cards)
- ~5–6 Flutter screens reusing existing widget library
- Parent↔Student linkage migration (simple FK on `users` or pivot table)

**Risk:** Low — well-understood domain, existing patterns to copy.

**Dependencies:** Phase 5 API foundation (done). Parent user seeding / admin UI to link parent↔student.

**Success metric:** A parent can log in, see their child's latest grades and attendance summary, and download the published report card PDF — all from mobile.

**Skill/agent:** `gsd-plan-phase` → `gsd-execute-phase`

---

## Phase 7 — School-Year Transition & Student Promotion Flow

**Description:** Admin-driven workflow to close the current academic year: bulk-promote students to the next class, retain or graduate Grade 6, reset teaching assignments, and open the new year.

**Why now:** The `StudentMutation` model already exists with types `promotion | retention | transfer_in | transfer_out | dropout | graduated`. The `AcademicYear` and `Semester` models exist. The scaffold is there; only the UI wizard and business logic are missing. The school will need this before July 2026 (Indonesian new-school-year).

**Effort:** M (5–8 days)
- Year-close wizard (web admin): select target year, map classes, bulk-promote
- Grade-6 graduation path (mark as `graduated`, exclude from next-year class lists)
- Re-seed teaching assignments for new year
- Guard: prevent data entry when year is closed

**Risk:** Medium — data-destructive if mishandled; needs dry-run preview + confirmation step.

**Dependencies:** Stable academic-year data model (exists). No mobile dependency.

**Success metric:** Admin can close 2025/2026, open 2026/2027, and all students appear in correct new classes with zero manual record edits.

**Skill/agent:** `gsd-spec-phase` → `gsd-plan-phase` → `gsd-execute-phase`

---

## Phase 8 — Production Readiness & Deployment Hardening

**Description:** Harden the Docker stack for real-school production: env secrets management, automated DB backup, health-check endpoints, basic uptime monitoring, and a one-command deploy runbook.

**Why now:** Docker Compose + Nginx + PostgreSQL + Redis stack exists but is dev-grade. The school will run this on a local server or VPS; a crash with no backup is catastrophic. No CI/CD or backup cron is in place.

**Effort:** S–M (3–5 days)
- `.env.production` template + secret injection guide
- `pg_dump` cron → local + offsite (rclone/S3)
- Laravel health-check route + simple uptime monitor (UptimeRobot or self-hosted)
- `deploy.sh` / Makefile targets: migrate, seed, queue restart, clear cache
- Supervisor config review for queue + Reverb workers

**Risk:** Low effort, very high payoff. Risk of NOT doing it is higher.

**Dependencies:** None — fully independent of feature phases.

**Success metric:** VPS can be reprovisioned from backup within 30 minutes; deploy script runs without manual steps; DB backup verified restorable.

**Skill/agent:** `gsd-plan-phase` → `gsd-execute-phase`

---

## Phase 9 — Reporting & Analytics Dashboard

**Description:** Admin web dashboard with school-wide analytics: attendance trends per class, grade distributions per subject, teacher workload summary, and exportable Excel/CSV reports.

**Why now:** All raw data exists (grades, attendance, report cards). Admins currently have no aggregated view — they must inspect records one by one. This directly serves the kepala sekolah (principal) for monthly/semester reporting to Dinas.

**Effort:** L (8–12 days)
- 4–6 chart components (Vue + Chart.js or ApexCharts)
- Aggregate query layer (Laravel scopes / DB views)
- Excel export (Laravel Excel) for attendance recap and grade summary
- Date-range + class + subject filters

**Risk:** Low functional risk; medium performance risk on large datasets (mitigated by indexed queries and pagination).

**Dependencies:** None. Works on existing data.

**Success metric:** Admin can generate a semester attendance recap and grade distribution PDF/Excel for any class within 3 clicks.

**Skill/agent:** `gsd-ui-phase` → `gsd-plan-phase` → `gsd-execute-phase`

---

## Phase 10 — Test Hardening & API Contract Stabilization

**Description:** Raise Feature test coverage to ≥80% for all V1 API endpoints, add contract tests (OpenAPI snapshot), and establish a CI gate so regressions are caught before merge.

**Why now:** Only 11 test files exist for Student + Teacher API groups; no Auth group tests cover edge cases; no performance benchmarks. As the school goes live, regressions become costly.

**Effort:** M (5–7 days)
- Fill missing test files (Parent API group once Phase 6 ships, edge cases for existing groups)
- OpenAPI spec generation (Scramble or L5-Swagger) pinned as snapshot test
- GitHub Actions / local CI pipeline (pest --parallel, coverage report)
- Basic load test (k6) for attendance batch endpoint

**Risk:** Low — purely additive, no production impact.

**Dependencies:** Best done after Phase 6 (parent API) to avoid re-writing tests.

**Success metric:** `./vendor/bin/pest --coverage` reports ≥80% line coverage; CI fails on any endpoint that breaks the OpenAPI snapshot.

**Skill/agent:** `gsd-add-tests` → `gsd-validate-phase`

---

## Phase 11 — Real-Time Expansion (Live Attendance + Broadcast Announcements)

**Description:** Use Laravel Reverb (already in stack) for live attendance dashboard (teacher marks absent → admin sees instantly) and push announcements directly to Flutter via FCM/WebSocket.

**Why now:** Reverb is installed and wired for notifications (Phase 5). Extending it to attendance events and mobile push is incremental. Teachers currently must reload to see if attendance was already taken by another teacher.

**Effort:** L (10–14 days)
- Attendance broadcast event + admin listener UI (Vue Echo)
- FCM integration for Flutter push notifications (replacing in-app polling)
- Broadcast announcement to all users on publish

**Risk:** Medium — WebSocket stability on school server hardware is uncertain; needs fallback polling.

**Dependencies:** Phase 8 (production-grade Supervisor config for Reverb worker) strongly recommended first.

**Success metric:** Admin sees live attendance status update within 2 seconds of teacher submission; Flutter receives push notification within 5 seconds of announcement publish.

**Skill/agent:** `gsd-spec-phase` → `gsd-plan-phase` → `gsd-execute-phase`

---

## Recommendation Matrix

| Phase | Name | Effort | Value | Risk | Recommended? |
|-------|------|--------|-------|------|--------------|
| 6 | Parent Mobile App | M | High | Low | **YES — #2** |
| 7 | School-Year Transition | M | Critical | Medium | **YES — #1** |
| 8 | Production Readiness | S–M | Critical | Low | **YES — #3** |
| 9 | Reporting & Analytics | L | High | Low | Later (Q3) |
| 10 | Test Hardening | M | Medium | Low | Parallel or after 6 |
| 11 | Real-Time Expansion | L | Medium | Medium | After Phase 8 |

---

## Top 3 Recommendations

### #1 — Phase 7: School-Year Transition (START HERE)
The Indonesian school year turns over in July 2026. The `StudentMutation` model and `AcademicYear` table are already built — this is mostly UI + business logic. Missing this deadline means teachers and admins manually shuffle hundreds of student records. **Do this in May–June 2026.**

### #2 — Phase 6: Parent Mobile App
The `parent` role exists in RBAC and the Phase 5 API foundation is ready. Parents are explicitly in the PRD. Shipping this completes the stakeholder triangle (student ✓ teacher ✓ parent →). Low effort, high visibility.

### #3 — Phase 8: Production Readiness
No backup strategy + no deploy runbook = one disk failure loses all school data. This is 3–5 days of infra work that protects everything else. Run in parallel with Phase 7 or immediately after.

**Single most-recommended next phase: Phase 7 — School-Year Transition.** It has a hard real-world deadline (July school-year rollover), the data model scaffold already exists, and skipping it will cause operational chaos for the school.
