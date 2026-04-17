# Student Courses & Materials Viewer — Design Spec

**Goal:** Siswa bisa melihat daftar mata pelajaran yang mereka ambil, drill ke pertemuan, dan akses materi (file/link/text) yang diupload guru lewat web admin.

**Why:** Phase 5 MVP belum punya viewer untuk materi pertemuan — guru bisa upload via web tapi siswa belum bisa lihat. Ini menutup gap fitur visible utama dari Phase 4 PRD ("Course & meeting materials").

---

## Architecture

### Backend (Laravel)

**Service:** `App\Services\Mobile\CoursesService`
- `listForStudent(User $user): array` — list teaching assignments for student's class. Returns `[{id, subject_name, teacher_name, meeting_count, material_count}]`.
- `meetingsFor(User $user, int $teachingAssignmentId): array` — list 16 meetings (1-14 + UTS/UAS) for one TA. Authz: TA's class_id must equal student's class_id. Returns `{teaching_assignment: {id, subject_name, teacher_name, class_name}, meetings: [{id, meeting_number, title, description, is_locked, material_count}]}`.
- `meetingDetail(User $user, int $meetingId): array` — meeting + all materials. Authz: meeting's TA must belong to student's class. Returns `{meeting: {...}, materials: [{id, title, type, content, file_name, file_size, file_url, url, sort_order}]}`. `file_url` is generated absolute URL via `asset('storage/'.$path)`.

**Controller:** `App\Http\Controllers\Api\V1\MobileStudentCoursesController`
- `index(Request)` — wraps `listForStudent`
- `meetings(Request, int $taId)` — wraps `meetingsFor`
- `meeting(Request, int $meetingId)` — wraps `meetingDetail`

**Routes (inside `role:student` middleware):**
```
GET /api/v1/student/courses
GET /api/v1/student/courses/{ta}/meetings
GET /api/v1/student/meetings/{meeting}
```

**Authz:** Service layer enforces `student->class_id === ta->class_id`. Mismatch throws `AuthorizationException` → 403.

### Mobile (Flutter)

**Feature dir:** `floz_mobile/lib/features/student/courses/`

```
domain/
  entities/{course.dart, meeting_summary.dart, meeting_detail.dart, material_item.dart}
  repositories/courses_repository.dart
data/
  models/{course_dto.dart, meetings_dto.dart, meeting_detail_dto.dart}
  datasources/courses_remote_datasource.dart
  repositories/courses_repository_impl.dart
providers/courses_providers.dart
presentation/screens/{course_detail_screen.dart, meeting_detail_screen.dart}
```

(No separate `courses_list_screen.dart` — courses are rendered inline on the dashboard.)

**Entry point:** Add a horizontal-scroll "Mata Pelajaran Saya" section to `DashboardScreen`, between the attendance stat card and "Jadwal Hari Ini". Each card is compact (subject name, teacher, meeting count badge, material count badge). Tap → push `CourseDetailScreen(taId, subjectName, teacherName, className)`.

**`CourseDetailScreen`:**
- Watches `meetingsProvider(taId)` (FutureProvider.family)
- AppBar: subject + class subtitle
- Lists 16 meetings as cards. Locked meetings show grayed + 🔒 + "Belum dibuka" text (disabled tap). Unlocked → tap → push `MeetingDetailScreen(meetingId)`.
- Each meeting card shows: number badge, title, material count chip.

**`MeetingDetailScreen`:**
- Watches `meetingDetailProvider(meetingId)`
- AppBar: meeting title
- Header: meeting number + description (if any)
- Materials list, each row depends on type:
  - **`text`** — render `content` inline (markdown-ish styled card, no nav)
  - **`link`** — chip with link icon + url; tap → open in external browser via `url_launcher`
  - **`file`** — chip with file icon + filename + file size; tap → open URL externally (download via system handler)

### Caching strategy

**Network-first, no cache layer** (matches recap convention from P6). Pull-to-refresh on both screens. If user's offline, show error state with retry.

### Locked meetings

Backend returns `is_locked` flag honestly. Mobile renders locked rows but disables tap. Rationale: keep Phase 5 simple; no separate hide/show config needed.

---

## Tasks (high level)

1. Backend: `CoursesService` + tests
2. Backend: `MobileStudentCoursesController` + routes + feature tests
3. Mobile: data layer (entities, DTOs, datasource, repo, repo tests)
4. Mobile: providers + `CourseDetailScreen` + `MeetingDetailScreen` + widget tests
5. Mobile: dashboard inline `_CoursesSection` widget + wire navigation
6. Integration: full regression + manual smoke test (Playwright + simulator)

Detailed task breakdown in the implementation plan (next).

---

## Decisions log

- **No `CoursesListScreen`** — dashboard inline section is the entry; redundant otherwise.
- **Horizontal scroll on dashboard** — compact, doesn't dominate. Vertical list would push "Jadwal Hari Ini" too far down.
- **No cache** — recap pattern. Materials change rarely but freshness matters.
- **External browser for files/links** — `url_launcher` is in pubspec already (used elsewhere if needed). No in-app PDF viewer (out of scope for MVP).
- **Locked meetings visible but disabled** — siswa tetap lihat ada 16 pertemuan, tapi tidak bisa buka yang belum dibuka guru. Bisa di-iterate jadi "hide entirely" kalau pengguna mau.

---

## Out of scope

- In-app file preview (PDF/image rendering) — relies on system viewer instead
- Mark-as-read tracking
- Comments / Q&A pada materi
- Search across materials
- Push notification when new material uploaded (out of Phase 5 scope)
