# Phase 5 — REST API + Flutter Mobile Integration Design

**Project:** FLOZ LMS — SDN Kelapa Dua IV
**Date:** 2026-04-15
**Status:** Approved (brainstorming output)
**Next step:** Implementation plan via `superpowers:writing-plans`

---

## 1. Goal & Scope

Selesaikan Phase 5: REST API & integrasi Flutter mobile, dengan target **production deployment** di SDN Kelapa Dua IV.

### In scope
- **A — Polish student read-only flow.** 7 endpoint student existing (auth, dashboard, schedule, grades, report-cards, announcements, assignments) di-refactor ke kontrak terstandar dan UI mobile-nya di-polish ke level production.
- **C — Teacher mode.** Empat fitur teacher baru di mobile + endpoint backend pendukung:
  1. Lihat daftar kelas/mapel yang diampu (teaching assignments)
  2. Input absensi harian (per Pertemuan)
  3. Input nilai batch (Harian/UTS/UAS)
  4. Lihat rekap absen & nilai per kelas

### Out of scope (di-defer ke phase berikutnya)
- B — Submission tugas oleh siswa (siswa tidak upload tugas dari mobile)
- D — Push notification (FCM) & WebSocket Reverb di mobile
- E — Parent flow (akun parent ditolak login di mobile saat ini)
- Editing materi/tugas oleh teacher (Pertemuan: title/desc/status hanya read di Phase 5)
- Integration test (Flutter `integration_test`) & golden test
- Offline-first mutation queue (lihat keputusan offline di §3)

---

## 2. Approach

**Contract-First → Vertical Slices.**

Investasi 1 minggu di Step 0 untuk mengunci fondasi (API contract, base classes, error handler, Policies, mobile core infra), lalu eksekusi 11 vertical slice fitur. Tiap slice = backend + Resource + Policy + Pest test + Dart datasource + repo + provider + UI screen + widget test, di-merge sebagai satu PR ship-ready.

Alternatif yang ditolak:
- Bottom-up by layer (mobile jadi PR raksasa, bug shape mismatch baru ketahuan di akhir)
- Pure vertical slice tanpa contract-first (risiko inkonsistensi tinggi, slice ke-3 mungkin force refactor slice ke-1)

---

## 3. Key Decisions

| Topik | Keputusan |
|---|---|
| Deployment target | Production di SDN Kelapa Dua IV |
| Offline support | **Read-cache + online-write** (opsi 2). Data list di-cache lokal via Hive; mutasi (input absen/nilai) selalu butuh online. Tidak ada queue offline di Phase 5. |
| API contract | Standardisasi total. Refactor existing endpoint OK (mobile belum ship). Breaking change diperbolehkan. |
| Attendance flow | Per-Pertemuan (konsisten dengan web). Mobile bisa kasih shortcut "lompat ke Pertemuan terdekat hari ini" sebagai UX bonus, tapi data model tetap meeting-driven. |
| Versioning | `/api/v1/...`. Migrasi controller namespace `Api\` → `Api\V1\`. |
| Auth | Sanctum bearer token, single-device per user (revoke token lama saat login). Login endpoint dipakai bersama untuk student + teacher; response payload role-aware. |
| Role yang didukung | `student`, `teacher`. `admin` boleh login tapi shell admin tidak dibangun di Phase 5 (out of scope). `parent` ditolak login dengan error eksplisit. |
| Service layer | Wajib untuk semua mutasi. Controller thin, transaksi DB di Service. |
| Authz package | Tidak pakai Spatie permission (tidak terinstall). Pakai enum `App\Enums\UserRole` + custom `EnsureRole` middleware + Laravel Policy. |
| Result type (Flutter) | Custom sealed class `Result<T>`, tanpa fpdart. |
| Cache backend (Flutter) | Hive (sudah di pubspec). |
| Mobile struktur | Migrasi `features/<feat>` → `features/student/<feat>`; bikin `features/teacher/<feat>` baru. |
| Test DB | Postgres (real, sama dengan prod). Bukan SQLite in-memory. |
| Mocking lib | mocktail (lighter than mockito, no codegen). |
| Deadline | Tidak ada deadline keras. Full TDD, code review, Swagger lengkap. |

---

## 4. API Contract (Single Source of Truth)

### 4.1 Envelope

**Single resource:**
```json
{ "data": { ... } }
```

**Collection:**
```json
{
  "data": [ ... ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 145,
    "last_page": 8
  }
}
```

**Error:**
```json
{
  "message": "Pesan singkat untuk user.",
  "errors": {
    "field_name": ["Pesan validasi 1", "Pesan validasi 2"]
  },
  "code": "VALIDATION_ERROR"
}
```

### 4.2 HTTP Status Mapping

| Code | Use |
|---|---|
| 200 | OK |
| 201 | Created |
| 204 | No Content |
| 400 | Bad Request (malformed) |
| 401 | Unauthenticated (token invalid/missing) |
| 403 | Forbidden (authz fail) |
| 404 | Not Found |
| 422 | Validation Error |
| 429 | Rate Limit |
| 500 | Server Error (generic message; full trace di log) |

### 4.3 Field Conventions

- `id` selalu integer
- Tanggal/waktu **selalu ISO 8601 UTC** (`2026-04-15T08:00:00Z`); konversi ke Asia/Jakarta dilakukan di mobile
- Snake_case untuk semua key
- URL absolut untuk file/avatar (`avatar_url`, `pdf_url`)
- Pagination: query `?page=1&per_page=20`; default `per_page=20`, max `100`
- Filtering: query string (`?class_id=4&date=2026-04-15`)

### 4.4 Headers

**Request:**
- `Authorization: Bearer <sanctum-token>`
- `Accept: application/json`
- `X-Client: floz-mobile/1.0.0`

**Response:**
- `Content-Type: application/json`

### 4.5 Rate Limiting

- Login endpoint: `5 per minute per IP`
- Endpoint authenticated: `60 per minute per user`

### 4.6 Versioning

- Path-based `/api/v1/...`. Breaking change masa depan → `/api/v2/...` paralel, jangan mutasi v1.

---

## 5. Backend Architecture

### 5.1 Layering per slice

```
Routes (api.php)
  └─> Controller (thin — only HTTP concern)
        ├─> FormRequest (validation + authorize())
        ├─> Service (business logic, transactions)
        ├─> Policy (authz: can teacher access this class?)
        └─> Resource (response shape)
```

### 5.2 Naming convention

- Controller: `App\Http\Controllers\Api\V1\Mobile{Feature}Controller`
- FormRequest: `App\Http\Requests\Api\V1\{Feature}\{Action}Request`
- Resource: `App\Http\Resources\Api\V1\{Feature}Resource` & `{Feature}Collection`
- Service: `App\Services\Mobile\{Feature}Service`
- Policy: `App\Policies\{Model}Policy`

### 5.3 Folder structure (extension)

```
src/app/
├── Http/
│   ├── Controllers/Api/V1/
│   ├── Requests/Api/V1/{Feature}/
│   ├── Resources/Api/V1/
│   └── Middleware/
│       ├── ApiExceptionHandler.php
│       ├── ForceJsonResponse.php
│       ├── EnsureRole.php
│       └── ApiVersionHeader.php
├── Services/
│   └── Mobile/
│       ├── DashboardService.php
│       ├── ScheduleService.php
│       ├── GradeService.php
│       ├── ReportCardService.php
│       ├── AnnouncementService.php
│       ├── AssignmentService.php
│       ├── TeacherClassService.php
│       ├── AttendanceService.php
│       ├── GradingService.php
│       └── RecapService.php
└── Policies/   (existing + new yang ditambah, lihat §7)
```

### 5.4 Exception Handling

Centralized di `bootstrap/app.php` (Laravel 12 style). Mapping:

| Exception | HTTP | Catatan |
|---|---|---|
| `AuthenticationException` | 401 | |
| `AuthorizationException` | 403 | |
| `ValidationException` | 422 | Laravel default sudah pas, dibungkus envelope |
| `ModelNotFoundException` | 404 | |
| `Throwable` | 500 | Log full trace; return generic `{message: "Server error"}` |

Semua dibungkus envelope error standar (§4.1).

### 5.5 Migrasi controller existing

Existing `App\Http\Controllers\Api\Mobile*Controller` → `App\Http\Controllers\Api\V1\Mobile*Controller`. Yang lama dihapus (no deprecation shim) karena mobile app belum di-ship.

---

## 6. Mobile Architecture

### 6.1 Folder structure (extension)

```
floz_mobile/lib/
├── core/
│   ├── network/
│   │   ├── api_client.dart           # Dio + interceptors
│   │   ├── api_response.dart         # envelope <T>: data + meta
│   │   ├── api_exception.dart        # typed
│   │   └── api_endpoints.dart
│   ├── error/
│   │   ├── failure.dart              # sealed: Network/Auth/Server/Cache/Validation
│   │   └── result.dart               # sealed Result<T>
│   ├── storage/
│   │   ├── secure_token_storage.dart # flutter_secure_storage
│   │   └── cache_box.dart            # Hive boxes per feature
│   ├── auth/
│   │   ├── auth_session.dart
│   │   └── role_guard.dart           # go_router redirect
│   ├── router/
│   │   └── app_router.dart           # split shells by role
│   └── theme/
├── features/
│   ├── auth/                         # cross-role; refine
│   ├── student/                      # NEW namespace
│   │   ├── dashboard/
│   │   ├── schedule/
│   │   ├── grades/
│   │   ├── report_cards/
│   │   ├── announcements/
│   │   └── assignments/
│   └── teacher/                      # NEW
│       ├── classes/
│       ├── attendance/
│       ├── grades_input/
│       └── recaps/
└── shared/
    ├── widgets/
    │   ├── empty_state.dart
    │   ├── error_state.dart
    │   ├── loading_skeleton.dart
    │   └── async_value_widget.dart
    └── extensions/
```

### 6.2 Per-feature internal layering

```
features/<role>/<name>/
├── data/
│   ├── datasources/<feature>_remote_datasource.dart
│   ├── datasources/<feature>_local_datasource.dart
│   ├── models/<feature>_dto.dart
│   └── repositories/<feature>_repository_impl.dart
├── domain/
│   ├── entities/<feature>.dart
│   └── repositories/<feature>_repository.dart
├── presentation/
│   ├── screens/<feature>_screen.dart
│   └── widgets/
└── providers/
    └── <feature>_providers.dart      # Riverpod
```

### 6.3 Shared infrastructure

**ApiClient (Dio) interceptors:**
1. Inject `Authorization: Bearer <token>` from `SecureTokenStorage`
2. Log request/response (debug-only)
3. Catch `DioException` → throw typed `ApiException`
4. On 401 → trigger logout + redirect to login

**Result<T>** (lightweight sealed class, no fpdart):
```dart
sealed class Result<T> { const Result(); }
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}
final class FailureResult<T> extends Result<T> {
  final Failure failure;
  const FailureResult(this.failure);
}
```

Repositories return `Future<Result<T>>` — exceptions tidak pernah leak ke presentation layer.

**Role-aware router:**
- Dua shell route: `/student/...` dan `/teacher/...`
- Setelah login, `auth_session.role` menentukan redirect
- Parent role → ditolak di `auth/login` response (login endpoint return 403 dengan pesan "Akun parent belum didukung di mobile")

### 6.4 Cache strategy (read-cache + online-write)

Setiap feature punya Hive box `{feature}_cache`. Repository pattern:

1. **Read flow:**
   - Try fetch from API → simpan ke cache → `return Success(data)`
   - Network gagal → fallback ke cache → `return Success(data, stale=true)` atau `FailureResult(NetworkFailure)` kalau cache kosong
   - UI tampilkan banner "Data offline" saat stale

2. **Write flow:** Always-online. Network gagal → `FailureResult(NetworkFailure)`. **Tidak** ada queue. UI snackbar error + retry button; form data tetap di state.

3. **Cache TTL** per feature:
   - dashboard: 5 menit
   - schedules: 1 hari
   - grades: 1 jam
   - report-cards: 1 hari
   - announcements: 30 menit
   - assignments: 30 menit
   - teacher classes/recaps: 1 jam
   - attendance roster (sebelum input): tidak di-cache (selalu fresh)

4. **Cache invalidation:** Setelah mutasi sukses (input absen/nilai), repo invalidate cache feature terkait + recap.

### 6.5 Dependencies baru (pubspec)

- `mocktail` di `dev_dependencies` (untuk test)

---

## 7. Authorization Model

### 7.1 Defense in depth — 5 layers

```
1. Route middleware     → "is authenticated at all?" (auth:sanctum)
2. Role middleware      → "is this user a student/teacher?" (role:teacher)
3. FormRequest          → "does this user pass authorize() for this action?"
4. Policy (in service)  → "does this user own this specific resource?"
5. Query scoping        → "filter to only what they can see"
```

Tidak boleh skip layer 4 & 5. Middleware `role:teacher` cuma bilang "this guy is a teacher", bukan "this teacher owns kelas 4A".

### 7.2 Custom middleware `EnsureRole`

- Alias: `role:student`, `role:teacher`, `role:teacher,admin`
- Cek `$user->role->value` against allowed list, reject 403 dengan envelope error standar

### 7.3 Policies — gap closure (Step 0)

| Policy | Method | Status | Aturan |
|---|---|---|---|
| `MeetingPolicy::view` | exists | OK |
| `MeetingPolicy::recordAttendance` | NEW | teacher: own TA; admin: yes |
| `MeetingPolicy::recordGrade` | NEW | sama dengan recordAttendance |
| `GradePolicy::view` | FIX | student: `grade->student_id === user->student->id` (bukan email matching) |
| `GradePolicy::viewAny` | FIX | scope ke teaching assignments milik teacher |
| `GradePolicy::update` | FIX | filter: subject + class harus ada di TA teacher |
| `AttendancePolicy::viewAny` | NEW | teacher view rekap own classes; student own records |
| `AttendancePolicy::view` | NEW | per-record check |
| `AttendancePolicy::create` | NEW | teacher: own meeting; admin: yes |
| `AnnouncementPolicy::view` | NEW | semua role auth bisa baca (sekolah-wide); kalau ada `class_scope` → cek kelas siswa |
| `ReportCardPolicy::view` | NEW | student: own; teacher: wali kelas of student's class |
| `ReportCardPolicy::download` | NEW | sama dengan view |
| `OfflineAssignmentPolicy` | exists | Audit & verify methods `view`/`viewAny` cover student (read tugas dari kelas-nya) + teacher (tugas di TA-nya). Patch kalau gap. Mobile pakai model `OfflineAssignment`, bukan `Task`. |

### 7.4 Query scoping discipline

Wajib di Service layer. Aturan keras:

- Jangan pernah `Student::all()` atau `Grade::all()` di service mobile API
- Selalu scope dari relasi yang sudah implicitly authz oleh ownership: `$teacher->teachingAssignments->meetings`, `$student->grades`, dst.
- Service double-check ownership di awal method meskipun Policy sudah lewat (defense in depth)

### 7.5 Authz test plan

Untuk tiap endpoint mutation/sensitive, Pest test wajib:
- ✅ Happy: actor yang berhak → 200/201
- ❌ Wrong role: student → endpoint teacher → 403
- ❌ Right role wrong owner: teacher A submit absen di kelas teacher B → 403
- ❌ Unauthenticated: tanpa Bearer → 401
- ❌ Expired/revoked token → 401

---

## 8. Data Flow — Reference Slice (Teacher Input Absen)

Contoh end-to-end slice paling kompleks (mutation + validation + authz + cache invalidation).

### 8.1 Load roster

```
[UI] AttendanceInputScreen
  load: teachingAssignmentId=12, meetingId=42
  ↓
[Provider] AttendanceProvider.build()
  → repo.getRoster(meetingId)
  ↓
[Repo] AttendanceRepositoryImpl.getRoster
  - remote.fetchRoster(meetingId)         (no cache for roster — selalu fresh)
  - return Result<Roster>
  ↓
[DataSource] AttendanceRemoteDataSource
  apiClient.get('/v1/teacher/meetings/42/attendance')
  ↓
══════════════ HTTP ══════════════
  ↓
[Backend] Routes/api.php
  Route::get('/teacher/meetings/{meeting}/attendance', ...)
    ->middleware(['auth:sanctum', 'role:teacher,admin'])
  ↓
[Controller] MobileTeacherAttendanceController@show
  $this->authorize('recordAttendance', $meeting);   // MeetingPolicy
  $roster = $this->service->getRoster($meeting, $request->user());
  return new AttendanceRosterResource($roster);
  ↓
[Service] AttendanceService::getRoster($meeting, $user)
  // Double-check ownership
  if ($user->isTeacher() && $meeting->teachingAssignment->teacher_id !== $user->teacher->id) {
      throw new AuthorizationException();
  }
  return $meeting->teachingAssignment->schoolClass->students()
    ->with(['attendances' => fn($q) => $q->where('meeting_id', $meeting->id)])
    ->orderBy('name')->get();
```

**Response:**
```json
{
  "data": {
    "meeting": {
      "id": 42, "session_number": 5, "title": "...", "date": "2026-04-15T00:00:00Z"
    },
    "class": { "id": 4, "name": "4A" },
    "teaching_assignment": { "id": 12, "subject": { "id": 7, "name": "Matematika" } },
    "students": [
      { "id": 1, "name": "Ahmad", "status": null,    "note": null },
      { "id": 2, "name": "Budi",  "status": "hadir", "note": null }
    ]
  }
}
```

### 8.2 Submit attendance

```
[UI] tap submit
  ↓
[Controller (mobile)] AttendanceController.submit({status_per_student})
  → provider.submit(...)
  ↓
[Repo] AttendanceRepositoryImpl.submit
  → remote.submit(POST /v1/teacher/meetings/42/attendance, payload)
  ↓
══════════════ HTTP ══════════════
  ↓
[Backend] POST /v1/teacher/meetings/{meeting}/attendance
  → StoreAttendanceRequest::rules()
      'entries' => 'required|array|min:1',
      'entries.*.student_id' => 'required|integer|exists:students,id',
      'entries.*.status' => 'required|in:hadir,sakit,izin,alpha',
      'entries.*.note' => 'nullable|string|max:255',
  → Policy: $user->can('recordAttendance', $meeting)
  → AttendanceService::store($meeting, $validated, $user)
      DB::transaction(function() use (...) {
          foreach ($entries as $e) {
              Attendance::updateOrCreate(
                  [
                      'class_id'   => $meeting->teachingAssignment->class_id,
                      'student_id' => $e['student_id'],
                      'meeting_id' => $meeting->id,
                      'date'       => $meeting->date,
                  ],
                  [
                      'status'      => $e['status'],
                      'note'        => $e['note'] ?? null,
                      'recorded_by' => $user->id,
                  ]
              );
          }
      });
  → return AttendanceRosterResource (refreshed state)
  ↓
[Mobile]
  - repo.invalidateCache(meetingId, recap)
  - provider.refresh()
  - UI snackbar success
```

### 8.3 Failure modes

| Stage | Failure | Handling |
|---|---|---|
| Load roster | Network gagal | (Roster tidak di-cache) → tampil error state dengan retry button |
| Load roster | 403 | Snackbar "Anda tidak punya akses" + back to list |
| Submit | Network gagal | Snackbar error + retry button; form data tetap di state |
| Submit | 422 validation | Render error per field di UI |
| Submit | 403 | Snackbar "Anda tidak punya akses ke pertemuan ini" + back to list |
| Submit | 401 | Token expired → auto logout + redirect login |
| Submit | 500 | Snackbar generik "Server error, coba lagi" |

### 8.4 Pola yang sama berlaku untuk

- **Grade input batch** (Slice 10) — beda di service: `GradingService::storeBatch(TeachingAssignment $ta, array $entries, string $type, User $user)` dengan validasi tipe nilai (`harian|uts|uas`) dan score 0-100.
- **Read-only student endpoints** — lebih sederhana, hanya jalur "load → cache → render" tanpa mutation.

---

## 9. Testing Strategy

### 9.1 Backend (Pest)

**Rasio:** 70% feature test, 20% unit test (services), 10% policy test.

**Per slice wajib:**
1. Authentication test — token issued/revoked, expired token rejected
2. Authorization test — happy + 3 negatives (wrong role, wrong owner, unauthenticated)
3. Validation test — required fields, type coercion, custom rules
4. Business logic test — calculation correctness (grading formula), data constraints (unique attendance), side effects
5. Response shape test — envelope structure, datetime ISO 8601, pagination meta

**Tools:**
- Pest 3 (sudah default di Laravel 12)
- `actingAs($user, 'sanctum')`
- **Postgres test DB** (real, isolated dari dev). Bukan SQLite in-memory.
- Factories: pastikan ada untuk Student, Teacher, Meeting, TeachingAssignment, Grade, Attendance, ReportCard, Announcement, Task. Audit + buat yang missing di Step 0.

**Coverage target:**
- Service classes: 90%+
- Controllers: 80%+
- Policies: 100%

**TDD discipline:** Tulis test dulu (red), implement (green), refactor. Setiap PR slice tidak di-merge kalau test belum hijau.

### 9.2 Mobile (Flutter test)

**Layer testing:**
- Unit test — Repository (mock datasource), entity mappers (DTO ↔ Entity)
- Widget test — Screen rendering per state (loading/success/error/empty), form validation, button enable/disable
- Provider test — `ProviderContainer` test, override datasource dengan mock, assert state transitions

**Tools:**
- `flutter_test` (built-in)
- `mocktail` (perlu ditambah ke `dev_dependencies`)

**Coverage target:**
- Repositories: 90%+
- Providers: 80%+
- Widgets: smoke test happy + error per screen

### 9.3 Manual QA per slice merge

Sebelum merge tiap slice ke main:
1. `php artisan test --filter=<SliceName>` → green
2. `flutter test` → green
3. Build & run di Android emulator + iOS simulator (jika tersedia)
4. Smoke flow login → fitur terkait → logout
5. Force airplane-mode → verify cache fallback bekerja
6. `php artisan l5-swagger:generate` → buka `/api/documentation`, verify endpoint baru muncul

---

## 10. Slice Catalog & Ordering

### Step 0 — Foundation (~5–7 hari)

- Tulis & commit `docs/api/CONTRACT.md` (envelope, error format, conventions)
- Backend:
  - Pindah `App\Http\Controllers\Api\` → `App\Http\Controllers\Api\V1\`
  - Bikin `BaseResource`, exception handler centralized di `bootstrap/app.php`
  - Bikin `EnsureRole` middleware
  - Audit + perbaiki `GradePolicy`
  - Bikin policy gap: `AttendancePolicy`, `AnnouncementPolicy`, `ReportCardPolicy`, `TaskPolicy`
  - Audit Pest factories yang missing, buat yang perlu
- Mobile:
  - Bikin `core/network/`, `core/error/`, `core/auth/`, `core/storage/`
  - Refactor `auth/login`, `auth/logout`, `auth/me` jadi reference impl pattern
  - Auth login: tolak role `parent` dengan 403 + pesan "Akun parent belum didukung di mobile saat ini" (backend + handle di mobile login screen)
  - Migrasi folder `features/{dashboard,schedule,grades,report_cards,announcements,assignments}` → `features/student/{...}`
  - Tambah `mocktail` di `pubspec.yaml`
- Generate Swagger annotation pattern di reference impl

**Definition of Done Step 0:**
- `auth/login`, `auth/logout`, `auth/me` end-to-end pakai contract baru
- Semua test hijau (backend + mobile)
- Swagger render endpoint baru
- Mobile build green di Android + iOS

### Slices Student (refactor existing → contract baru)

| # | Slice | Backend Endpoints | Mobile |
|---|---|---|---|
| 1 | **Dashboard student** | `GET /v1/student/dashboard` | refresh dashboard screen |
| 2 | **Schedule** | `GET /v1/student/schedules`, `/today` | refresh schedule screen |
| 3 | **Grades student** | `GET /v1/student/grades`, `/{subjectId}` | refresh grades screen (split controller dari teacher branch) |
| 4 | **Report Cards** | `GET /v1/student/report-cards`, `/{id}`, `/{id}/pdf` | refresh + PDF viewer |
| 5 | **Announcements** | `GET /v1/student/announcements`, `/{id}` | refresh + detail screen |
| 6 | **Assignments student (read-only)** | `GET /v1/student/assignments`, `/{id}` | refresh list + detail screen |

### Slices Teacher (new)

| # | Slice | Backend Endpoints | Mobile |
|---|---|---|---|
| 7 | **Teacher classes list** | `GET /v1/teacher/teaching-assignments` | new `ClassesListScreen` |
| 8 | **Teacher class detail + meetings** | `GET /v1/teacher/teaching-assignments/{id}/meetings` | new `ClassDetailScreen` |
| 9 | **Attendance input** | `GET /v1/teacher/meetings/{id}/attendance`, `POST` same path | new `AttendanceInputScreen` |
| 10 | **Grade input batch** | `GET /v1/teacher/teaching-assignments/{id}/grade-roster?type=harian\|uts\|uas`, `POST /v1/teacher/teaching-assignments/{id}/grades` | new `GradeInputScreen` (grid table) |
| 11 | **Recap (absen + nilai)** | `GET /v1/teacher/teaching-assignments/{id}/attendance-recap`, `/grade-recap` | new `RecapScreen` (toggle absen/nilai) |

### Dependency Graph

```
Step 0 ──┬─→ S1 dashboard
         ├─→ S2 schedule
         ├─→ S3 grades-student
         ├─→ S4 report-cards
         ├─→ S5 announcements
         ├─→ S6 assignments-student
         └─→ S7 teacher-classes ──→ S8 class-detail ──┬─→ S9 attendance
                                                       ├─→ S10 grade-input
                                                       └─→ S11 recap
```

S1–S6 independen setelah Step 0 selesai. S7 → S8 → {S9, S10, S11} ada dependency (S9–11 butuh meeting/TA detail dari S8).

### Estimasi (solo, no deadline, TDD)

| Item | Estimasi |
|---|---|
| Step 0 | 5–7 hari |
| S1–S6 | ~12–18 hari (2–3 hari/slice) |
| S7–S8 | 3–4 hari |
| S9 attendance | 4–5 hari |
| S10 grade-input | 4–5 hari |
| S11 recap | 2–3 hari |
| **Total** | **~30–42 hari kerja** |

---

## 11. Definition of Done (whole Phase 5)

- Semua 11 slice merged ke main
- Backend test coverage memenuhi target di §9.1
- Mobile test coverage memenuhi target di §9.2
- Swagger doc complete & rendered di `/api/documentation`
- Mobile build green di Android + iOS, manual QA pass per §9.3
- Cache offline (read-cache) terverifikasi pakai airplane mode
- Rate limiting aktif & terverifikasi
- README atau MOBILE_README di `floz_mobile/` updated
- Existing `Api\` namespace sudah bersih (tidak ada residual file di lokasi lama)
