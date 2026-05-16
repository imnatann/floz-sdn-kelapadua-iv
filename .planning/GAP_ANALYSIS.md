# GAP ANALYSIS — FLOZ LMS SDN Kelapadua IV

**Generated:** 2026-05-08
**Branch:** `chore/remove-tenant-leftovers`
**Scope:** Single-school deployment (multi-tenant SaaS code fully removed)

---

## 1. Spec-Promised Features Status Table

| Feature | Spec Source | Status |
|---|---|---|
| Auth (login/logout/me) | PRD, BACKEND_SPEC | DONE |
| RBAC (admin, teacher, student, parent) | PROJECT_MILESTONES | DONE (parent no UI) |
| Dashboard — Admin | PROJECT_MILESTONES | DONE |
| Dashboard — Teacher | PROJECT_MILESTONES | DONE |
| Dashboard — Student | PROJECT_MILESTONES | DONE |
| Student Management (CRUD + import Excel + ID card) | PROJECT_MILESTONES | DONE |
| Staff/Teacher Management (CRUD) | PROJECT_MILESTONES | DONE |
| Class Management (Kelas) | PROJECT_MILESTONES | DONE |
| Subject Management (Mata Pelajaran) | PROJECT_MILESTONES | DONE |
| Teaching Assignments (Penugasan Guru) | PROJECT_MILESTONES | DONE |
| Schedules (Jadwal Pelajaran) | PROJECT_MILESTONES | DONE |
| Attendance web (per-Pertemuan, CRUD) | PROJECT_MILESTONES | DONE |
| Grades web — batch input | PROJECT_MILESTONES | DONE |
| Report Cards — generate + PDF download | PROJECT_MILESTONES | DONE |
| Tasks (Tugas online) — create/grade/submit | PROJECT_MILESTONES | DONE |
| Exams (Ujian) — create/score/manual status | PROJECT_MILESTONES | DONE |
| Offline Assignments (file upload + quiz) | PROJECT_MILESTONES | DONE |
| Courses (Pertemuan system + meetings + materials) | PROJECT_MILESTONES | DONE |
| Materials viewer (web) | PROJECT_MILESTONES | DONE |
| Meetings detail (web) | PROJECT_MILESTONES | DONE |
| Announcements (web CRUD) | PROJECT_MILESTONES | DONE |
| Notifications web inbox | PROJECT_MILESTONES | DONE |
| Audit Logs viewer | PROJECT_MILESTONES | DONE |
| Docs page (Swagger) | README | DONE |
| Welcome / Landing page | PROJECT_MILESTONES | DONE |
| Mobile — Auth (login/logout/me) | PHASE5_SPEC | DONE |
| Mobile — Student dashboard | PHASE5_SPEC | DONE |
| Mobile — Student schedule | PHASE5_SPEC | DONE |
| Mobile — Student grades (list + detail) | PHASE5_SPEC | DONE |
| Mobile — Student report cards (list + PDF) | PHASE5_SPEC | DONE |
| Mobile — Student announcements | PHASE5_SPEC | DONE |
| Mobile — Student assignments (view only) | PHASE5_SPEC | DONE |
| Mobile — Student courses + meetings viewer | PHASE5_SPEC | DONE |
| Mobile — Notifications feed (student + teacher) | PHASE5_SPEC | DONE |
| Mobile — Teacher class list | PHASE5_SPEC | DONE |
| Mobile — Teacher attendance input (per-meeting) | PHASE5_SPEC | DONE |
| Mobile — Teacher grade input | PHASE5_SPEC | DONE |
| Mobile — Teacher recap (attendance + grade) | PHASE5_SPEC | DONE |
| Mobile — Profile screen | GIT_LOG | DONE |
| Parent portal (web or mobile) | PRD | MISSING |
| Swagger annotations (full, rendered) | PHASE5_SPEC (DoD) | PARTIAL (SwaggerController exists; completeness unknown) |
| `EnsureRole` middleware | PHASE5_SPEC | DONE |
| Policies (AttendancePolicy, AnnouncementPolicy, ReportCardPolicy, TaskPolicy) | PHASE5_SPEC Step 0 | UNKNOWN — not confirmed in git log |
| BaseResource + centralized exception handler | PHASE5_SPEC Step 0 | UNKNOWN |
| Hive read-cache (offline stale banner) | PHASE5_SPEC | UNKNOWN — architecture designed, implementation not confirmed via commits |
| Rate limiting (throttle:login, throttle:mobile-api) | PHASE5_SPEC | DONE (routes show throttle groups) |
| Mobile student assignment submission (POST) | PRD/BACKEND_SPEC | MISSING — student/assignments is GET only in api.php |
| Bulk Excel import for students | BACKEND_SPEC | DONE |
| Academic Year / Semester management (web) | BACKEND_SPEC | UNKNOWN — no web route or page visible |
| Contract.md / API contract docs | PHASE5_SPEC Step 0 | UNKNOWN — not found in git log |

---

## 2. Phase 5 Mobile Slices Completion Status

| Slice | Label | Status | Evidence |
|---|---|---|---|
| Step 0 | Foundation (auth refactor, EnsureRole, BaseResource, core/ infra, factories) | LIKELY DONE | auth/login, logout, me all work; EnsureRole in routes; core/ tree exists |
| P1 / S0 | Foundation plan | DONE | `2026-04-15-phase5-p1-foundation.md` |
| P2-1 | Student shell + dashboard | DONE | `feat(mobile/dashboard)` commits; `dashboard_screen.dart` exists |
| P2-2 | Student schedule | DONE | `MobileScheduleController` + `features/student/` schedule files |
| P2-3 | Student grades | DONE | `MobileGradeController` + grade screens |
| P2-4 | Student report cards | DONE | `MobileReportCardController` + report_cards screens |
| P3 | Student announcements (plan file missing but S5) | DONE | `MobileAnnouncementController` + announcement screens |
| P3 | Student assignments view (S6) | DONE | `MobileAssignmentController` + assignment screens |
| P4 | Teacher attendance input | DONE | `MobileTeacherAttendanceController` + `attendance_input_screen.dart` |
| P5 | Teacher grade input | DONE | `MobileTeacherGradeController` + `grade_input_screen.dart` |
| P6 | Teacher recap | DONE | `MobileTeacherRecapController` + `recap_screen.dart` |
| EXTRA | Student courses + materials | DONE | `MobileStudentCoursesController` + courses screens |
| EXTRA | In-app notifications feed | DONE | `MobileNotificationsController` + `notifications_screen.dart` + `notification_bell.dart` |
| MISSING | Student assignment submission (POST) | MISSING | api.php has only GET for assignments |
| MISSING | Hive read-cache + offline stale banner | PARTIAL | Architecture designed; commit evidence thin |
| MISSING | Full Swagger annotations rendered | PARTIAL | `/docs` page exists, completeness unclear |
| MISSING | Parent mobile shell | OUT OF SCOPE (Phase 5) | Explicitly deferred |
| MISSING | Admin mobile shell | OUT OF SCOPE (Phase 5) | Explicitly deferred |

---

## 3. Web Features Coverage

| Feature | Pages Exist | Routes Exist | Controller Exists | Status |
|---|---|---|---|---|
| Auth (login) | `Auth/Login.vue` | `/login` | `LoginController` | DONE |
| Dashboard (admin/teacher/student) | 3 variants | `/dashboard` | `DashboardController` | DONE |
| Students (CRUD + import + ID card) | `Students/` | `/students` resource + extras | `StudentController` | DONE |
| Staff/Teachers | `Staff/` | `/staff` resource | `TeacherController` | DONE |
| Classes | `Classes/Form.vue`, `Index.vue` | `/classes` resource | `SchoolClassController` | DONE |
| Subjects | (expected in Pages) | `/subjects` resource | `SubjectController` | DONE |
| Teaching Assignments | (expected in Pages) | `/teaching-assignments` | `TeachingAssignmentController` | DONE |
| Schedules | `Schedules/` (moved from Tenant/) | `/schedules` | `ScheduleController` | DONE |
| Courses + Meetings + Materials | `Courses/`, `Meetings/Show.vue`, `Materials/Show.vue` | (via courses routes) | (expected) | DONE |
| Attendance | `Attendance/` CRUD | `/attendance/{class}` | `AttendanceController` | DONE |
| Grades (batch) | `Grades/BatchInput.vue`, `Index.vue` | `/grades/batch` | `GradeController` | DONE |
| Report Cards | `ReportCards/` | `/report-cards` | `ReportCardController` | DONE |
| Tasks (online) | `Assignments/` (Create/Edit/Grading/Show/Index) | `/tasks` | `TaskController` | DONE |
| Exams | `Exams/` (ClassIndex/Create/Index/Show) | `/exams` | `ExamController` | DONE |
| Offline Assignments | `OfflineAssignments/` (full CRUD + Grading) | `/offline-assignments` (expected) | `OfflineAssignmentController` | DONE |
| Announcements | `Announcements/` (Form/Index/Show) | `/announcements` (expected) | `AnnouncementController` | DONE |
| Notifications web | `Notifications/Index.vue` | `/notifications` | `NotificationController` | DONE |
| Audit Logs | `AuditLogs/` (Index + DetailModal) | `/audit-logs` (expected) | `AuditLogController` | DONE |
| Docs (Swagger) | `Docs.vue` | `/docs` | `SwaggerController` | DONE |
| Academic Year / Semester mgmt | MISSING | MISSING | MISSING | MISSING — no web CRUD visible |
| Parent portal (web) | MISSING | MISSING | MISSING | MISSING |

---

## 4. Mobile Features Coverage

### Student Side

| Feature | Implemented |
|---|---|
| Login / Logout / Me | DONE |
| Dashboard (greeting, subjects, schedule snippet) | DONE |
| Schedule list | DONE |
| Grades list + subject detail | DONE |
| Report cards list + detail + PDF open | DONE |
| Announcements list + detail | DONE |
| Assignments list + detail (view only) | DONE |
| Courses list + meeting list + meeting detail (materials) | DONE |
| Notifications feed + bell indicator | DONE |
| Profile screen | DONE |
| Assignment submission (POST) | MISSING |
| Attendance self-view | MISSING |

### Teacher Side

| Feature | Implemented |
|---|---|
| Login / Logout / Me (shared) | DONE |
| Teaching assignments (class list) | DONE |
| Meeting list per class | DONE |
| Attendance input per meeting | DONE |
| Grade input per TA | DONE |
| Attendance recap per TA | DONE |
| Grade recap per TA | DONE |
| Notifications feed + bell | DONE |
| Profile screen (shared) | DONE |
| Create/edit meetings from mobile | MISSING |
| Create/edit tasks from mobile | MISSING |
| Teacher announcement create from mobile | MISSING |

---

## 5. Missing / Untested Areas

| Item | Impact | Spec Reference |
|---|---|---|
| Parent role — zero UI (web + mobile) | Medium | PRD §2, PROJECT_MILESTONES roles |
| Student assignment submission (POST /api/v1/student/assignments/{id}/submit) | High | BACKEND_SPEC §3.4 |
| Student self-view attendance via mobile | Medium | BACKEND_SPEC §3.5 |
| Academic Year & Semester web CRUD | High | BACKEND_SPEC §3.1.C |
| Hive read-cache confirmed working + offline stale banner in UI | Medium | PHASE5_SPEC §6.4, DoD |
| Full Swagger annotations + `/api/documentation` rendered | Medium | PHASE5_SPEC DoD |
| Policy gap closure (AttendancePolicy, ReportCardPolicy, etc.) | High (security) | PHASE5_SPEC Step 0 |
| Pest test coverage targets met (backend + mobile) | High | PHASE5_SPEC §9 |
| `docs/api/CONTRACT.md` committed | Low | PHASE5_SPEC Step 0 |
| E2E integration test suite (mobile) | Medium | `844fdcc` shows start; completeness unknown |
| Production `.env` documentation / deployment runbook | High | README mentions Quick Start only |
| KKM (minimum passing grade) logic verified | Medium | FLOZ_README grade calc section |

---

## 6. Quick Wins (Low Effort, High Value)

| Item | Why |
|---|---|
| Wire student assignment POST `/api/v1/student/assignments/{id}/submit` | One new controller method + route; mobile UI already has the screen shell |
| Add `AttendancePolicy`, `ReportCardPolicy`, `TaskPolicy` if missing | Security gap; 30–60 min each following existing Policy pattern |
| Confirm + complete Hive cache for student features (TTL constants) | Architecture already designed in spec; mostly plumbing |
| Add `docs/api/CONTRACT.md` | Single markdown file; already fully described in phase5-rest-api spec |
| Academic Year selector on dashboard / grade input if not auto-resolved | UX: teachers may have multiple years |
| Offline stale banner widget in student shell | Shared widget; small Flutter component |

---

## 7. Big Next Pieces (Significant New Work)

| Item | Effort |
|---|---|
| Academic Year + Semester web CRUD (if absent) | Medium — migrations may exist, need controller + pages + routes |
| Parent portal (web + mobile) — view child grades, attendance, report cards | Large — new role shell, new API endpoints, new mobile shell |
| Student assignment submission flow (full round-trip: submit + teacher grading visible in mobile) | Medium |
| Push notifications (FCM/APNs) | Large — server-side event triggers + mobile token registration + device table |
| Full Swagger doc coverage (all 11+ controllers annotated) | Medium |
| Pest feature test coverage to spec targets | Medium — requires systematic test authoring per slice |
| Production deployment runbook (Docker Compose, env vars, SSL, backup) | Medium |

---

## 8. Production Readiness Checks

| Check | Status | Notes |
|---|---|---|
| Single-school `.env` config (no multi-tenant) | DONE | `config/school.php` exists; tenant middleware removed |
| Sanctum bearer token auth | DONE | Used in all API routes |
| Rate limiting (login + mobile-api) | DONE | `throttle:login`, `throttle:mobile-api` in routes |
| RBAC enforcement (EnsureRole middleware) | DONE | Visible in api.php groups |
| Laravel Policies for authz gap | PARTIAL | Needs audit — AttendancePolicy etc. may be missing |
| HTTPS / SSL setup documented | MISSING | Not in README |
| Docker Compose for production | UNKNOWN | FLOZ_README references Docker but single-school config unclear |
| DB backup strategy documented | MISSING | FLOZ_README has backup section but it's multi-tenant era |
| Seeder / demo data for SDN Kelapadua IV | UNKNOWN | Seeder refactored (`ef7a802`); completeness unclear |
| Error monitoring (Sentry / log aggregation) | MISSING | Not referenced anywhere |
| Mobile build CI (Android + iOS green) | UNKNOWN | Claimed in Phase5 DoD but no CI config found in scope |
| Swagger doc rendered at `/api/documentation` | PARTIAL | `/docs` page exists; full annotation status unknown |

---

## Summary

**Phase 5 is functionally complete for the 11-slice core.** All teacher and student mobile features are merged. Web features are comprehensive. Key gaps:

1. **Student assignment submission** (POST) is the only missing API slice promised in spec.
2. **Policy gap closure** (AttendancePolicy etc.) is a security concern per Phase 5 Step 0 DoD.
3. **Academic Year / Semester web CRUD** has no visible pages or routes.
4. **Parent role** has zero implementation (web or mobile) — deliberately deferred but still a spec promise.
5. **Production readiness** (SSL docs, backup runbook, error monitoring, CI) needs work before go-live.
