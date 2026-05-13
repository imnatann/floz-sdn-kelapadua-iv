# Mobile Permission Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a reproducible E2E permission audit of the Flutter mobile app across siswa, wali kelas, and admin roles, capturing scope leaks and feature gaps into `MOBILE_AUDIT_HANDOFF.md`. **No bug fixes** — findings only.

**Architecture:** Five Flutter `integration_test/` files run against a live seeded Laravel backend on `localhost:8000`. A shared `audit_helpers.dart` exposes credentialed login, shell assertion, deep-link probing, and raw API probing (independent Dio instance, reusing the Sanctum token in `flutter_secure_storage`). Each test produces evidence (pass/fail/skip with reason) that is hand-synthesized into a severity-ranked findings doc.

**Tech Stack:** Flutter 3.x · integration_test · flutter_riverpod 2.6 · go_router 17 · dio 5.7 · flutter_secure_storage 10. Backend: Laravel 11 at `http://localhost:8000/api/v1`.

**Spec:** `docs/superpowers/specs/2026-05-13-mobile-permission-audit-design.md`

**Working directory for all commands below:** `floz_mobile/` (unless explicitly noted otherwise).

---

## Test credentials (seeded, do NOT change)

| Role          | Email                              | Password      |
|---------------|------------------------------------|---------------|
| Admin         | admin@floz.test                    | password123   |
| Wali Kelas 1A | mariam.s@sdkelapadua4.sch.id       | password123   |
| Wali Kelas 2A | hendra.w@sdkelapadua4.sch.id       | password123   |
| Siswa         | 24001@siswa.sekolah.id             | password      |

Siswa password is `password` (8 chars), NOT `password123`. This is a tripwire.

---

## File map

| Path                                                                 | Action  | Responsibility                                              |
|----------------------------------------------------------------------|---------|-------------------------------------------------------------|
| `lib/features/student/shared/widgets/student_shell.dart`             | Modify  | Add `Key('shell.student')` to Scaffold                       |
| `lib/features/teacher/shared/widgets/teacher_shell.dart`             | Modify  | Add `Key('shell.teacher')` to Scaffold                       |
| `integration_test/audit_helpers.dart`                                | Create  | Credentials, login, shell assertion, deep-link, apiProbe     |
| `integration_test/walikelas_flow_test.dart`                          | Create  | Smoke: mariam.s login → shell → tabs → daily attendance      |
| `integration_test/admin_flow_test.dart`                              | Create  | Smoke + negative: admin login routing & shell isolation      |
| `integration_test/permission_leaks_test.dart`                        | Create  | Cross-role scope/negative assertions                         |
| `integration_test/student_flow_test.dart`                            | Modify  | Migrate credentials; add one negative assertion              |
| `integration_test/teacher_flow_test.dart`                            | Modify  | Migrate credentials                                          |
| `integration_test/AUDIT_README.md`                                   | Create  | Single-page how-to-run                                       |
| `../MOBILE_AUDIT_HANDOFF.md` (repo root)                             | Create  | Severity-ranked findings, hand-written from test evidence    |

---

## Background you need to know

- **App entry** is `FlozApp` (in `lib/app.dart`); wrap in `ProviderScope` for tests (see existing `integration_test/helpers.dart`).
- **API base URL** is hardcoded in `lib/core/constants/api_constants.dart` to `http://localhost:8000/api/v1`. The audit honors this default but lets you override via `--dart-define=AUDIT_API_BASE=...`.
- **Sanctum token** is written to `flutter_secure_storage` under key `floz_mobile_token` after a successful login (see `lib/core/storage/secure_token_storage.dart:10`).
- **Login screen keys** are `Key('login.email')`, `Key('login.password')`, `Key('login.submit')`. Already used by existing tests.
- **Health endpoint** is `GET /healthz` at the web root (NOT under `/api/v1`), defined in `src/routes/web.php:32`.
- **Existing tests** (`student_flow_test.dart`, `teacher_flow_test.dart`) use stale `student@floz.test` / `teacher@floz.test` accounts. Migrating them is part of this plan.

---

## How to interpret test outcomes during this audit

This is an **audit**, not a feature build. A failing or skipping test is **expected** and is the data we record. Do NOT change source code to make a failing test pass — the failure IS the finding.

Per task, after running the test suite, jot down in a scratch note:

```
TEST: <test_name>
RESULT: pass | fail | skip
EVIDENCE: <one-line reason — error message / unexpected route / 200 instead of 403 / etc.>
```

These notes feed Task 9 (`MOBILE_AUDIT_HANDOFF.md`).

If a test crashes the suite outright (compile error, helper bug) that's a plan bug — fix the test, do not "fix" the app.

---

## Task 1: Add stable widget keys to shells

**Files:**
- Modify: `lib/features/student/shared/widgets/student_shell.dart`
- Modify: `lib/features/teacher/shared/widgets/teacher_shell.dart`

These keys give the audit a stable, non-text way to assert which shell is mounted after login. Adding a `Key` is a non-functional change.

- [ ] **Step 1: Add the student-shell key**

Open `lib/features/student/shared/widgets/student_shell.dart`. Inside `build()`, find the line `return Scaffold(` and change it to:

```dart
    return Scaffold(
      key: const Key('shell.student'),
      body: _buildTab(index),
      bottomNavigationBar: NavigationBar(
```

Keep the rest of the Scaffold's properties exactly as they were.

- [ ] **Step 2: Add the teacher-shell key**

Open `lib/features/teacher/shared/widgets/teacher_shell.dart`. Inside `build()`, find the `return Scaffold(` and add `key: const Key('shell.teacher'),` as its first argument, exactly mirroring Step 1.

- [ ] **Step 3: Run analyzer**

From `floz_mobile/`:

```bash
flutter analyze lib/features/student/shared/widgets/student_shell.dart lib/features/teacher/shared/widgets/teacher_shell.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/student/shared/widgets/student_shell.dart \
        lib/features/teacher/shared/widgets/teacher_shell.dart
git commit -m "$(cat <<'EOF'
feat(mobile/audit): add stable widget keys on student/teacher shells

Adds Key('shell.student') and Key('shell.teacher') so the upcoming
permission audit can assert which shell is mounted after login without
relying on text labels (which are localized).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Create `audit_helpers.dart`

**Files:**
- Create: `integration_test/audit_helpers.dart`

Single self-contained helpers file. No edits to existing `helpers.dart` (kept as-is for the older smoke tests).

- [ ] **Step 1: Create the file with full content**

Create `floz_mobile/integration_test/audit_helpers.dart` with this exact content:

```dart
// Audit helpers — used by walikelas_flow_test, admin_flow_test,
// permission_leaks_test, and the migrated student/teacher flow tests.
//
// Conventions:
// - All helpers assume the app is already pumped via `initApp` from helpers.dart.
// - Credentials default to the seeded values from the audit spec but can be
//   overridden via --dart-define at run time.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class AuditCredentials {
  final String role; // 'admin' | 'wali' | 'siswa'
  final String email;
  final String password;
  const AuditCredentials(this.role, this.email, this.password);

  static const siswa = AuditCredentials(
    'siswa',
    String.fromEnvironment(
      'AUDIT_SISWA_EMAIL',
      defaultValue: '24001@siswa.sekolah.id',
    ),
    String.fromEnvironment(
      'AUDIT_SISWA_PASSWORD',
      defaultValue: 'password',
    ),
  );

  static const wali1A = AuditCredentials(
    'wali',
    String.fromEnvironment(
      'AUDIT_WALI_1A_EMAIL',
      defaultValue: 'mariam.s@sdkelapadua4.sch.id',
    ),
    String.fromEnvironment(
      'AUDIT_WALI_1A_PASSWORD',
      defaultValue: 'password123',
    ),
  );

  static const wali2A = AuditCredentials(
    'wali',
    String.fromEnvironment(
      'AUDIT_WALI_2A_EMAIL',
      defaultValue: 'hendra.w@sdkelapadua4.sch.id',
    ),
    String.fromEnvironment(
      'AUDIT_WALI_2A_PASSWORD',
      defaultValue: 'password123',
    ),
  );

  static const admin = AuditCredentials(
    'admin',
    String.fromEnvironment(
      'AUDIT_ADMIN_EMAIL',
      defaultValue: 'admin@floz.test',
    ),
    String.fromEnvironment(
      'AUDIT_ADMIN_PASSWORD',
      defaultValue: 'password123',
    ),
  );
}

const String _apiBase = String.fromEnvironment(
  'AUDIT_API_BASE',
  defaultValue: 'http://localhost:8000/api/v1',
);

// Health endpoint lives at the web root, NOT under /api/v1.
String get _healthUrl =>
    Uri.parse(_apiBase).replace(path: '/healthz').toString();

const _tokenStorageKey = 'floz_mobile_token';
const _secureStorage = FlutterSecureStorage();

/// Returns true if GET /healthz returns 2xx.
/// Tests should call this in `setUpAll` and skip the group on false.
Future<bool> backendReachable() async {
  try {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
    ));
    final res = await dio.get<dynamic>(_healthUrl);
    return res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300;
  } catch (_) {
    return false;
  }
}

/// Performs the login flow with the given credentials. Caller is responsible
/// for calling `initApp(tester)` first.
Future<void> loginAsRole(WidgetTester tester, AuditCredentials creds) async {
  final emailField = find.byKey(const Key('login.email'));
  final passwordField = find.byKey(const Key('login.password'));
  final submitBtn = find.byKey(const Key('login.submit'));

  expect(emailField, findsOneWidget, reason: 'login screen not mounted');
  await tester.enterText(emailField, creds.email);
  await tester.enterText(passwordField, creds.password);
  await tester.tap(submitBtn);
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

/// Asserts the shell currently mounted.
///
/// expected ∈ { 'student', 'teacher', 'login', 'denied' }
/// - 'login'  — the login screen is showing (i.e. routing rejected us back)
/// - 'denied' — none of the known shells AND not login; useful for documenting
///              admin behaviour when no admin shell exists.
void expectShellFor(WidgetTester tester, String expected) {
  final loginField = find.byKey(const Key('login.email'));
  final studentShell = find.byKey(const Key('shell.student'));
  final teacherShell = find.byKey(const Key('shell.teacher'));

  switch (expected) {
    case 'student':
      expect(studentShell, findsOneWidget,
          reason: 'expected StudentShell, not mounted');
      expect(loginField, findsNothing,
          reason: 'still on login screen unexpectedly');
      break;
    case 'teacher':
      expect(teacherShell, findsOneWidget,
          reason: 'expected TeacherShell, not mounted');
      expect(loginField, findsNothing,
          reason: 'still on login screen unexpectedly');
      break;
    case 'login':
      expect(loginField, findsOneWidget,
          reason: 'expected to be on login screen');
      break;
    case 'denied':
      expect(studentShell, findsNothing,
          reason: 'StudentShell leaked');
      expect(teacherShell, findsNothing,
          reason: 'TeacherShell leaked');
      break;
    default:
      fail('unknown shell expectation: $expected');
  }
}

/// Direct API call using the token currently stored in flutter_secure_storage.
/// Bypasses the UI/Dio interceptor stack — gives us raw status code/body for
/// scope assertions.
///
/// Returns the Response (does NOT throw on 4xx/5xx). Tests check the
/// statusCode themselves.
Future<Response<dynamic>> apiProbe({
  required String method,
  required String path,
  Map<String, dynamic>? body,
}) async {
  final token = await _secureStorage.read(key: _tokenStorageKey);

  final dio = Dio(BaseOptions(
    baseUrl: _apiBase,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
    // Do not throw — let the caller inspect the status code.
    validateStatus: (_) => true,
  ));

  return dio.request<dynamic>(
    path,
    data: body,
    options: Options(method: method),
  );
}

/// Clears the stored Sanctum token (use in tearDown to fully reset
/// between tests).
Future<void> clearAuthToken() async {
  await _secureStorage.delete(key: _tokenStorageKey);
}
```

- [ ] **Step 2: Run analyzer**

```bash
flutter analyze integration_test/audit_helpers.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add integration_test/audit_helpers.dart
git commit -m "$(cat <<'EOF'
feat(mobile/audit): add audit_helpers.dart for permission tests

Provides AuditCredentials (env-overridable), loginAsRole, expectShellFor,
apiProbe (raw Dio with stored Sanctum token, no exceptions on 4xx),
backendReachable health check, and clearAuthToken.

Pure helper layer — does not touch app source.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Add `walikelas_flow_test.dart` (smoke)

**Files:**
- Create: `integration_test/walikelas_flow_test.dart`

Wali kelas 1A (mariam.s) smoke test. Six scenarios from spec §6.1.

- [ ] **Step 1: Create the test file**

Create `floz_mobile/integration_test/walikelas_flow_test.dart` with this exact content:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'audit_helpers.dart';
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Wali Kelas 1A E2E (mariam.s)', () {
    setUpAll(() async {
      final ok = await backendReachable();
      if (!ok) {
        markTestSkipped('backend not reachable at /healthz');
      }
    });

    tearDown(() async {
      await clearAuthToken();
    });

    testWidgets('login → lands on TeacherShell', (tester) async {
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.wali1A);
      expectShellFor(tester, 'teacher');
    });

    testWidgets('Kelas tab lists at least one teaching assignment',
        (tester) async {
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.wali1A);
      expectShellFor(tester, 'teacher');

      // Already on Kelas (default tab). Settle and assert non-empty.
      await tester.pumpAndSettle(const Duration(seconds: 3));
      final emptyState = find.text('Belum ada kelas');
      expect(emptyState, findsNothing,
          reason: 'wali 1A should have at least one teaching assignment');
    });

    testWidgets('Nilai tab renders grade-input affordance', (tester) async {
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.wali1A);

      final nilaiTab = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Nilai'),
      );
      expect(nilaiTab, findsOneWidget);
      await tester.tap(nilaiTab);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Heuristic: a teacher-grade screen surfaces a class list to choose
      // from. The exact widget key varies; assert no error banner showing.
      final errorBanner = find.text('Terjadi kesalahan');
      expect(errorBanner, findsNothing,
          reason: 'Nilai tab should load without error for wali 1A');
    });

    testWidgets('Rekap tab loads without error', (tester) async {
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.wali1A);

      final rekapTab = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Rekap'),
      );
      expect(rekapTab, findsOneWidget);
      await tester.tap(rekapTab);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final errorBanner = find.text('Terjadi kesalahan');
      expect(errorBanner, findsNothing);
    });

    testWidgets('API: wali 1A can fetch own teacher classes', (tester) async {
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.wali1A);

      final res = await apiProbe(method: 'GET', path: '/teacher/classes');
      expect(res.statusCode, 200,
          reason: 'expected 200 from /teacher/classes for wali 1A '
              '(got ${res.statusCode})');
    });

    testWidgets('logout → back at login screen', (tester) async {
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.wali1A);

      final profileBtn = find.byIcon(Icons.person_outlined);
      if (profileBtn.evaluate().isEmpty) {
        markTestSkipped('profile icon not found in top bar');
        return;
      }
      await tester.tap(profileBtn.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final logoutBtn = find.text('Keluar');
      if (logoutBtn.evaluate().isEmpty) {
        markTestSkipped('logout button not found on profile screen');
        return;
      }
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final confirmBtn = find.text('Ya, Keluar');
      if (confirmBtn.evaluate().isNotEmpty) {
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      expectShellFor(tester, 'login');
    });
  });
}
```

- [ ] **Step 2: Run the test and capture results**

```bash
flutter test integration_test/walikelas_flow_test.dart -r expanded
```

This may take 30–90 seconds. Record EACH test's result (pass/fail/skip) plus a one-line reason in your audit notes. Do NOT modify source to make failures pass — failures are findings.

- [ ] **Step 3: Commit (regardless of test outcomes)**

```bash
git add integration_test/walikelas_flow_test.dart
git commit -m "$(cat <<'EOF'
feat(mobile/audit): add walikelas_flow_test.dart (smoke)

Six scenarios for wali kelas 1A (mariam.s): login routing, Kelas tab
populated, Nilai/Rekap tabs render without error, /teacher/classes API
returns 200, logout. Skips if backend unreachable.

Test failures are NOT bugs to fix here — they feed
MOBILE_AUDIT_HANDOFF.md.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Add `admin_flow_test.dart` (smoke + negative)

**Files:**
- Create: `integration_test/admin_flow_test.dart`

Admin role. The mobile likely has no admin shell; the test documents whatever happens — that's the data.

- [ ] **Step 1: Create the test file**

Create `floz_mobile/integration_test/admin_flow_test.dart` with this exact content:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'audit_helpers.dart';
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Admin E2E (admin@floz.test)', () {
    setUpAll(() async {
      final ok = await backendReachable();
      if (!ok) {
        markTestSkipped('backend not reachable at /healthz');
      }
    });

    tearDown(() async {
      await clearAuthToken();
    });

    testWidgets('login: must NOT leak into StudentShell or TeacherShell',
        (tester) async {
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.admin);

      // Admin has no role-appropriate shell on mobile. Acceptable outcomes:
      //   (a) stayed on login screen — assert via expectShellFor('login')
      //   (b) some "denied"/"info" screen — assert via 'denied'
      // FAIL outcome: leaks into student or teacher shell.
      final inStudent = find
          .byKey(const Key('shell.student'))
          .evaluate()
          .isNotEmpty;
      final inTeacher = find
          .byKey(const Key('shell.teacher'))
          .evaluate()
          .isNotEmpty;
      expect(inStudent, false,
          reason: 'admin token landed in StudentShell — scope leak');
      expect(inTeacher, false,
          reason: 'admin token landed in TeacherShell — scope leak');
    });

    testWidgets('API: admin token on /student/dashboard → expect 403',
        (tester) async {
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.admin);

      final res = await apiProbe(method: 'GET', path: '/student/dashboard');
      // Acceptable: 403 (forbidden), 401 (token rejected), or 404
      // (route gated server-side). NOT acceptable: 200.
      expect(res.statusCode == 200, false,
          reason: '/student/dashboard returned 200 to admin token — leak');
    });

    testWidgets('API: admin token on /teacher/classes → expect non-200',
        (tester) async {
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.admin);

      final res = await apiProbe(method: 'GET', path: '/teacher/classes');
      expect(res.statusCode == 200, false,
          reason: '/teacher/classes returned 200 to admin token — leak');
    });
  });
}
```

- [ ] **Step 2: Run the test and capture results**

```bash
flutter test integration_test/admin_flow_test.dart -r expanded
```

Record outcomes in audit notes.

- [ ] **Step 3: Commit**

```bash
git add integration_test/admin_flow_test.dart
git commit -m "$(cat <<'EOF'
feat(mobile/audit): add admin_flow_test.dart (no-leak assertions)

Three scenarios documenting admin behaviour on mobile (no admin shell
exists): asserts admin does NOT land in StudentShell/TeacherShell after
login, and that /student/dashboard + /teacher/classes do not return 200
to an admin token.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Add `permission_leaks_test.dart` (cross-role)

**Files:**
- Create: `integration_test/permission_leaks_test.dart`

The most important test file. Seven scenarios from spec §6.3. Some require chaining logins (login as Hendra, capture an ID, login as Mariam, attack with Hendra's ID).

- [ ] **Step 1: Create the test file**

Create `floz_mobile/integration_test/permission_leaks_test.dart` with this exact content:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'audit_helpers.dart';
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Permission Leaks (cross-role)', () {
    setUpAll(() async {
      final ok = await backendReachable();
      if (!ok) {
        markTestSkipped('backend not reachable at /healthz');
      }
    });

    tearDown(() async {
      await clearAuthToken();
    });

    testWidgets('siswa login lands on StudentShell (NOT teacher/login)',
        (tester) async {
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.siswa);
      expectShellFor(tester, 'student');
    });

    testWidgets('wali 1A login lands on TeacherShell (NOT student/login)',
        (tester) async {
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.wali1A);
      expectShellFor(tester, 'teacher');
    });

    testWidgets('API: siswa /student/grades → every row.student_id == self',
        (tester) async {
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.siswa);

      // First read self id via /auth/me (mobile auth controller).
      final me = await apiProbe(method: 'GET', path: '/me');
      if (me.statusCode != 200) {
        markTestSkipped('/me did not return 200 — cannot verify scope');
        return;
      }
      final selfId = (me.data is Map) ? me.data['id'] : null;
      expect(selfId, isNotNull, reason: '/me response has no id');

      final res = await apiProbe(method: 'GET', path: '/student/grades');
      expect(res.statusCode, 200,
          reason: 'siswa cannot fetch own grades '
              '(got ${res.statusCode})');

      final data = res.data;
      final rows = (data is Map && data['data'] is List)
          ? data['data'] as List
          : (data is List ? data : const <dynamic>[]);
      for (final row in rows) {
        if (row is Map && row.containsKey('student_id')) {
          expect(row['student_id'], selfId,
              reason: 'siswa got a grade row for another student — leak');
        }
      }
    });

    testWidgets('API: wali 1A cannot read wali 2A daily attendance',
        (tester) async {
      // Login as Hendra (wali 2A) and discover one of her class IDs.
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.wali2A);
      final hendraClasses =
          await apiProbe(method: 'GET', path: '/teacher/classes');
      if (hendraClasses.statusCode != 200) {
        markTestSkipped(
            'could not list Hendra teacher classes (status '
            '${hendraClasses.statusCode})');
        return;
      }
      final list = (hendraClasses.data is Map &&
              hendraClasses.data['data'] is List)
          ? hendraClasses.data['data'] as List
          : (hendraClasses.data is List ? hendraClasses.data : const []);
      if (list.isEmpty) {
        markTestSkipped('Hendra has no classes — cannot test cross-scope');
        return;
      }
      final hendraClassId = (list.first is Map) ? list.first['id'] : null;
      expect(hendraClassId, isNotNull);
      await clearAuthToken();

      // Now login as Mariam and try to peek at Hendra's class.
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.wali1A);
      final res = await apiProbe(
        method: 'GET',
        path: '/teacher/classes/$hendraClassId/attendance/today',
      );
      // Acceptable: 403/404. Empty 200 with [] is borderline — record as
      // finding for review.
      expect(res.statusCode == 200 &&
              res.data is Map &&
              (res.data['data'] is List) &&
              (res.data['data'] as List).isNotEmpty,
          false,
          reason: 'Mariam got non-empty attendance for Hendra\'s class — '
              'leak (status ${res.statusCode})');
    });

    testWidgets(
        'API: wali 1A cannot POST grade to a TA owned by Hendra',
        (tester) async {
      // Discover one of Hendra's teaching assignment IDs.
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.wali2A);
      final tas =
          await apiProbe(method: 'GET', path: '/teacher/teaching-assignments');
      if (tas.statusCode != 200) {
        markTestSkipped(
            '/teacher/teaching-assignments returned ${tas.statusCode}');
        return;
      }
      final list = (tas.data is Map && tas.data['data'] is List)
          ? tas.data['data'] as List
          : (tas.data is List ? tas.data : const []);
      if (list.isEmpty) {
        markTestSkipped('Hendra has no teaching assignments');
        return;
      }
      final hendraTaId = (list.first is Map) ? list.first['id'] : null;
      expect(hendraTaId, isNotNull);
      await clearAuthToken();

      // Login as Mariam and attempt a POST against Hendra's TA.
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.wali1A);
      final res = await apiProbe(
        method: 'POST',
        path: '/teacher/teaching-assignments/$hendraTaId/grades',
        body: {'student_id': 1, 'category': 'tugas', 'score': 1},
      );
      // 403 expected. Anything 2xx is a finding.
      expect(res.statusCode != null && res.statusCode! >= 400, true,
          reason: 'Mariam was able to POST a grade to Hendra\'s TA — '
              'leak (status ${res.statusCode})');
    });

    testWidgets('API: siswa cannot POST a grade (write-path block)',
        (tester) async {
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.siswa);

      // We don't know a valid TA id as the student, so use id=1.
      // We're asserting the auth rejection, not the validation.
      final res = await apiProbe(
        method: 'POST',
        path: '/teacher/teaching-assignments/1/grades',
        body: {'student_id': 1, 'category': 'tugas', 'score': 99},
      );
      expect(res.statusCode != null && res.statusCode! >= 400, true,
          reason: 'siswa was able to POST a grade — '
              'leak (status ${res.statusCode})');
    });

    testWidgets('API: wali token rejected by admin-only endpoint',
        (tester) async {
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.wali1A);

      // Admin-only routes are not under /api/v1. We probe the namespace
      // that mobile would never hit legitimately — using a clearly
      // admin-flavoured path.
      final res = await apiProbe(method: 'GET', path: '/admin/users');
      expect(res.statusCode == 200, false,
          reason: 'wali got 200 on /admin/users — admin namespace leak');
    });
  });
}
```

- [ ] **Step 2: Run the test and capture results**

```bash
flutter test integration_test/permission_leaks_test.dart -r expanded
```

Record EACH of the 7 test outcomes. Pay close attention to which paths 404 vs 403 vs 200. Both 404 and 403 are acceptable (server denies access); a 200 with another role's data is a CRITICAL leak.

- [ ] **Step 3: Commit**

```bash
git add integration_test/permission_leaks_test.dart
git commit -m "$(cat <<'EOF'
feat(mobile/audit): add permission_leaks_test.dart (cross-role)

Seven scenarios covering: siswa & wali shell routing, siswa grade scope,
wali 1A vs wali 2A cross-scope (chained logins to discover foreign IDs),
siswa write-path rejection, wali rejected at admin namespace.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Migrate `student_flow_test.dart`

**Files:**
- Modify: `integration_test/student_flow_test.dart`

Existing test references stale `student@floz.test`. Migrate to seeded `24001@siswa.sekolah.id` / `password`, and add the one negative assertion from spec §6.4.

- [ ] **Step 1: Rewrite the file**

Replace `floz_mobile/integration_test/student_flow_test.dart` with this exact content:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'audit_helpers.dart';
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Student E2E Flow', () {
    setUpAll(() async {
      final ok = await backendReachable();
      if (!ok) {
        markTestSkipped('backend not reachable at /healthz');
      }
    });

    tearDown(() async {
      await clearAuthToken();
    });

    testWidgets('login → navigate all tabs → profile → logout',
        (tester) async {
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.siswa);

      expect(
        find.descendant(
            of: find.byType(NavigationBar), matching: find.text('Beranda')),
        findsOneWidget,
      );

      await tapNavTab(tester, 'Jadwal');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tapNavTab(tester, 'Nilai');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Negative assertion: siswa is read-only on grades.
      // Common write affordances should NOT be present.
      expect(find.byIcon(Icons.add), findsNothing,
          reason: 'siswa should not see add-grade FAB on Nilai tab');
      expect(find.text('Simpan'), findsNothing,
          reason: 'siswa should not see Simpan button on Nilai tab');

      await tapNavTab(tester, 'Rapor');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tapNavTab(tester, 'Info');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tapNavTab(tester, 'Tugas');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tapNavTab(tester, 'Beranda');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final profileButtons = find.byIcon(Icons.person_outlined);
      if (profileButtons.evaluate().isNotEmpty) {
        await tester.tap(profileButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final logoutBtn = find.text('Keluar');
        if (logoutBtn.evaluate().isNotEmpty) {
          await tester.tap(logoutBtn);
          await tester.pumpAndSettle(const Duration(seconds: 3));

          final confirmBtn = find.text('Ya, Keluar');
          if (confirmBtn.evaluate().isNotEmpty) {
            await tester.tap(confirmBtn);
            await tester.pumpAndSettle(const Duration(seconds: 3));
          }

          expectShellFor(tester, 'login');
        }
      }
    });
  });
}
```

- [ ] **Step 2: Run the test**

```bash
flutter test integration_test/student_flow_test.dart -r expanded
```

Record outcome (pass/fail/skip + reason).

- [ ] **Step 3: Commit**

```bash
git add integration_test/student_flow_test.dart
git commit -m "$(cat <<'EOF'
fix(mobile/audit): migrate student_flow_test to seeded siswa credentials

Replaces stale student@floz.test/password123 with the seeded
24001@siswa.sekolah.id / password (note: 'password', not 'password123').
Adds a read-only assertion on the Nilai tab so any future leak of a
write affordance fails the test.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Migrate `teacher_flow_test.dart`

**Files:**
- Modify: `integration_test/teacher_flow_test.dart`

- [ ] **Step 1: Rewrite the file**

Replace `floz_mobile/integration_test/teacher_flow_test.dart` with this exact content:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'audit_helpers.dart';
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Teacher E2E Flow', () {
    setUpAll(() async {
      final ok = await backendReachable();
      if (!ok) {
        markTestSkipped('backend not reachable at /healthz');
      }
    });

    tearDown(() async {
      await clearAuthToken();
    });

    testWidgets('login → navigate Kelas/Nilai/Rekap tabs → profile',
        (tester) async {
      await initApp(tester);
      await loginAsRole(tester, AuditCredentials.wali1A);

      expect(
        find.descendant(
            of: find.byType(NavigationBar), matching: find.text('Kelas')),
        findsOneWidget,
      );

      await tapNavTab(tester, 'Nilai');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tapNavTab(tester, 'Rekap');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tapNavTab(tester, 'Kelas');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final profileButtons = find.byIcon(Icons.person_outlined);
      if (profileButtons.evaluate().isNotEmpty) {
        await tester.tap(profileButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(find.text('Keluar'), findsOneWidget);
      }
    });
  });
}
```

- [ ] **Step 2: Run the test**

```bash
flutter test integration_test/teacher_flow_test.dart -r expanded
```

Record outcome.

- [ ] **Step 3: Commit**

```bash
git add integration_test/teacher_flow_test.dart
git commit -m "$(cat <<'EOF'
fix(mobile/audit): migrate teacher_flow_test to seeded wali kelas creds

Replaces stale teacher@floz.test/password123 with mariam.s (wali kelas 1A).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Add `AUDIT_README.md`

**Files:**
- Create: `integration_test/AUDIT_README.md`

- [ ] **Step 1: Create the file**

Create `floz_mobile/integration_test/AUDIT_README.md` with this exact content:

````markdown
# Mobile Permission Audit — How to Run

Audit suite for the FLOZ mobile app's role-based permissions. Source of
truth: `docs/superpowers/specs/2026-05-13-mobile-permission-audit-design.md`.

## Prerequisites

1. Laravel backend running on `localhost:8000` with the school DB seeded.
   From repo root:
   ```bash
   cd src && php artisan serve
   ```
2. The four seeded accounts exist:

   | Role          | Email                             | Password    |
   |---------------|-----------------------------------|-------------|
   | Admin         | admin@floz.test                   | password123 |
   | Wali Kelas 1A | mariam.s@sdkelapadua4.sch.id      | password123 |
   | Wali Kelas 2A | hendra.w@sdkelapadua4.sch.id      | password123 |
   | Siswa         | 24001@siswa.sekolah.id            | password    |

3. A real device or simulator attached (`flutter devices`).

## Running

From `floz_mobile/`:

```bash
# All audit files at once
flutter test integration_test/

# A single role
flutter test integration_test/walikelas_flow_test.dart
flutter test integration_test/admin_flow_test.dart
flutter test integration_test/permission_leaks_test.dart

# Custom API base or credentials (e.g. against staging)
flutter test integration_test/permission_leaks_test.dart \
  --dart-define=AUDIT_API_BASE=http://10.0.2.2:8000/api/v1 \
  --dart-define=AUDIT_SISWA_EMAIL=other@siswa.sekolah.id \
  --dart-define=AUDIT_SISWA_PASSWORD=password
```

## Available `--dart-define` keys

| Key                          | Default                          |
|------------------------------|----------------------------------|
| `AUDIT_API_BASE`             | `http://localhost:8000/api/v1`   |
| `AUDIT_SISWA_EMAIL`          | `24001@siswa.sekolah.id`         |
| `AUDIT_SISWA_PASSWORD`       | `password`                       |
| `AUDIT_WALI_1A_EMAIL`        | `mariam.s@sdkelapadua4.sch.id`   |
| `AUDIT_WALI_1A_PASSWORD`     | `password123`                    |
| `AUDIT_WALI_2A_EMAIL`        | `hendra.w@sdkelapadua4.sch.id`   |
| `AUDIT_WALI_2A_PASSWORD`     | `password123`                    |
| `AUDIT_ADMIN_EMAIL`          | `admin@floz.test`                |
| `AUDIT_ADMIN_PASSWORD`       | `password123`                    |

## Interpreting results

- **PASS** — the asserted behaviour holds. No finding.
- **FAIL** — record as a finding in `MOBILE_AUDIT_HANDOFF.md` at repo root.
  Do NOT modify app source to make a failure pass — the failure IS the
  finding. Severity rubric is documented in the spec §7.
- **SKIP** — usually means the backend was unreachable, or a dependent
  resource (e.g. Hendra's class id) wasn't available. Fix the precondition
  and re-run. A persistent skip is itself worth documenting.

## Files

- `audit_helpers.dart` — credentials, login, shell assertion, raw API probe
- `helpers.dart` — pre-audit smoke helpers (initApp, login, tapNavTab)
- `auth_edge_cases_test.dart` — validation behaviour at the login screen
- `student_flow_test.dart`, `teacher_flow_test.dart` — single-role smoke
- `walikelas_flow_test.dart` — wali kelas 1A smoke
- `admin_flow_test.dart` — admin no-leak assertions
- `permission_leaks_test.dart` — cross-role scope assertions
````

- [ ] **Step 2: Commit**

```bash
git add integration_test/AUDIT_README.md
git commit -m "$(cat <<'EOF'
docs(mobile/audit): add AUDIT_README.md run instructions

Step-by-step how to run the audit suite, full --dart-define matrix,
and how to interpret pass/fail/skip results.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Synthesize `MOBILE_AUDIT_HANDOFF.md` at repo root

**Files:**
- Create: `MOBILE_AUDIT_HANDOFF.md` (note: at REPO ROOT, not under `floz_mobile/`)

This is the **only** task whose content depends on the test outcomes captured during Tasks 3–7. Open your audit notes from those tasks; one finding per failure/unexpected behaviour.

- [ ] **Step 1: Tally test outcomes**

From your audit notes across Tasks 3–7, count:
- Tests passed
- Tests failed (each one becomes a finding)
- Tests skipped (each persistent skip becomes a LOW or MEDIUM finding)

Total test count: walikelas (6) + admin (3) + permission_leaks (7) + student (1) + teacher (1) = **18 tests**.

- [ ] **Step 2: Write the findings doc**

Create `MOBILE_AUDIT_HANDOFF.md` at the repo root (NOT inside `floz_mobile/`). Use this exact skeleton; fill in the actual findings inline:

```markdown
# Mobile Audit Handoff — 2026-05-13

**Branch:**      chore/remove-tenant-leftovers
**Backend:**     http://localhost:8000 (seeded school DB)
**Suite:**       floz_mobile/integration_test/ (18 tests)
**Spec:**        docs/superpowers/specs/2026-05-13-mobile-permission-audit-design.md

## Summary

- Passed:  <FILL FROM NOTES>
- Failed:  <FILL FROM NOTES>
- Skipped: <FILL FROM NOTES>

Severity counts:
- CRITICAL: <N>
- HIGH:     <N>
- MEDIUM:   <N>
- LOW:      <N>

## Severity rubric

- **CRITICAL** — cross-role scope leak, write access outside permissions,
  hardcoded auth bypass, or a legitimate user fully blocked.
- **HIGH** — broken role gating that allows read-only access to wrong-role
  data, or breaks one major flow while leaving the app partially usable.
- **MEDIUM** — feature gap vs web (e.g. semester filter missing), or
  parity issue. App still works.
- **LOW** — UX, dead code, stale fixtures, hardcoded values that should
  be env-overridable.

## Findings

### [<SEVERITY>] M-001 — <One-line title>
- **File**:        <path/to/source.dart:LINE> (or N/A for backend issues)
- **Test**:        integration_test/<file>.dart::<test name>
- **Observed**:    <one sentence — actual outcome>
- **Expected**:    <one sentence — what should have happened>
- **Root cause**:  <one or two sentences — best current hypothesis>
- **Suggested**:   <one-line direction for the fix session>
- **Status**:      OPEN

### [<SEVERITY>] M-002 — ...
<repeat per finding>

## Follow-up scope

Items to fix in a separate remediation session (do NOT bundle with the
audit commits):
- <list each finding by ID with a one-line rationale of urgency>

## Reproduction

```bash
cd src && php artisan serve              # backend
cd floz_mobile && flutter test integration_test/
```

See `floz_mobile/integration_test/AUDIT_README.md` for env-var overrides.
```

**Important constraints when filling in findings:**

- Every finding MUST cite a specific test file:line that produced the evidence. No findings without a test.
- A test that passed is NOT a finding.
- A skipped test is a LOW finding ("audit blind spot: <reason>") only if the skip is structural (e.g. backend missing an endpoint). Skips for transient reasons (backend down) are not findings.
- Suggested fix is a direction (one line), not a patch.
- Do NOT write code in this document. It's a hand-off doc.

If after Tasks 3–7 you have ZERO failures and ZERO structural skips, the doc still gets written — it just says "0 findings, audit baseline established." That's still a useful artifact.

- [ ] **Step 3: Commit at repo root**

```bash
# From repo root, not floz_mobile/
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add MOBILE_AUDIT_HANDOFF.md
git commit -m "$(cat <<'EOF'
docs(audit): MOBILE_AUDIT_HANDOFF.md — synthesized from audit suite output

Findings derived from floz_mobile/integration_test/ runs across siswa,
wali kelas 1A, wali kelas 2A, and admin roles. Each finding cites the
test file:line that produced its evidence. No source fixes in this
audit — remediation in a follow-up session.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 4: Final verification — full suite run**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter test integration_test/
```

Expected: the outcomes match what's in the findings doc. If a test that the doc says "FAIL" now passes (or vice versa), update the doc and re-commit.

- [ ] **Step 5: Confirm milestone**

```bash
git log --oneline -10
```

Expected: the last 9 commits should be the audit work (tasks 1–9 produced 9 commits).

---

## Deviations from spec §5

`tryDeepLink(tester, path)` listed in the spec's helper API is **omitted** by design. GoRouter deep-link simulation in integration_test requires reaching into the Riverpod container to grab the GoRouter instance, which leaks test plumbing into app code. Instead, the equivalent guard behaviour is exercised at login time: after `loginAsRole`, `expectShellFor` asserts the correct shell is mounted — same code path (the `redirect` in `appRouterProvider`), simpler test surface. A follow-up audit can add `tryDeepLink` if a leak surfaces that only manual navigation can trigger.

## Done criteria

- [ ] 18 integration tests run; outcomes documented.
- [ ] `MOBILE_AUDIT_HANDOFF.md` exists at repo root with at least one finding per failed/structurally-skipped test, severity-rated.
- [ ] `integration_test/AUDIT_README.md` exists with reproduction steps.
- [ ] `audit_helpers.dart` exposes: `AuditCredentials`, `loginAsRole`, `expectShellFor`, `apiProbe`, `backendReachable`, `clearAuthToken`. (`tryDeepLink` omitted — see "Deviations from spec §5" above.)
- [ ] Stable widget keys added on `StudentShell` and `TeacherShell`.
- [ ] 9 commits, linear, each independently revertable.
- [ ] **No app source files changed** beyond the two `Key()` additions in Task 1.

If you find yourself wanting to "fix" something in `lib/` to make a test pass — STOP. That is a remediation session, not this audit. Add the finding to the handoff doc instead.
