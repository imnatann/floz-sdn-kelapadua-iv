# Mobile Permission Audit — Design

**Date:** 2026-05-13
**Scope:** `floz_mobile/` (Flutter)
**Type:** Audit (E2E integration tests + findings doc). No bug fixes in this milestone.
**Branch:** `chore/remove-tenant-leftovers` (or a new branch off it)

---

## 1. Goal

Audit the Flutter mobile app's permission enforcement and role-based routing across all four user roles to identify scope leaks and feature gaps relative to the web app — without fixing them in this pass. Output is a reproducible test suite plus a findings document for follow-up remediation, mirroring the structure that worked for the web audit (`AUDIT_HANDOFF.md`).

## 2. Background

The web app recently completed a full role-based permission audit (sessions S163–S167, commits `5e17f4d` → `d49c4e5`). The mobile app has not had an equivalent pass. Suspected issues already surfaced during context exploration:

- `lib/features/auth/domain/user_model.dart:44-46` checks `role == 'student'` / `'teacher'` / `'parent'`, but the backend `UserRole` enum stores Indonesian values (`siswa`, `guru`, `wali_kelas`, `admin`, `orang_tua`). If the backend returns the enum value verbatim, every mobile role getter is false → cascading auth failures.
- `User` model has no `isWaliKelas` / `isAdmin` getters at all.
- `RoleGuard.guard` does a literal `Set<String>` check, so it inherits the same string-mismatch risk.
- Existing integration tests (`student_flow_test.dart`, `teacher_flow_test.dart`) use `student@floz.test` / `teacher@floz.test` accounts that do not match the current DB seed. Wali kelas and admin paths are not covered by the existing suite at all.
- Hardcoded API base URL (`lib/core/constants/api_constants.dart:5`) cannot be overridden per environment without a code change.

These are hypotheses to verify; the audit confirms them as findings.

## 3. Roles & test credentials

Provided by the user; backend already seeded:

| Role          | Email                              | Password      | Notes                                           |
|---------------|-------------------------------------|---------------|-------------------------------------------------|
| Admin         | admin@floz.test                     | password123   |                                                 |
| Wali Kelas 1A | mariam.s@sdkelapadua4.sch.id        | password123   | Also covers "guru biasa" subject-teaching paths |
| Wali Kelas 2A | hendra.w@sdkelapadua4.sch.id        | password123   | Used for cross-scope negative tests vs mariam   |
| Siswa         | 24001@siswa.sekolah.id              | password      | Note: 8-char password, not `password123`        |

A dedicated "guru biasa without homeroom" account is out of scope; deferred to a follow-up audit if needed.

## 4. Architecture

```
floz_mobile/
├─ integration_test/
│   ├─ helpers.dart                      [existing — initApp, login, tapNavTab]
│   ├─ audit_helpers.dart                [new]
│   ├─ AUDIT_README.md                   [new]
│   ├─ auth_edge_cases_test.dart         [existing — no change]
│   ├─ student_flow_test.dart            [migrate credentials]
│   ├─ teacher_flow_test.dart            [migrate credentials]
│   ├─ walikelas_flow_test.dart          [new]
│   ├─ admin_flow_test.dart              [new]
│   └─ permission_leaks_test.dart        [new]
└─ lib/features/student/shared/
   │  student_shell.dart                 [add Key('shell.student')]
   └─ teacher/shared/teacher_shell.dart  [add Key('shell.teacher')]

MOBILE_AUDIT_HANDOFF.md                  [new, repo root]
```

No business-logic changes. Only:
1. Two `Key()` additions on shell widgets (non-functional).
2. New test files + helpers.
3. New documentation.

## 5. `audit_helpers.dart` API

```dart
class AuditCredentials {
  final String email;
  final String password;
  final String role;  // 'admin' | 'wali' | 'siswa'
  const AuditCredentials(this.role, this.email, this.password);

  static const siswa = AuditCredentials('siswa',
      String.fromEnvironment('AUDIT_SISWA_EMAIL',
          defaultValue: '24001@siswa.sekolah.id'),
      String.fromEnvironment('AUDIT_SISWA_PASSWORD',
          defaultValue: 'password'));
  static const wali1A = AuditCredentials('wali',
      String.fromEnvironment('AUDIT_WALI_1A_EMAIL',
          defaultValue: 'mariam.s@sdkelapadua4.sch.id'),
      String.fromEnvironment('AUDIT_WALI_1A_PASSWORD',
          defaultValue: 'password123'));
  static const wali2A = AuditCredentials('wali',
      String.fromEnvironment('AUDIT_WALI_2A_EMAIL',
          defaultValue: 'hendra.w@sdkelapadua4.sch.id'),
      String.fromEnvironment('AUDIT_WALI_2A_PASSWORD',
          defaultValue: 'password123'));
  static const admin = AuditCredentials('admin',
      String.fromEnvironment('AUDIT_ADMIN_EMAIL',
          defaultValue: 'admin@floz.test'),
      String.fromEnvironment('AUDIT_ADMIN_PASSWORD',
          defaultValue: 'password123'));
}

// Login with given credentials. Pump and settle. Returns post-login route.
Future<void> loginAsRole(WidgetTester tester, AuditCredentials creds);

// Asserts that the shell matching `expected` is mounted.
// expected ∈ { 'student', 'teacher', 'login', 'denied' }
Future<void> expectShellFor(WidgetTester tester, String expected);

// Direct API call using the current session's Sanctum token.
// For scope assertions where the UI does not expose the underlying data.
Future<Response> apiProbe(
  WidgetTester tester, {
  required String method,  // 'GET' | 'POST' | 'PUT' | 'DELETE'
  required String path,    // e.g. '/teacher/classes/2/attendance/roster'
  Map<String, dynamic>? body,
});

// Tries a deep link via GoRouter. Returns true if the user ends up
// on a different route than `path` (i.e. the guard redirected).
Future<bool> tryDeepLink(WidgetTester tester, String path);

// Health check used in `setUpAll` — if it fails, all tests in the group
// `skip` with a clear reason instead of cascading red.
Future<bool> backendReachable();
```

Environment overrides:

| Var                          | Default                                            |
|------------------------------|----------------------------------------------------|
| `AUDIT_API_BASE`             | `http://localhost:8000/api/v1`                     |
| `AUDIT_SISWA_EMAIL`          | `24001@siswa.sekolah.id`                           |
| `AUDIT_SISWA_PASSWORD`       | `password`                                         |
| `AUDIT_WALI_1A_EMAIL`        | `mariam.s@sdkelapadua4.sch.id`                     |
| `AUDIT_WALI_1A_PASSWORD`     | `password123`                                      |
| `AUDIT_WALI_2A_EMAIL`        | `hendra.w@sdkelapadua4.sch.id`                     |
| `AUDIT_WALI_2A_PASSWORD`     | `password123`                                      |
| `AUDIT_ADMIN_EMAIL`          | `admin@floz.test`                                  |
| `AUDIT_ADMIN_PASSWORD`       | `password123`                                      |

## 6. Test coverage

### 6.1 `walikelas_flow_test.dart` (mariam.s)

| # | Scenario                                                      | Assertion                                                                 |
|---|---------------------------------------------------------------|---------------------------------------------------------------------------|
| 1 | Login → routing                                               | Landing on `Key('shell.teacher')`                                          |
| 2 | Tab `Kelas`                                                   | At least one teaching assignment listed; tap → MeetingsScreen reachable    |
| 3 | Tab `Nilai`                                                   | Grade input screen rendered with save button visible                       |
| 4 | Tab `Rekap`                                                   | Grade & attendance recap loads without exception                           |
| 5 | Daily attendance for homeroom (kelas 1A)                      | `MobileTeacherDailyAttendanceController` returns 200 for class_id 1A       |
| 6 | Profile → logout                                              | Returns to `/login`                                                        |

### 6.2 `admin_flow_test.dart`

| # | Scenario                                                      | Assertion                                                                 |
|---|---------------------------------------------------------------|---------------------------------------------------------------------------|
| 1 | Login → routing decision                                      | Document outcome; assert NOT mounted on `Key('shell.student')` or `Key('shell.teacher')` |
| 2 | Deep link `/student`                                          | Guard redirects                                                            |
| 3 | Deep link `/teacher`                                          | Guard redirects                                                            |
| 4 | API: GET `/student/dashboard` with admin token                | Expect 403 OR a clearly-admin-shaped response (document which)             |

### 6.3 `permission_leaks_test.dart` (cross-role)

| # | Subject  | Scenario                                                    | Assertion                                                            |
|---|----------|-------------------------------------------------------------|----------------------------------------------------------------------|
| 1 | siswa    | Deep-link `/teacher`                                        | Redirected to `/student` or `/login`                                 |
| 2 | wali 1A  | Deep-link `/student`                                        | Redirected to `/teacher` or `/login`                                 |
| 3 | siswa    | API GET `/student/grades` payload                           | Every row's `student_id` == self.id                                  |
| 4 | wali 1A  | API GET `/teacher/classes/<2A_id>/attendance/roster`        | 403 or empty. `<2A_id>` discovered by logging in as Hendra (wali 2A) first, listing her classes, and capturing the class_id |
| 5 | wali 1A  | API POST grade to a teaching_assignment_id owned by Hendra  | 403. Foreign teaching_assignment_id discovered the same way (login as Hendra → list teaching assignments)                    |
| 6 | siswa    | API POST `/student/grades` (or equivalent write)            | 403 (mirrors web audit finding A5)                                   |
| 7 | wali 1A  | API hit admin-only endpoint with wali token                 | 403                                                                  |

### 6.4 `student_flow_test.dart` (existing — update)

- Credentials → `24001@siswa.sekolah.id` / `password`
- Add one negative assertion on the "Nilai" tab: no grade-input UI is rendered (siswa is read-only). The exact widget key checked is decided when the test is written; the assertion exists either way.

### 6.5 `teacher_flow_test.dart` (existing — update)

- Credentials → `mariam.s@sdkelapadua4.sch.id` / `password123`
- No new assertions; just keep the smoke green.

## 7. Findings document — `MOBILE_AUDIT_HANDOFF.md`

Lives at repo root, mirrors `AUDIT_HANDOFF.md`.

```markdown
# Mobile Audit Handoff — 2026-05-13

Branch:          chore/remove-tenant-leftovers
Backend target:  http://localhost:8000 (seeded)
Test suite:      floz_mobile/integration_test/

## Summary
- N findings (X CRITICAL, Y HIGH, Z MEDIUM, W LOW)
- Tests passing: A / Total: B
- Tests skipped: K (reason captured per test)

## Findings

### [CRITICAL] M-001 — isStudent/isTeacher returns false for enum-cased roles
File:        floz_mobile/lib/features/auth/domain/user_model.dart:44-46
Evidence:    permission_leaks_test.dart:42 (siswa login expected StudentShell, got login)
Root cause:  Backend returns role='siswa'; mobile checks role=='student'.
Severity:    CRITICAL — siswa cannot use the app at all if backend returns enum.
Suggested:   Align mobile role checks with backend UserRole enum.
Status:      OPEN

### [HIGH] M-002 — ...
```

### Severity rubric

- **CRITICAL** — cross-role scope leak; write access outside permissions; hardcoded auth bypass; legitimate user fully blocked.
- **HIGH** — broken role gating that lets read-only access to wrong-role data, or breaks one major flow but app still partially usable.
- **MEDIUM** — feature gap vs web (e.g., no semester/subject filter, missing screen). Functional but parity issue.
- **LOW** — UX, dead code, stale fixtures, hardcoded constants without an env override.

## 8. Run instructions — `integration_test/AUDIT_README.md`

Single-page how-to:
1. Start backend: `php artisan serve` from `src/`.
2. Confirm seeded accounts exist (table from §3).
3. From `floz_mobile/`, run e.g.:
   `flutter test integration_test/permission_leaks_test.dart --dart-define=AUDIT_API_BASE=http://localhost:8000/api/v1`
4. If a test reports `skip: backend unreachable`, fix backend before retrying.
5. Findings get appended to `MOBILE_AUDIT_HANDOFF.md`. Each finding cites the test file:line that produced it.

## 9. Implementation order (5 commits)

1. `feat(mobile/audit): audit_helpers + shell widget keys`
   — New `audit_helpers.dart`, add `Key('shell.student')` / `Key('shell.teacher')`.
2. `feat(mobile/audit): walikelas_flow_test + admin_flow_test`
3. `feat(mobile/audit): permission_leaks_test (cross-role)`
4. `fix(mobile/audit): migrate existing student/teacher flow to current seed credentials`
5. `docs(mobile/audit): MOBILE_AUDIT_HANDOFF.md + AUDIT_README.md`

Each commit independent and revertable.

## 10. Out of scope

- **Bug fixes.** Any leak surfaced by the suite is documented, not patched. Fixes happen in a follow-up session.
- **New features** (Tasks/Exams mobile, semester filter, Excel export, password reset). Tracked separately.
- **Visual regression / a11y / performance** audits.
- **Unit tests** in `floz_mobile/test/`. Only `integration_test/` is touched.
- **Adding a "guru biasa without homeroom" user.** Mariam doubles as both wali and subject teacher for this pass.
- **Refactoring** `User`, `RoleGuard`, `ApiConstants`. Even if obviously broken — they become findings.

## 11. Risks & mitigations

| Risk | Mitigation |
|---|---|
| `User.isStudent => role == 'student'` mismatch causes siswa login to redirect → all siswa tests fail at step 1 | First test in `permission_leaks_test.dart` asserts shell routing per role. If it fails, dependent tests `skip` with a clear reason rather than cascading red. The failure itself becomes finding M-001. |
| `student@floz.test` / `teacher@floz.test` in existing tests fail because seed uses different emails | Migrate as commit 4. Existing tests go green after migration. |
| Stable widget keys absent on shells | Commit 1 adds them. Two-line change, no logic touch. |
| `apiProbe` needs Dio instance + Sanctum token from the running app | Helper reaches into the same `ProviderContainer` mounted by `FlozApp`; reads token via `authSessionProvider`. |
| Backend port 8000 not up when test runs | `setUpAll` hits `/api/v1/health`; if unreachable, all tests `skip("backend not reachable")` — no false negatives. |
| Admin has no admin shell at all → undefined behaviour | That's the finding. `admin_flow_test.dart` documents whatever happens (redirect target, blank screen, etc.). |
| `apiProbe` body shapes assume mobile-specific endpoints; some may not exist or may be tenant-shaped | Tolerated: any 404 surfaces as a feature-parity MEDIUM finding rather than a test crash. |

## 12. Success criteria

1. Five integration test files compile and either pass or `skip` with explicit reason.
2. `MOBILE_AUDIT_HANDOFF.md` exists at repo root with at least one finding per role audited (siswa, wali kelas, admin) and a severity rating per finding.
3. `integration_test/AUDIT_README.md` exists with run instructions including env var examples.
4. `audit_helpers.dart` exposes at least: `loginAsRole`, `expectShellFor`, `apiProbe`, `tryDeepLink`, `backendReachable`.
5. Two stable widget keys added: `Key('shell.student')`, `Key('shell.teacher')`.
6. All five commits land in linear order, each independently revertable.
