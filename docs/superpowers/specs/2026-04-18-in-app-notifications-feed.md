# In-App Notifications Feed — Design Spec

**Goal:** Mobile siswa & guru dapat melihat daftar notifikasi (nilai keluar, pengumuman baru, dll), tandai dibaca, dan tap untuk lompat ke konten terkait. In-app feed only — bukan system push.

**Why:** Phase 5 MVP punya 4 Laravel notification class yang dispatch ke `database` channel, tapi mobile belum ada UI untuk konsumsi. Web admin punya `/notifications` endpoint, mobile tidak. Fitur ini menutup gap visible terbesar tersisa dari Phase 4 PRD ("notifications") tanpa biaya FCM/Firebase setup.

**Out of scope (defer):**
- FCM / system tray push (separate spec, "option B" later)
- Settings to mute per notification type
- Parent role notifications (parent role belum ada)
- Notification history retention beyond 90 days
- Reverb-based real-time updates inside app

---

## Architecture

### Backend (Laravel)

**Service:** `App\Services\Mobile\NotificationsService`
- `listForUser(User $user, int $perPage = 20): array` — paginated list, ordered by `created_at DESC`. Returns `{data: [...], meta: {current_page, last_page, total, unread_count}}`.
- `markAsRead(User $user, string $notificationId): void` — set `read_at = now()` if `notifiable_id == user.id` and not already read. Throws `AuthorizationException` if user doesn't own the notification.
- `markAllAsRead(User $user): int` — bulk set `read_at = now()` for all unread of this user. Returns count updated.

**Controller:** `App\Http\Controllers\Api\V1\MobileNotificationsController`
- `index(Request)` — wraps `listForUser`. Returns paginated.
- `read(Request, string $id)` — wraps `markAsRead`. Returns 204.
- `readAll(Request)` — wraps `markAllAsRead`. Returns `{data: {marked: N}}`.

**Routes (inside both `role:student` AND `role:teacher` middleware blocks):**
```
GET  /api/v1/notifications
POST /api/v1/notifications/{id}/read
POST /api/v1/notifications/read-all
```

Use `Route::middleware('role:student|teacher')` (pipe-separated) if EnsureRole supports it; otherwise duplicate routes in both blocks.

**Authz:** Service-layer ownership check on `notifiable_id` for `read` action. List naturally scopes to `$user->notifications()` so no cross-user leakage.

**Notification response shape:**
```json
{
  "data": [
    {
      "id": "uuid",
      "type": "grade_posted",            // friendly name (see mapping below)
      "title": "Nilai Matematika dirilis",
      "body": "Nilai akhir semester Anda: 85 (B)",
      "icon": "star",                     // friendly icon key (mobile maps to IconData)
      "action": {                         // optional, drives mobile tap-navigation
        "screen": "grades",
        "args": {"subject_id": 5}
      },
      "read_at": null,                    // ISO string when read
      "created_at": "2026-04-18T08:30:00Z"
    }
  ],
  "meta": {
    "current_page": 1, "last_page": 1, "total": 12, "per_page": 20,
    "unread_count": 3
  }
}
```

### Type → friendly mapping (in NotificationsService)

| Laravel class | `type` | `icon` | `action.screen` |
|---|---|---|---|
| `App\Notifications\GradePostedNotification` | `grade_posted` | `star` | `grades` |
| `App\Notifications\NewAnnouncementNotification` | `announcement` | `campaign` | `announcement_detail` |
| `App\Notifications\NewAssignmentNotification` | `assignment` | `assignment` | `assignments` |
| `App\Notifications\StudentAbsentNotification` | `student_absent` | `event_busy` | (none — parent only) |
| (unknown) | `other` | `bell` | (none) |

The service reads `$notification->data` (existing JSON payload) and projects `title` + `body` + `action` from it. If existing notification class data doesn't carry these fields, the mapping picks sensible defaults from the class name.

### Mobile (Flutter)

**Feature dir:** `floz_mobile/lib/features/shared/notifications/` (shared between student & teacher shells).

```
domain/
  entities/{notification_item.dart, notifications_page.dart}
  repositories/notifications_repository.dart
data/
  models/{notification_dto.dart, notifications_page_dto.dart}
  datasources/notifications_remote_datasource.dart
  repositories/notifications_repository_impl.dart
providers/notifications_providers.dart
presentation/
  screens/notifications_screen.dart
  widgets/notification_bell.dart
```

**Entry point:** `NotificationBell` widget — small bell icon button with red badge showing unread count. Sits in the top bar of:
- `DashboardScreen` (student Beranda) — top bar already has profile button, add bell to its left.
- `ClassesListScreen` (teacher all 3 tabs) — same top bar, same placement.

If `unreadCount == 0`, bell shows without badge. If > 0, red circle with white number (max display "9+").

**Tap bell** → push `NotificationsScreen`.

**`NotificationsScreen`:**
- AppBar "Notifikasi" + trailing "Tandai semua dibaca" text button (only when `unreadCount > 0`).
- Body: pull-to-refresh wrapping a paginated `ListView` of `_NotificationCard` widgets.
- **`_NotificationCard`:**
  - Unread: `AppColors.primary50` background, primary600 dot indicator.
  - Read: white background, no dot.
  - Icon (left): mapped from `icon` field, primary600 in primary50 circle.
  - Title (slate900, bold, 14sp).
  - Body (slate600, 12sp, 2-line max).
  - Time (slate400, 11sp): relative — "5 menit lalu", "2 jam lalu", "3 hari lalu", or DateFormat for >7 days.
  - Tap: invalidate provider after `markAsRead` + navigate to `action.screen` if any (no-op for unknown).
- Empty state: FlozCard with bell icon + "Belum ada notifikasi.".
- Pagination: simple — load page 1 only for v1. Show "Lihat lebih banyak" hint at bottom if `meta.total > 20` (defer infinite scroll to v2).

**Providers:**
- `notificationsRepositoryProvider` — wires datasource + impl
- `notificationsPageProvider` — `FutureProvider<NotificationsPage>`, refreshable
- `unreadCountProvider` — derived: `ref.watch(notificationsPageProvider).maybeWhen(data: (p) => p.unreadCount, orElse: () => 0)`
- `markAsReadController` — mutation: calls repo + invalidates `notificationsPageProvider`
- `markAllAsReadController` — same

### Navigation from notification tap

Per `action.screen` value, mobile maps:

| `screen` | Student behavior | Teacher behavior |
|---|---|---|
| `grades` | switch StudentShell to Nilai tab | (no-op for teacher; not their notif type) |
| `announcement_detail` | open existing announcement detail screen with `args.id` | same |
| `assignments` | switch StudentShell to Tugas tab | switch TeacherShell to Nilai tab (input nilai for tugas) |
| (other / null) | just close NotificationsScreen | same |

Note: mobile shells use `int _index` for tab control; navigation from outside requires either a global `selectedTabProvider` (StateProvider<int>) or a callback. We'll add `studentSelectedTabProvider` and `teacherSelectedTabProvider` (StateProvider<int>) so notification navigation can switch tabs without rebuilding the shell.

### Caching

**Network-first, no cache layer** (matches recap/courses convention). Bell badge re-fetches on app foreground (out of scope for v1 — just refreshes when NotificationsScreen pulled).

### Error handling

- 401 on any endpoint → standard auth flow (existing handler clears session, router redirects to /login).
- Network error → snackbar "Gagal memuat notifikasi. Periksa koneksi.".
- markAsRead error → silent (best-effort; user can retry by tapping again).

### Testing

**Backend:**
- Unit: `NotificationsServiceTest` (5 tests): list happy, list empty, mark-as-read happy, mark-as-read 403 cross-user, mark-all-as-read.
- Feature: `NotificationsTest` (4 tests): GET happy + 401, POST read happy, POST read-all happy.

**Mobile:**
- Repo tests: 4 (list happy/error, markAsRead happy, markAllAsRead happy).
- Widget tests: 3 (NotificationsScreen shows list with read/unread distinction, mark-all-as-read clears unread, empty state).

---

## Decisions log

- **No real-time updates** — bell only refreshes on screen pull/mount. Push-to-bell badge would need polling or WebSocket; out of scope.
- **No infinite scroll v1** — first page (20 items) only. "Lihat lebih banyak" hint instead. Saves client-side state mgmt.
- **Service-layer authz on read** — even though `notifiable_id` filtering on list is implicit, `markAsRead` needs explicit ownership check (route param could be any UUID).
- **Type+icon+action mapping in service, not mobile** — keeps mapping changes server-side without app updates.
- **Tap navigation via StateProvider tab indices** — keeps shell intact, no nav stack hacks.

---

## Tasks (high level)

1. **Backend NotificationsService TDD** — 3 methods + 5 unit tests. Includes type→friendly mapper.
2. **Backend Controller + routes + 4 feature tests** — wire 3 endpoints.
3. **Mobile data layer** — entities + DTOs + datasource + repo + 4 repo tests.
4. **Mobile providers + NotificationBell widget** — Riverpod plumbing + bell widget with badge.
5. **Mobile NotificationsScreen + widget tests** — full list screen + 3 widget tests.
6. **Wire NotificationBell into student + teacher top bars** — modify dashboard + classes_list_screen top bars to host the bell next to profile.
7. **Tab-switching providers + tap navigation** — add `studentSelectedTabProvider` and `teacherSelectedTabProvider`, refactor shells to consume them, wire notification tap.
8. **Integration regression + manual smoke test + tag** — backend + mobile suites green; tag `notifications-feed-complete`.

Detailed task breakdown in the implementation plan (next).
