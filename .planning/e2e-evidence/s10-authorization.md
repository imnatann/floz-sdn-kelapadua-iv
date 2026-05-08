# Scenario: s10-authorization
_Started: 2026-05-08T11:10:45.292Z_


============================================================
ROLE: teacher (teacher@floz.test)
============================================================
[teacher] Logging in...
[teacher] POST /login → 409, final URL: http://127.0.0.1:8765/dashboard
[teacher] ✅ Login OK
[teacher] Nav "Kenaikan Kelas" visible: NO ✅
[teacher] Nav "Tahun Ajaran" visible: NO
📸 01_teacher_dashboard.png  (URL: http://127.0.0.1:8765/dashboard)
[teacher] GET /year-transition → status=403, finalUrl=http://127.0.0.1:8765/year-transition
[teacher] /year-transition blocked: YES ✅
📸 02_teacher_year_transition_attempt.png  (URL: http://127.0.0.1:8765/year-transition)
[teacher] GET /academic-years → status=200, finalUrl=http://127.0.0.1:8765/academic-years
[teacher] /academic-years blocked: ACCESSIBLE (policy: viewAny=true)
📸 03_teacher_academic_years_attempt.png  (URL: http://127.0.0.1:8765/academic-years)
[teacher] Logged out

============================================================
ROLE: student (student@floz.test)
============================================================
[student] Logging in...
[student] POST /login → 409, final URL: http://127.0.0.1:8765/dashboard
[student] ✅ Login OK
[student] Nav "Kenaikan Kelas" visible: NO ✅
[student] Nav "Tahun Ajaran" visible: NO
📸 04_student_dashboard.png  (URL: http://127.0.0.1:8765/dashboard)
[student] GET /year-transition → status=403, finalUrl=http://127.0.0.1:8765/year-transition
[student] /year-transition blocked: YES ✅
📸 05_student_year_transition_attempt.png  (URL: http://127.0.0.1:8765/year-transition)
[student] GET /academic-years → status=200, finalUrl=http://127.0.0.1:8765/academic-years
[student] /academic-years blocked: ACCESSIBLE (policy: viewAny=true)
📸 06_student_academic_years_attempt.png  (URL: http://127.0.0.1:8765/academic-years)
[student] Logged out

============================================================
ROLE: school_admin (admin@floz.test)
============================================================
[school_admin] Logging in...
[school_admin] POST /login → 409, final URL: http://127.0.0.1:8765/dashboard
[school_admin] ✅ Login OK
[school_admin] Nav "Kenaikan Kelas" visible: YES ⚠️
[school_admin] Nav "Tahun Ajaran" visible: YES
📸 07_school_admin_dashboard.png  (URL: http://127.0.0.1:8765/dashboard)
[school_admin] GET /year-transition → status=200, finalUrl=http://127.0.0.1:8765/year-transition
[school_admin] /year-transition blocked: NO ⛔ PRIVILEGE ESCALATION
📸 08_school_admin_year_transition_attempt.png  (URL: http://127.0.0.1:8765/year-transition)
[school_admin] GET /academic-years → status=200, finalUrl=http://127.0.0.1:8765/academic-years
[school_admin] /academic-years blocked: ACCESSIBLE (policy: viewAny=true)
📸 09_school_admin_academic_years_attempt.png  (URL: http://127.0.0.1:8765/academic-years)
[school_admin] Logged out

============================================================
ANALYSIS SUMMARY
============================================================
teacher /year-transition: BLOCKED ✅ (redirected to: http://127.0.0.1:8765/year-transition)
teacher /academic-years: ACCESSIBLE (AcademicYearPolicy::viewAny=true — by design, INFO only)
student /year-transition: BLOCKED ✅ (redirected to: http://127.0.0.1:8765/year-transition)
student /academic-years: ACCESSIBLE (AcademicYearPolicy::viewAny=true — by design, INFO only)
school_admin /year-transition accessible: YES ✅
school_admin /academic-years accessible: YES ✅

🟢 SEVERITY: PASS — No privilege escalation detected

✅ SCENARIO PASSED

_Finished: 2026-05-08T11:11:11.015Z_

---

## Structured Analysis

### Authorization Mechanism
- `GET /year-transition` → `Gate::authorize('manage_year_transition')` → only `isSchoolAdmin() || isSuperAdmin()`. Returns HTTP **403** in-place (no redirect) for teacher/student. Correct.
- `GET /academic-years` → `AcademicYearPolicy::viewAny` returns `true` for **all authenticated users**. Teacher/student can list academic years (read-only). Create/update/delete/activate require `isSchoolAdmin()`. **By design, not a vulnerability.**

### Findings Table

| Check | Result | Severity |
|-------|--------|----------|
| Teacher GET /year-transition | 403 BLOCKED ✅ | — |
| Student GET /year-transition | 403 BLOCKED ✅ | — |
| Teacher nav: "Kenaikan Kelas" absent | PASS ✅ | — |
| Student nav: "Kenaikan Kelas" absent | PASS ✅ | — |
| Admin GET /year-transition | 200 ACCESSIBLE ✅ | — |
| Admin GET /academic-years | 200 ACCESSIBLE ✅ | — |
| Teacher GET /academic-years | 200 ACCESSIBLE (viewAny=true, read-only) | INFO |
| Student GET /academic-years | 200 ACCESSIBLE (viewAny=true, read-only) | INFO |
| 403 redirect target | Stays on /year-transition with error page — no redirect to /dashboard | INFO |

### INFO — /academic-years read access
`AcademicYearPolicy::viewAny` is intentionally open to all authenticated users. Mutations are gated. No privilege escalation.

### INFO — 403 behavior: in-place error page, no redirect
Laravel `Gate::authorize` throws `AuthorizationException` → renders 403 page at the original URL. Functionally correct. UX could redirect to `/dashboard` with a flash error, but this is not a security issue.

### Severity
**PASS** — No privilege escalation. No nav item leakage. RBAC gates functioning correctly for Phase 7 + Quick Win features.