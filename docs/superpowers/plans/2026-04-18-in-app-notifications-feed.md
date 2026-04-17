# In-App Notifications Feed — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mobile siswa & guru bisa lihat daftar notifikasi (grade posted, announcement, assignment), tandai dibaca, tap untuk navigasi ke konten terkait. In-app feed only — no FCM/push.

**Architecture:** Backend exposes 3 read/write endpoints over the existing Laravel `notifications` table (UUID, polymorphic). Mobile adds a `shared/notifications` feature with bell widget (in top bar) + full-screen list. Tab-switching via `StateProvider<int>` so notification tap can deep-link into the right shell tab.

**Tech Stack:** Laravel 12, Pest 3, Sanctum, Flutter 3.11, Riverpod, Dio, mocktail

---

## Key Decisions

1. **Routes available to BOTH roles** via `Route::middleware('role:student,teacher')` (EnsureRole is variadic with comma — verified at `EnsureRole.php:15`).
2. **Existing notification `data` payload** already has `type` ('grade'/'announcement'/'assignment'), `title`, `message`, `link` (web URL). Service projects these into mobile-friendly shape: `body` = `data.message`, `action` = our own mapping. Web `link` field ignored.
3. **No infinite scroll v1** — load page 1 only (20 items). Defer.
4. **Tab-switching** via 2 new `StateProvider<int>` (one per shell) so notification tap can change tab without navigator hacks. Requires shell refactor (ConsumerStatefulWidget → ConsumerWidget reading provider).
5. **Bell badge** re-fetches only on screen mount/pull. No polling.
6. **Auth ownership** on `markAsRead` enforced at service layer (route param could be any UUID).

---

## File Structure

### Backend — create
```
src/app/Services/Mobile/NotificationsService.php
src/app/Http/Controllers/Api/V1/MobileNotificationsController.php
src/tests/Unit/Services/Mobile/NotificationsServiceTest.php
src/tests/Feature/Api/V1/NotificationsTest.php
```

### Backend — modify
```
src/routes/api.php                                 (1 import + 3 routes outside the role-specific blocks)
```

### Mobile — create
```
floz_mobile/lib/features/shared/notifications/domain/entities/notification_item.dart
floz_mobile/lib/features/shared/notifications/domain/entities/notifications_page.dart
floz_mobile/lib/features/shared/notifications/domain/repositories/notifications_repository.dart
floz_mobile/lib/features/shared/notifications/data/models/notification_dto.dart
floz_mobile/lib/features/shared/notifications/data/models/notifications_page_dto.dart
floz_mobile/lib/features/shared/notifications/data/datasources/notifications_remote_datasource.dart
floz_mobile/lib/features/shared/notifications/data/repositories/notifications_repository_impl.dart
floz_mobile/lib/features/shared/notifications/providers/notifications_providers.dart
floz_mobile/lib/features/shared/notifications/presentation/screens/notifications_screen.dart
floz_mobile/lib/features/shared/notifications/presentation/widgets/notification_bell.dart
floz_mobile/lib/features/student/shared/providers/student_tab_providers.dart
floz_mobile/lib/features/teacher/shared/providers/teacher_tab_providers.dart
floz_mobile/test/features/shared/notifications/data/repositories/notifications_repository_impl_test.dart
floz_mobile/test/features/shared/notifications/presentation/screens/notifications_screen_test.dart
```

### Mobile — modify
```
floz_mobile/lib/core/network/api_endpoints.dart                                            (3 endpoint constants)
floz_mobile/lib/features/student/shared/widgets/student_shell.dart                          (consume tab provider)
floz_mobile/lib/features/teacher/shared/widgets/teacher_shell.dart                          (consume tab provider)
floz_mobile/lib/features/student/dashboard/presentation/screens/dashboard_screen.dart       (insert NotificationBell into _TopBar)
floz_mobile/lib/features/teacher/classes/presentation/screens/classes_list_screen.dart      (insert NotificationBell into _TopBar)
```

---

## Tasks

### Task 1: NotificationsService TDD

**Files:**
- Create: `src/app/Services/Mobile/NotificationsService.php`
- Test: `src/tests/Unit/Services/Mobile/NotificationsServiceTest.php`

**Service spec:**

```php
<?php

namespace App\Services\Mobile;

use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Notifications\DatabaseNotification;

class NotificationsService
{
    /** @return array{data: array, meta: array} */
    public function listForUser(User $user, int $perPage = 20): array
    {
        $page = $user->notifications()->orderBy('created_at', 'desc')->paginate($perPage);

        $unreadCount = $user->unreadNotifications()->count();

        return [
            'data' => $page->getCollection()->map(fn ($n) => $this->project($n))->all(),
            'meta' => [
                'current_page' => $page->currentPage(),
                'last_page' => $page->lastPage(),
                'total' => $page->total(),
                'per_page' => $page->perPage(),
                'unread_count' => $unreadCount,
            ],
        ];
    }

    public function markAsRead(User $user, string $notificationId): void
    {
        $notification = DatabaseNotification::find($notificationId);

        if (! $notification
            || $notification->notifiable_type !== User::class
            || (int) $notification->notifiable_id !== $user->id) {
            throw new AuthorizationException('Notifikasi tidak ditemukan atau bukan milik Anda.');
        }

        if ($notification->read_at === null) {
            $notification->markAsRead();
        }
    }

    public function markAllAsRead(User $user): int
    {
        return $user->unreadNotifications()->update(['read_at' => now()]);
    }

    /**
     * Project a database notification into mobile-friendly shape.
     * Existing notifications carry: data.type, data.title, data.message, data.link.
     */
    private function project(DatabaseNotification $n): array
    {
        $data = $n->data ?? [];
        $type = $data['type'] ?? 'other';
        [$icon, $action] = $this->mapTypeToIconAndAction($type, $data);

        return [
            'id' => $n->id,
            'type' => $type,
            'title' => $data['title'] ?? 'Notifikasi',
            'body' => $data['message'] ?? '',
            'icon' => $icon,
            'action' => $action,
            'read_at' => $n->read_at?->toIso8601String(),
            'created_at' => $n->created_at->toIso8601String(),
        ];
    }

    /**
     * @return array{0: string, 1: array|null}  [icon_key, action_or_null]
     */
    private function mapTypeToIconAndAction(string $type, array $data): array
    {
        return match ($type) {
            'grade' => ['star', ['screen' => 'grades', 'args' => []]],
            'announcement' => ['campaign', ['screen' => 'announcement_detail', 'args' => array_filter([
                'id' => $data['announcement_id'] ?? null,
            ])]],
            'assignment' => ['assignment', ['screen' => 'assignments', 'args' => []]],
            'student_absent' => ['event_busy', null],
            default => ['bell', null],
        };
    }
}
```

**Test cases (Pest, 5 total) — write all FIRST, watch them fail, then implement:**

```php
<?php

use App\Models\Student;
use App\Models\User;
use App\Notifications\GradePostedNotification;
use App\Services\Mobile\NotificationsService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->service = new NotificationsService();
});

it('listForUser returns paginated notifications with unread count', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $user->update(['role' => 'student']);

    // Manually insert 3 notifications: 2 unread, 1 read
    $user->notifications()->create([
        'id' => \Str::uuid()->toString(),
        'type' => 'App\\Notifications\\GradePostedNotification',
        'data' => ['type' => 'grade', 'title' => 'Nilai Baru', 'message' => 'Matematika: 85'],
        'read_at' => null,
    ]);
    $user->notifications()->create([
        'id' => \Str::uuid()->toString(),
        'type' => 'App\\Notifications\\NewAnnouncementNotification',
        'data' => ['type' => 'announcement', 'title' => 'Pengumuman', 'message' => 'Libur besok', 'announcement_id' => 5],
        'read_at' => null,
    ]);
    $user->notifications()->create([
        'id' => \Str::uuid()->toString(),
        'type' => 'App\\Notifications\\GradePostedNotification',
        'data' => ['type' => 'grade', 'title' => 'Nilai Baru', 'message' => 'IPA: 90'],
        'read_at' => now(),
    ]);

    $result = $this->service->listForUser($user);

    expect($result['data'])->toHaveCount(3);
    expect($result['meta']['unread_count'])->toBe(2);
    expect($result['meta']['total'])->toBe(3);

    $first = $result['data'][0];
    expect($first)->toHaveKeys(['id', 'type', 'title', 'body', 'icon', 'action', 'read_at', 'created_at']);
});

it('listForUser projects type to icon + action correctly', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $user->update(['role' => 'student']);

    $user->notifications()->create([
        'id' => \Str::uuid()->toString(),
        'type' => 'App\\Notifications\\NewAnnouncementNotification',
        'data' => ['type' => 'announcement', 'title' => 'Pengumuman', 'message' => 'X', 'announcement_id' => 7],
    ]);

    $result = $this->service->listForUser($user);
    $n = $result['data'][0];

    expect($n['icon'])->toBe('campaign');
    expect($n['action'])->toBe(['screen' => 'announcement_detail', 'args' => ['id' => 7]]);
});

it('markAsRead marks unread notification', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $user->update(['role' => 'student']);

    $id = \Str::uuid()->toString();
    $user->notifications()->create([
        'id' => $id,
        'type' => 'App\\Notifications\\GradePostedNotification',
        'data' => ['type' => 'grade', 'title' => 'X', 'message' => 'Y'],
        'read_at' => null,
    ]);

    $this->service->markAsRead($user, $id);

    expect($user->notifications()->find($id)->read_at)->not->toBeNull();
});

it('markAsRead throws when notification belongs to another user', function () {
    $s1 = Student::factory()->create();
    $u1 = User::where('email', $s1->email)->first(); $u1->update(['role' => 'student']);
    $s2 = Student::factory()->create();
    $u2 = User::where('email', $s2->email)->first(); $u2->update(['role' => 'student']);

    $id = \Str::uuid()->toString();
    $u2->notifications()->create([
        'id' => $id,
        'type' => 'App\\Notifications\\GradePostedNotification',
        'data' => ['type' => 'grade', 'title' => 'X', 'message' => 'Y'],
    ]);

    expect(fn () => $this->service->markAsRead($u1, $id))
        ->toThrow(AuthorizationException::class);
});

it('markAllAsRead marks all unread for user and returns count', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $user->update(['role' => 'student']);

    foreach (range(1, 4) as $i) {
        $user->notifications()->create([
            'id' => \Str::uuid()->toString(),
            'type' => 'App\\Notifications\\GradePostedNotification',
            'data' => ['type' => 'grade', 'title' => 'X', 'message' => "msg {$i}"],
            'read_at' => $i === 1 ? now() : null,  // 1 already read, 3 unread
        ]);
    }

    $count = $this->service->markAllAsRead($user);

    expect($count)->toBe(3);
    expect($user->unreadNotifications()->count())->toBe(0);
});
```

**Steps:**
- [ ] **1.1 Read sibling** — `src/app/Services/Mobile/CoursesService.php` for shape conventions (private helpers, projection patterns).
- [ ] **1.2 Write test file** — paste all 5 tests above. Run `cd src && php artisan test --env=testing tests/Unit/Services/Mobile/NotificationsServiceTest.php`. Expect "Class NotificationsService not found".
- [ ] **1.3 Implement service** — paste service code above.
- [ ] **1.4 Run tests** — same command. Expect 5/5 pass.
- [ ] **1.5 Commit:**
  ```bash
  cd /Users/tokaf/Floz_SDN_KELAPADUA_IV && git add src/app/Services/Mobile/NotificationsService.php src/tests/Unit/Services/Mobile/NotificationsServiceTest.php && git commit -m "feat(api/notifications): NotificationsService for mobile feed (TDD)"
  ```

---

### Task 2: V1 Controller + Feature Tests + Routes

**Files:**
- Create: `src/app/Http/Controllers/Api/V1/MobileNotificationsController.php`
- Create: `src/tests/Feature/Api/V1/NotificationsTest.php`
- Modify: `src/routes/api.php` (1 import + 3 routes inside `auth:sanctum` group, with `role:student,teacher` middleware)

**Controller spec:**

```php
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Mobile\NotificationsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MobileNotificationsController extends Controller
{
    public function __construct(private readonly NotificationsService $service) {}

    public function index(Request $request): JsonResponse
    {
        return response()->json($this->service->listForUser($request->user()));
    }

    public function read(Request $request, string $id): JsonResponse
    {
        $this->service->markAsRead($request->user(), $id);
        return response()->json(null, 204);
    }

    public function readAll(Request $request): JsonResponse
    {
        $count = $this->service->markAllAsRead($request->user());
        return response()->json(['data' => ['marked' => $count]]);
    }
}
```

**Routes (add at the appropriate place — inside the existing `Route::middleware('auth:sanctum')->group(...)` block but OUTSIDE both `role:student` and `role:teacher` sub-groups, with explicit `role:student,teacher` middleware):**

```php
use App\Http\Controllers\Api\V1\MobileNotificationsController;

// Inside auth:sanctum group, outside role-specific sub-groups:
Route::middleware('role:student,teacher')->group(function () {
    Route::get('/notifications', [MobileNotificationsController::class, 'index']);
    Route::post('/notifications/{id}/read', [MobileNotificationsController::class, 'read']);
    Route::post('/notifications/read-all', [MobileNotificationsController::class, 'readAll']);
});
```

**Test cases (Pest, 4 total) — mirror `CoursesTest.php` style:**

```php
<?php

use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->student = Student::factory()->create();
    $this->user = User::where('email', $this->student->email)->first();
    $this->user->update(['role' => 'student']);
    $this->token = $this->user->createToken('mobile')->plainTextToken;
});

it('GET /notifications returns paginated list with unread_count', function () {
    $this->user->notifications()->create([
        'id' => \Str::uuid()->toString(),
        'type' => 'App\\Notifications\\GradePostedNotification',
        'data' => ['type' => 'grade', 'title' => 'Nilai', 'message' => 'X'],
    ]);

    $this->withHeader('Authorization', "Bearer {$this->token}")
        ->getJson('/api/v1/notifications')
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('meta.unread_count', 1);
});

it('POST /notifications/{id}/read marks as read', function () {
    $id = \Str::uuid()->toString();
    $this->user->notifications()->create([
        'id' => $id,
        'type' => 'App\\Notifications\\GradePostedNotification',
        'data' => ['type' => 'grade', 'title' => 'X', 'message' => 'Y'],
    ]);

    $this->withHeader('Authorization', "Bearer {$this->token}")
        ->postJson("/api/v1/notifications/{$id}/read")
        ->assertNoContent();

    expect($this->user->notifications()->find($id)->read_at)->not->toBeNull();
});

it('POST /notifications/read-all marks everything as read and returns count', function () {
    foreach (range(1, 3) as $i) {
        $this->user->notifications()->create([
            'id' => \Str::uuid()->toString(),
            'type' => 'App\\Notifications\\GradePostedNotification',
            'data' => ['type' => 'grade', 'title' => 'X', 'message' => "msg {$i}"],
        ]);
    }

    $this->withHeader('Authorization', "Bearer {$this->token}")
        ->postJson('/api/v1/notifications/read-all')
        ->assertOk()
        ->assertJsonPath('data.marked', 3);
});

it('GET /notifications returns 401 without token', function () {
    $this->getJson('/api/v1/notifications')->assertUnauthorized();
});
```

**Steps:**
- [ ] **2.1 Read sibling** — `src/app/Http/Controllers/Api/V1/MobileStudentCoursesController.php` for thin-controller shape and `src/tests/Feature/Api/V1/Student/CoursesTest.php` for token + assertion conventions.
- [ ] **2.2 Read routes layout** — `src/routes/api.php`. Find the existing `auth:sanctum` group (around lines 35-67) and identify the right insertion point (above `role:student` block, OR a separate inner group).
- [ ] **2.3 Write feature test file** at `src/tests/Feature/Api/V1/NotificationsTest.php`. Run, expect 404 / route-not-found.
- [ ] **2.4 Implement controller** — paste code above.
- [ ] **2.5 Add 1 import + 3 routes** to `src/routes/api.php` per spec above.
- [ ] **2.6 Run tests** — `cd src && php artisan test --env=testing tests/Feature/Api/V1/NotificationsTest.php`. Expect 4/4 pass.
- [ ] **2.7 Run full backend regression** — `cd src && php artisan test --env=testing 2>&1 | tail -5`. Expect previous count + 9 (5 unit + 4 feature).
- [ ] **2.8 Commit:**
  ```bash
  cd /Users/tokaf/Floz_SDN_KELAPADUA_IV && git add src/app/Http/Controllers/Api/V1/MobileNotificationsController.php src/tests/Feature/Api/V1/NotificationsTest.php src/routes/api.php && git commit -m "feat(api/notifications): MobileNotificationsController + routes + feature tests"
  ```

---

### Task 3: Mobile data layer

**Files (create):**
```
floz_mobile/lib/features/shared/notifications/domain/entities/notification_item.dart
floz_mobile/lib/features/shared/notifications/domain/entities/notifications_page.dart
floz_mobile/lib/features/shared/notifications/domain/repositories/notifications_repository.dart
floz_mobile/lib/features/shared/notifications/data/models/notification_dto.dart
floz_mobile/lib/features/shared/notifications/data/models/notifications_page_dto.dart
floz_mobile/lib/features/shared/notifications/data/datasources/notifications_remote_datasource.dart
floz_mobile/lib/features/shared/notifications/data/repositories/notifications_repository_impl.dart
floz_mobile/test/features/shared/notifications/data/repositories/notifications_repository_impl_test.dart
```

**Files (modify):**
```
floz_mobile/lib/core/network/api_endpoints.dart  (add 3 constants)
```

**Entity definitions:**

```dart
// notification_item.dart
class NotificationAction {
  final String screen;
  final Map<String, dynamic> args;
  const NotificationAction({required this.screen, this.args = const {}});
}

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final String icon;
  final NotificationAction? action;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.icon,
    this.action,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;
}

// notifications_page.dart
import 'notification_item.dart';

class NotificationsPage {
  final List<NotificationItem> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int unreadCount;

  const NotificationsPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.unreadCount,
  });
}
```

**Repository abstract:**

```dart
// notifications_repository.dart
import '../../../../../core/error/result.dart';
import '../entities/notifications_page.dart';

abstract class NotificationsRepository {
  Future<Result<NotificationsPage>> fetch();
  Future<Result<void>> markAsRead(String id);
  Future<Result<int>> markAllAsRead();
}
```

**Endpoints to add to `api_endpoints.dart`:**

```dart
static const String notifications = '/notifications';
static String notificationRead(String id) => '/notifications/$id/read';
static const String notificationsReadAll = '/notifications/read-all';
```

**DTOs:**

```dart
// notification_dto.dart
import '../../domain/entities/notification_item.dart';

class NotificationDto {
  static NotificationItem fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'other',
      title: json['title']?.toString() ?? 'Notifikasi',
      body: json['body']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'bell',
      action: _actionFromJson(json['action']),
      readAt: _parseDate(json['read_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  static NotificationAction? _actionFromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final screen = raw['screen']?.toString();
    if (screen == null || screen.isEmpty) return null;
    final args = (raw['args'] is Map) ? Map<String, dynamic>.from(raw['args'] as Map) : <String, dynamic>{};
    return NotificationAction(screen: screen, args: args);
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}

// notifications_page_dto.dart
import '../../domain/entities/notifications_page.dart';
import 'notification_dto.dart';

class NotificationsPageDto {
  static NotificationsPage fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(NotificationDto.fromJson)
        .toList(growable: false);
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return NotificationsPage(
      items: items,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? items.length,
      unreadCount: (meta['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}
```

**Datasource (abstract + Impl, mirror sibling pattern):**

```dart
// notifications_remote_datasource.dart
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../models/notifications_page_dto.dart';
import '../../domain/entities/notifications_page.dart';

abstract class NotificationsRemoteDataSource {
  Future<NotificationsPage> fetch();
  Future<void> markAsRead(String id);
  Future<int> markAllAsRead();
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final ApiClient _client;
  const NotificationsRemoteDataSourceImpl(this._client);

  @override
  Future<NotificationsPage> fetch() async {
    final res = await _client.get(ApiEndpoints.notifications);
    return NotificationsPageDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> markAsRead(String id) async {
    await _client.post(ApiEndpoints.notificationRead(id));
  }

  @override
  Future<int> markAllAsRead() async {
    final res = await _client.post(ApiEndpoints.notificationsReadAll);
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return (data['marked'] as num?)?.toInt() ?? 0;
  }
}
```

**Repository impl (`_guard<T>` helper, mirror courses):**

```dart
// notifications_repository_impl.dart
import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/network/api_exception.dart';
import '../../domain/entities/notifications_page.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource _remote;
  const NotificationsRepositoryImpl({required NotificationsRemoteDataSource remote}) : _remote = remote;

  @override
  Future<Result<NotificationsPage>> fetch() => _guard(() => _remote.fetch());

  @override
  Future<Result<void>> markAsRead(String id) => _guard(() => _remote.markAsRead(id));

  @override
  Future<Result<int>> markAllAsRead() => _guard(() => _remote.markAllAsRead());

  Future<Result<T>> _guard<T>(Future<T> Function() op) async {
    try {
      return Success(await op());
    } on NetworkException catch (e) {
      return FailureResult(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(ForbiddenFailure(e.message));
    } on ValidationException catch (e) {
      return FailureResult(ValidationFailure(message: e.message, fieldErrors: e.errors));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message, statusCode: e.statusCode));
    } on ApiException catch (e) {
      return FailureResult(ServerFailure(e.message));
    }
  }
}
```

**Tests (4, mocktail):**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/features/shared/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:floz_mobile/features/shared/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:floz_mobile/features/shared/notifications/domain/entities/notification_item.dart';
import 'package:floz_mobile/features/shared/notifications/domain/entities/notifications_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements NotificationsRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late NotificationsRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = NotificationsRepositoryImpl(remote: remote);
  });

  test('fetch returns Success with page', () async {
    when(() => remote.fetch()).thenAnswer((_) async => NotificationsPage(
          items: [
            NotificationItem(
              id: '1', type: 'grade', title: 'Nilai',
              body: 'Matematika: 85', icon: 'star',
              createdAt: DateTime.parse('2026-04-18T08:00:00Z'),
            ),
          ],
          currentPage: 1, lastPage: 1, total: 1, unreadCount: 1,
        ));
    final r = await repo.fetch();
    expect(r, isA<Success<NotificationsPage>>());
    expect((r as Success).data.unreadCount, 1);
  });

  test('fetch returns NetworkFailure on NetworkException', () async {
    when(() => remote.fetch()).thenThrow(NetworkException('offline'));
    final r = await repo.fetch();
    expect(r, isA<FailureResult<NotificationsPage>>());
    expect((r as FailureResult).failure, isA<NetworkFailure>());
  });

  test('markAsRead returns Success', () async {
    when(() => remote.markAsRead('abc')).thenAnswer((_) async {});
    final r = await repo.markAsRead('abc');
    expect(r, isA<Success<void>>());
  });

  test('markAllAsRead returns Success with count', () async {
    when(() => remote.markAllAsRead()).thenAnswer((_) async => 7);
    final r = await repo.markAllAsRead();
    expect(r, isA<Success<int>>());
    expect((r as Success).data, 7);
  });
}
```

**Steps:**
- [ ] **3.1 Read sibling** — `floz_mobile/lib/features/student/courses/data/` for entity / DTO / datasource / repo conventions.
- [ ] **3.2 Add 3 endpoint constants** to `api_endpoints.dart` per spec above.
- [ ] **3.3 Create entities** — 2 files under `domain/entities/`.
- [ ] **3.4 Create repo abstract**.
- [ ] **3.5 Create DTOs** — 2 files.
- [ ] **3.6 Create datasource** (abstract + Impl).
- [ ] **3.7 Create repo impl** with `_guard<T>` helper.
- [ ] **3.8 Write 4 repo tests** per spec above.
- [ ] **3.9 Run tests** — `cd floz_mobile && flutter test test/features/shared/notifications/`. Expect 4/4 pass.
- [ ] **3.10 flutter analyze** on touched files — must be clean.
- [ ] **3.11 Commit:**
  ```bash
  cd /Users/tokaf/Floz_SDN_KELAPADUA_IV && git add floz_mobile/lib/features/shared/notifications floz_mobile/lib/core/network/api_endpoints.dart floz_mobile/test/features/shared/notifications && git commit -m "feat(mobile/notifications): data layer + entities + DTO + repo (no cache)"
  ```

---

### Task 4: Tab providers + shell refactor

**Why this comes before screens:** the NotificationsScreen needs to switch tabs after navigation. Shells currently own `int _index` as `ConsumerStatefulWidget` — refactor to read `StateProvider<int>` so notifications can `.notifier.state = N`.

**Files:**
- Create: `floz_mobile/lib/features/student/shared/providers/student_tab_providers.dart`
- Create: `floz_mobile/lib/features/teacher/shared/providers/teacher_tab_providers.dart`
- Modify: `floz_mobile/lib/features/student/shared/widgets/student_shell.dart`
- Modify: `floz_mobile/lib/features/teacher/shared/widgets/teacher_shell.dart`

**Tab providers (create):**

```dart
// student_tab_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected tab index in StudentShell. Notification deep-link writes to this.
/// 0 Beranda, 1 Jadwal, 2 Nilai, 3 Rapor, 4 Info, 5 Tugas
final studentSelectedTabProvider = StateProvider<int>((ref) => 0);

// teacher_tab_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected tab index in TeacherShell. Notification deep-link writes to this.
/// 0 Kelas, 1 Nilai, 2 Rekap
final teacherSelectedTabProvider = StateProvider<int>((ref) => 0);
```

**StudentShell refactor (`student_shell.dart`):**

Convert from `ConsumerStatefulWidget` (with `int _index`) → `ConsumerWidget` reading `studentSelectedTabProvider`. Replace `setState(() => _index = i)` with `ref.read(studentSelectedTabProvider.notifier).state = i`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../announcements/presentation/screens/announcements_list_screen.dart';
import '../../assignments/presentation/screens/assignments_list_screen.dart';
import '../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../grades/presentation/screens/grades_list_screen.dart';
import '../../report_cards/presentation/screens/report_cards_list_screen.dart';
import '../../schedule/presentation/screens/schedule_screen.dart';
import '../providers/student_tab_providers.dart';

class StudentShell extends ConsumerWidget {
  const StudentShell({super.key});

  static const _tabs = <_StudentTab>[
    _StudentTab(label: 'Beranda', icon: Icons.home_outlined, activeIcon: Icons.home),
    _StudentTab(label: 'Jadwal', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today),
    _StudentTab(label: 'Nilai', icon: Icons.grade_outlined, activeIcon: Icons.grade),
    _StudentTab(label: 'Rapor', icon: Icons.description_outlined, activeIcon: Icons.description),
    _StudentTab(label: 'Info', icon: Icons.campaign_outlined, activeIcon: Icons.campaign),
    _StudentTab(label: 'Tugas', icon: Icons.assignment_outlined, activeIcon: Icons.assignment),
  ];

  Widget _buildTab(int index) {
    return switch (index) {
      0 => const DashboardScreen(),
      1 => const ScheduleScreen(),
      2 => const GradesListScreen(),
      3 => const ReportCardsListScreen(),
      4 => const AnnouncementsListScreen(),
      5 => const AssignmentsListScreen(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(studentSelectedTabProvider);
    return Scaffold(
      body: _buildTab(index),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(studentSelectedTabProvider.notifier).state = i,
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _StudentTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _StudentTab({required this.label, required this.icon, required this.activeIcon});
}
```

**TeacherShell refactor (`teacher_shell.dart`):**

Same pattern. Convert from `ConsumerStatefulWidget` → `ConsumerWidget` reading `teacherSelectedTabProvider`. Important: TeacherShell has nested closures (Navigator pushes + onClassTap) — make sure they still work after refactor.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../classes/presentation/screens/classes_list_screen.dart';
import '../../grades_input/presentation/screens/grade_input_screen.dart';
import '../../recaps/presentation/screens/recap_screen.dart';
import '../providers/teacher_tab_providers.dart';

class TeacherShell extends ConsumerWidget {
  const TeacherShell({super.key});

  static const _tabs = <_TeacherTab>[
    _TeacherTab(label: 'Kelas', icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book_rounded),
    _TeacherTab(label: 'Nilai', icon: Icons.edit_note_outlined, activeIcon: Icons.edit_note),
    _TeacherTab(label: 'Rekap', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded),
  ];

  Widget _buildTab(BuildContext context, int index) {
    return switch (index) {
      0 => const ClassesListScreen(purpose: ClassListPurpose.kelas),
      1 => ClassesListScreen(
          purpose: ClassListPurpose.nilai,
          onClassTap: (ta) => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GradeInputScreen(
                taId: ta.id,
                subjectName: ta.subjectName,
                className: ta.className,
              ),
            ),
          ),
        ),
      2 => ClassesListScreen(
          purpose: ClassListPurpose.rekap,
          onClassTap: (ta) => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecapScreen(
                taId: ta.id,
                subjectName: ta.subjectName,
                className: ta.className,
              ),
            ),
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(teacherSelectedTabProvider);
    return Scaffold(
      body: _buildTab(context, index),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(teacherSelectedTabProvider.notifier).state = i,
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TeacherTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _TeacherTab({required this.label, required this.icon, required this.activeIcon});
}
```

**Steps:**
- [ ] **4.1 Read current shells** — `floz_mobile/lib/features/student/shared/widgets/student_shell.dart` and `teacher_shell.dart`.
- [ ] **4.2 Create both tab provider files**.
- [ ] **4.3 Refactor StudentShell** to ConsumerWidget per spec.
- [ ] **4.4 Refactor TeacherShell** to ConsumerWidget per spec.
- [ ] **4.5 flutter analyze lib/features/student lib/features/teacher** — clean.
- [ ] **4.6 Run any existing shell tests** — `flutter test test/features/student/ test/features/teacher/`. All must still pass.
- [ ] **4.7 Commit:**
  ```bash
  cd /Users/tokaf/Floz_SDN_KELAPADUA_IV && git add floz_mobile/lib/features/student/shared/providers floz_mobile/lib/features/teacher/shared/providers floz_mobile/lib/features/student/shared/widgets/student_shell.dart floz_mobile/lib/features/teacher/shared/widgets/teacher_shell.dart && git commit -m "refactor(mobile/shells): consume tab index via StateProvider for deep linking"
  ```

---

### Task 5: Riverpod providers

**Why this is a separate task from the bell widget:** the bell needs to import `NotificationsScreen`, which doesn't exist until Task 6. So Task 5 = providers only; bell + screen ship together in Task 6.

**Files:**
- Create: `floz_mobile/lib/features/shared/notifications/providers/notifications_providers.dart`

**Providers spec:**

```dart
// notifications_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/notifications_remote_datasource.dart';
import '../data/repositories/notifications_repository_impl.dart';
import '../domain/entities/notifications_page.dart';
import '../domain/repositories/notifications_repository.dart';

final notificationsRemoteProvider = Provider<NotificationsRemoteDataSource>((ref) {
  return NotificationsRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(remote: ref.watch(notificationsRemoteProvider));
});

final notificationsPageProvider = FutureProvider<NotificationsPage>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  final result = await repo.fetch();
  return switch (result) {
    Success(:final data) => data,
    FailureResult(:final failure) => throw failure,
  };
});

/// Convenience provider: unread count for the bell badge.
/// Returns 0 while loading or on error — bell stays clean rather than showing stale.
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsPageProvider).maybeWhen(
        data: (page) => page.unreadCount,
        orElse: () => 0,
      );
});
```

**Steps:**
- [ ] **5.1 Create providers file** with the spec above.
- [ ] **5.2 flutter analyze** on the providers file. Must be clean (depends only on existing data layer + auth providers — both already in place after Task 3).
- [ ] **5.3 Commit:**
  ```bash
  cd /Users/tokaf/Floz_SDN_KELAPADUA_IV && git add floz_mobile/lib/features/shared/notifications/providers && git commit -m "feat(mobile/notifications): Riverpod providers (page + unread count)"
  ```

---

### Task 6: NotificationsScreen + NotificationBell + widget tests

**Files:**
- Create: `floz_mobile/lib/features/shared/notifications/presentation/screens/notifications_screen.dart`
- Create: `floz_mobile/lib/features/shared/notifications/presentation/widgets/notification_bell.dart` (the version from Task 5 spec above)
- Create: `floz_mobile/test/features/shared/notifications/presentation/screens/notifications_screen_test.dart`

**`NotificationsScreen` spec:**

```dart
// notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../auth/providers/auth_providers.dart';
import '../../../../student/shared/providers/student_tab_providers.dart';
import '../../../../teacher/shared/providers/teacher_tab_providers.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/entities/notifications_page.dart';
import '../../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(notificationsPageProvider);
    try {
      await ref.read(notificationsPageProvider.future);
    } catch (_) {
      /* ignore — error UI is shown by the AsyncValue branch */
    }
  }

  Future<void> _markAllAsRead(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(notificationsRepositoryProvider);
    await repo.markAllAsRead();
    ref.invalidate(notificationsPageProvider);
  }

  void _onTapNotification(BuildContext context, WidgetRef ref, NotificationItem n) async {
    if (!n.isRead) {
      // fire-and-forget mark-as-read; UI will refresh on next provider read
      ref.read(notificationsRepositoryProvider).markAsRead(n.id);
      ref.invalidate(notificationsPageProvider);
    }

    final action = n.action;
    if (action == null) {
      Navigator.of(context).pop();
      return;
    }

    final role = ref.read(authSessionProvider).user?.role;
    Navigator.of(context).pop();

    switch (action.screen) {
      case 'grades':
        if (role == 'student') {
          ref.read(studentSelectedTabProvider.notifier).state = 2; // Nilai
        }
        break;
      case 'announcement_detail':
        if (role == 'student') {
          ref.read(studentSelectedTabProvider.notifier).state = 4; // Info
        }
        break;
      case 'assignments':
        if (role == 'student') {
          ref.read(studentSelectedTabProvider.notifier).state = 5; // Tugas
        } else if (role == 'teacher') {
          ref.read(teacherSelectedTabProvider.notifier).state = 1; // Nilai (input)
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPage = ref.watch(notificationsPageProvider);
    final unread = asyncPage.maybeWhen(data: (p) => p.unreadCount, orElse: () => 0);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.slate200,
        foregroundColor: AppColors.slate900,
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 16, fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => _markAllAsRead(context, ref),
              child: const Text(
                'Tandai semua dibaca',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.primary600,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary600,
        onRefresh: () => _refresh(ref),
        child: asyncPage.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary600),
          ),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              ErrorState(
                message: err is Failure ? err.message : 'Gagal memuat notifikasi',
                onRetry: () => ref.invalidate(notificationsPageProvider),
              ),
            ],
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                  FlozCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 48, color: AppColors.slate400),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada notifikasi.',
                          style: TextStyle(
                            fontSize: 14, color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: page.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _NotificationCard(
                item: page.items[i],
                onTap: () => _onTapNotification(context, ref, page.items[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});
  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRead = item.isRead;
    return Material(
      color: isRead ? Colors.white : AppColors.primary50,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
            border: Border.all(
              color: isRead ? AppColors.slate100 : AppColors.primary100,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: isRead ? AppColors.slate100 : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                ),
                child: Icon(
                  _iconFor(item.icon),
                  size: 20,
                  color: AppColors.primary600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.slate900, height: 1.3,
                      ),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: const TextStyle(
                        fontSize: 12, color: AppColors.slate600, height: 1.4,
                      ),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(item.createdAt),
                      style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(top: 4, left: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary600,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'star': return Icons.star_rounded;
      case 'campaign': return Icons.campaign_rounded;
      case 'assignment': return Icons.assignment_rounded;
      case 'event_busy': return Icons.event_busy_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
```

**`NotificationBell` widget:**

```dart
// notification_bell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../screens/notifications_screen.dart';
import '../../providers/notifications_providers.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        },
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.slate200, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.slate900.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, size: 20, color: AppColors.slate700),
              if (unread > 0)
                Positioned(
                  top: -6, right: -8,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.danger600,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: Colors.white, height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Widget tests (3, mocktail):**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/shared/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:floz_mobile/features/shared/notifications/domain/entities/notification_item.dart';
import 'package:floz_mobile/features/shared/notifications/domain/entities/notifications_page.dart';
import 'package:floz_mobile/features/shared/notifications/domain/repositories/notifications_repository.dart';
import 'package:floz_mobile/features/shared/notifications/presentation/screens/notifications_screen.dart';
import 'package:floz_mobile/features/shared/notifications/providers/notifications_providers.dart';
import 'package:mocktail/mocktail.dart';

class _FakeRepo extends Mock implements NotificationsRepository {}

void main() {
  late _FakeRepo repo;

  setUp(() {
    repo = _FakeRepo();
  });

  Widget _wrap() {
    return ProviderScope(
      overrides: [notificationsRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: NotificationsScreen()),
    );
  }

  testWidgets('shows list with read/unread distinction', (tester) async {
    when(() => repo.fetch()).thenAnswer((_) async => Success(NotificationsPage(
          items: [
            NotificationItem(
              id: '1', type: 'grade', title: 'Nilai Baru',
              body: 'Matematika: 85', icon: 'star',
              createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
              readAt: null,
            ),
            NotificationItem(
              id: '2', type: 'announcement', title: 'Pengumuman',
              body: 'Libur besok', icon: 'campaign',
              createdAt: DateTime.now().subtract(const Duration(hours: 2)),
              readAt: DateTime.now(),
            ),
          ],
          currentPage: 1, lastPage: 1, total: 2, unreadCount: 1,
        )));

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('Nilai Baru'), findsOneWidget);
    expect(find.text('Pengumuman'), findsOneWidget);
    expect(find.text('Tandai semua dibaca'), findsOneWidget);
  });

  testWidgets('shows empty state when no notifications', (tester) async {
    when(() => repo.fetch()).thenAnswer((_) async => Success(const NotificationsPage(
          items: [],
          currentPage: 1, lastPage: 1, total: 0, unreadCount: 0,
        )));

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('Belum ada notifikasi.'), findsOneWidget);
    expect(find.text('Tandai semua dibaca'), findsNothing);
  });

  testWidgets('mark-all-as-read button calls repo and refreshes', (tester) async {
    when(() => repo.fetch()).thenAnswer((_) async => Success(NotificationsPage(
          items: [
            NotificationItem(
              id: '1', type: 'grade', title: 'Nilai',
              body: 'X', icon: 'star',
              createdAt: DateTime.now(),
            ),
          ],
          currentPage: 1, lastPage: 1, total: 1, unreadCount: 1,
        )));
    when(() => repo.markAllAsRead()).thenAnswer((_) async => const Success(1));

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tandai semua dibaca'));
    await tester.pumpAndSettle();

    verify(() => repo.markAllAsRead()).called(1);
  });
}
```

**Steps:**
- [ ] **6.1 Create `NotificationsScreen`** per spec.
- [ ] **6.2 Create `NotificationBell`** widget per spec from Task 5.
- [ ] **6.3 Write 3 widget tests** per spec.
- [ ] **6.4 Run tests** — `cd floz_mobile && flutter test test/features/shared/notifications/presentation/`. Expect 3/3 pass.
- [ ] **6.5 flutter analyze** — clean.
- [ ] **6.6 Commit:**
  ```bash
  cd /Users/tokaf/Floz_SDN_KELAPADUA_IV && git add floz_mobile/lib/features/shared/notifications/presentation floz_mobile/test/features/shared/notifications/presentation && git commit -m "feat(mobile/notifications): NotificationsScreen + NotificationBell + widget tests"
  ```

---

### Task 7: Wire NotificationBell into student + teacher top bars

**Files (modify):**
- `floz_mobile/lib/features/student/dashboard/presentation/screens/dashboard_screen.dart` (insert bell into existing `_TopBar` Row, left of profile button)
- `floz_mobile/lib/features/teacher/classes/presentation/screens/classes_list_screen.dart` (insert bell into existing `_TopBar` Row, left of profile button)

**Approach:** Both files have a `_TopBar` widget with structure `Row → [Spacer, _ProfileButton]`. Insert `NotificationBell` between them: `Row → [Spacer, NotificationBell, SizedBox(width: 10), _ProfileButton]`.

**Edit pattern (apply to BOTH files):**

In each file, find the `_TopBar.build()` method (look for `Row(children: [const Spacer(), _ProfileButton(...)])`). Replace with:

```dart
Row(
  children: [
    const Spacer(),
    const NotificationBell(),
    const SizedBox(width: 10),
    _ProfileButton(initials: _initialsOf(name)),
  ],
),
```

Also add the import at top of each file:
```dart
import '../../../../shared/notifications/presentation/widgets/notification_bell.dart';
```

(Adjust `../` count for relative path — `dashboard_screen.dart` is at `lib/features/student/dashboard/presentation/screens/`, so 5 levels up to `lib/`, then back into `features/shared/notifications/presentation/widgets/notification_bell.dart` → `../../../../shared/notifications/presentation/widgets/notification_bell.dart`. Verify by inspecting the existing relative imports in each file.)

**Steps:**
- [ ] **7.1 Read both files** to find current `_TopBar.build()` Row.
- [ ] **7.2 Modify `dashboard_screen.dart`** — add import + insert NotificationBell into _TopBar Row.
- [ ] **7.3 Modify `classes_list_screen.dart`** — same.
- [ ] **7.4 flutter analyze** — clean.
- [ ] **7.5 Run existing tests** — `flutter test test/features/student/ test/features/teacher/`. All must still pass (the bell is purely additive). The dashboard_screen_test will need to override `notificationsRepositoryProvider` since the bell reads `unreadCountProvider` → `notificationsPageProvider`. Match the existing pattern of overriding `coursesRepositoryProvider` already in that test file.
- [ ] **7.6 Commit:**
  ```bash
  cd /Users/tokaf/Floz_SDN_KELAPADUA_IV && git add floz_mobile/lib/features/student/dashboard/presentation/screens/dashboard_screen.dart floz_mobile/lib/features/teacher/classes/presentation/screens/classes_list_screen.dart floz_mobile/test/features/student/dashboard/presentation/screens/dashboard_screen_test.dart && git commit -m "feat(mobile/shells): wire NotificationBell into student + teacher top bars"
  ```

(If any existing test files break, modify them in this same commit.)

---

### Task 8: Integration regression + manual smoke test + tag

**Steps:**
- [ ] **8.1 Backend regression** — `cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src && php artisan test --env=testing 2>&1 | tail -10`. Expect previous + 9 (5 unit + 4 feature). Confirm count.
- [ ] **8.2 Mobile regression** — `cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile && flutter test 2>&1 | tail -10`. Expect previous + 7 (4 repo + 3 widget). Confirm count.
- [ ] **8.3 Smoke test via curl** — get a student token via tinker, then:
  ```bash
  TOKEN=...
  # Seed a notification first via tinker if dev DB is empty
  curl -s -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8000/api/v1/notifications | python3 -m json.tool
  ```
  Confirm response has `data` array + `meta.unread_count`.
- [ ] **8.4 Tag** — `cd /Users/tokaf/Floz_SDN_KELAPADUA_IV && git tag notifications-feed-complete && git push origin notifications-feed-complete`.
- [ ] **8.5 Verify tag** — `git tag -l '*notif*'`. Should show.

---

## Notes for executing agent

- **Safety:** NEVER run `migrate:fresh` or any migration command. Tests use `RefreshDatabase`. Always `--env=testing`.
- **Existing notification dispatch is sparse** — only `GradePostedNotification` (via `GradeController`) and `NewAssignmentNotification` (via `TeachingAssignmentController`) actually fire. `NewAnnouncementNotification` is commented out. For testing, the test files create notifications directly via `$user->notifications()->create([...])` which is the same path Laravel uses internally — bypasses the un-fired dispatch.
- **`Str::uuid()`** requires `use Illuminate\Support\Str;` at top of test files OR use the global `\Str::uuid()->toString()`.
- **`User::class`** in `notifiable_type` filter (Task 1 service) — Laravel uses the FQCN by default. Verify by inspecting an existing notification row via tinker if unsure.
- **`auth:sanctum` group in routes** — find the existing block in `src/routes/api.php`. The notifications routes go inside it but in their own `role:student,teacher` sub-group. Don't accidentally put them inside the existing `role:student` or `role:teacher` blocks.
- **Tab refactor (Task 4) MUST come before screen wiring (Task 6)** — the screen reads the tab providers. Order matters.
- **`maybeWhen` on AsyncValue** — `data: (...) => ..., orElse: () => ...` is the right pattern for `unreadCountProvider`. Returns 0 during load/error.
- **`Future<void>` Result pattern** — `Future<Result<void>> markAsRead(...)`. The `void` Result needs to be `const Success(null)` or `Success<void>(null)`. Verify by reading `auth_repository_impl.dart` line 48 (`return const Success(null);`).
- **Existing patterns to mirror exactly:**
  - Backend service → `CoursesService.php`
  - Backend controller → `MobileStudentCoursesController.php`
  - Backend feature test → `CoursesTest.php`
  - Mobile data layer → `floz_mobile/lib/features/student/courses/`
  - Mobile widget tests → `course_detail_screen_test.dart`
- **`Result<int>` for markAllAsRead** — that's a non-void Result, easy.
- **Snackbar in widget tests** — the snackbar shown after `_markAllAsRead` may interfere with assertions. The provided test asserts the verify call, not snackbar text — should be fine.
- **Widget tests for the bell itself** — out of scope for v1. The bell is small + tested implicitly via NotificationsScreen tap. Add later if it becomes important.
