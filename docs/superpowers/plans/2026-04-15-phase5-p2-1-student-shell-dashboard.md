# Phase 5 — P2.1 Student Shell + Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a working Student Shell (bottom-nav with 6 tabs, 5 placeholder, 1 live) and a fully refactored Dashboard slice (backend V1 endpoint + mobile screen with Hive cache) — so a student can log in and see real dashboard data.

**Architecture:** Backend splits the legacy role-branching `/api/v1/dashboard` into a role-scoped `/api/v1/student/dashboard` using thin controller → FormRequest → Service → Resource pattern (same as auth P1). Mobile rebuilds `features/student/dashboard` from scratch using clean architecture (data/domain/presentation/providers) with a sealed `Result<T>` and 5-minute Hive cache. A `StudentShell` widget replaces the P1 router placeholder and hosts all 6 student tabs.

**Tech Stack:**
- **Backend:** PHP 8.2, Laravel 12, Sanctum 4.3, Pest 3, Postgres 16
- **Mobile:** Flutter 3.11+, Riverpod 2, go_router 17, Dio 5, Hive 2, mocktail
- **Contract:** `docs/api/CONTRACT.md` (locked in P1)

**Spec source:** `docs/superpowers/specs/2026-04-15-phase5-rest-api-mobile-design.md` (Slice #1 Dashboard-student)

---

## Key Decisions

1. **Endpoint path:** `/api/v1/student/dashboard` (NOT `/api/v1/dashboard`). Legacy `/dashboard` route is removed. Teacher dashboard comes in P3 as `/api/v1/teacher/dashboard`.
2. **Role guard:** `role:student` middleware — only students can hit this endpoint. Teacher/admin/parent → 403.
3. **Response shape:** Preserve the existing student fields (student profile, stats.attendance_percentage, todays_schedules, recent_announcements) but wrap in `{data: {...}}` envelope per contract.
4. **Attendance status fix:** Existing controller queries `status='present'` but factory + DB use `status='hadir'`. **This is a bug.** Fix to `hadir`.
5. **Student shell:** `ConsumerStatefulWidget` with `IndexedStack` + `BottomNavigationBar`. 6 tabs, Indonesian labels. Dashboard tab = real screen; other 5 = `_TabPlaceholder` widgets.
6. **Cache:** Hive box `dashboard_cache` with 5-min TTL. Repository returns `Success(data)` on fresh, `Success(data, stale=true)` on network-fail with cached data, `FailureResult(NetworkFailure)` on network-fail with empty cache.
7. **Seeding for manual test:** A dev tinker command seeds a Student + SchoolClass + Schedule + Announcement for `student@floz.test` so the UI shows non-empty data. Not part of automated tests.

---

## File Structure

### Backend — files to create
```
src/app/Http/Controllers/Api/V1/MobileDashboardController.php
src/app/Services/Mobile/DashboardService.php
src/app/Http/Resources/Api/V1/DashboardResource.php
src/tests/Feature/Api/V1/Student/DashboardTest.php
src/tests/Unit/Services/Mobile/DashboardServiceTest.php
```

### Backend — files to modify
```
src/routes/api.php
```

### Backend — files to delete
```
src/app/Http/Controllers/Api/MobileDashboardController.php
```

### Mobile — files to delete (broken pre-P1 code)
```
floz_mobile/lib/features/student/dashboard/   (recursively — all files inside)
```

### Mobile — files to create
```
floz_mobile/lib/features/student/dashboard/domain/entities/dashboard.dart
floz_mobile/lib/features/student/dashboard/domain/repositories/dashboard_repository.dart
floz_mobile/lib/features/student/dashboard/data/models/dashboard_dto.dart
floz_mobile/lib/features/student/dashboard/data/datasources/dashboard_remote_datasource.dart
floz_mobile/lib/features/student/dashboard/data/repositories/dashboard_repository_impl.dart
floz_mobile/lib/features/student/dashboard/providers/dashboard_providers.dart
floz_mobile/lib/features/student/dashboard/presentation/screens/dashboard_screen.dart
floz_mobile/lib/features/student/shared/widgets/student_shell.dart
floz_mobile/lib/features/student/shared/widgets/tab_placeholder.dart
floz_mobile/test/features/student/dashboard/data/repositories/dashboard_repository_impl_test.dart
floz_mobile/test/features/student/dashboard/presentation/screens/dashboard_screen_test.dart
```

### Mobile — files to modify
```
floz_mobile/lib/core/router/app_router.dart
floz_mobile/lib/core/network/api_endpoints.dart
```

---

## Tasks

### Task 1: Write failing DashboardService unit test

**Files:**
- Create: `src/tests/Unit/Services/Mobile/DashboardServiceTest.php`

- [ ] **Step 1: Create the test file**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/tests/Unit/Services/Mobile/DashboardServiceTest.php`:

```php
<?php

use App\Models\Announcement;
use App\Models\Attendance;
use App\Models\Schedule;
use App\Models\Student;
use App\Models\TeachingAssignment;
use App\Models\User;
use App\Services\Mobile\DashboardService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new DashboardService();
});

it('returns student profile with class and homeroom teacher', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    $data = $this->service->forStudent($user);

    expect($data['role'])->toBe('student');
    expect($data['student'])->toMatchArray([
        'id' => $student->id,
        'name' => $student->name,
    ]);
    expect($data['student']['class'])->not->toBeNull();
    expect($data)->toHaveKeys(['stats', 'todays_schedules', 'recent_announcements']);
});

it('calculates attendance percentage from hadir records', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    // 4 hadir + 1 alpha = 80%
    Attendance::factory()->count(4)->create([
        'student_id' => $student->id,
        'class_id' => $student->class_id,
        'status' => 'hadir',
    ]);
    Attendance::factory()->create([
        'student_id' => $student->id,
        'class_id' => $student->class_id,
        'status' => 'alpha',
    ]);

    $data = $this->service->forStudent($user);

    expect($data['stats']['attendance_percentage'])->toBe(80);
});

it('returns attendance_percentage 0 when no records exist', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    $data = $this->service->forStudent($user);

    expect($data['stats']['attendance_percentage'])->toBe(0);
});

it('returns empty todays_schedules when student has no class_id', function () {
    $student = Student::factory()->create(['class_id' => null]);
    $user = User::where('email', $student->email)->first();

    $data = $this->service->forStudent($user);

    expect($data['todays_schedules'])->toBe([]);
});

it('returns at most 5 recent published announcements ordered by newest', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    // Create 7 published + 2 unpublished
    Announcement::factory()->count(7)->create(['is_published' => true]);
    Announcement::factory()->count(2)->create(['is_published' => false]);

    $data = $this->service->forStudent($user);

    expect($data['recent_announcements'])->toHaveCount(5);
});

it('trims announcement content to 120 chars and strips HTML', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    Announcement::factory()->create([
        'is_published' => true,
        'content' => '<p>' . str_repeat('a', 200) . '</p>',
    ]);

    $data = $this->service->forStudent($user);

    $content = $data['recent_announcements'][0]['content'];
    expect(strlen($content))->toBeLessThanOrEqual(124); // 120 + "..."
    expect($content)->not->toContain('<p>');
});
```

- [ ] **Step 2: Run test, confirm it fails**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest tests/Unit/Services/Mobile/DashboardServiceTest.php
```

Expected: FAIL with `Class "App\Services\Mobile\DashboardService" not found`.

---

### Task 2: Implement DashboardService

**Files:**
- Create: `src/app/Services/Mobile/DashboardService.php`

- [ ] **Step 1: Create DashboardService**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Services/Mobile/DashboardService.php`:

```php
<?php

namespace App\Services\Mobile;

use App\Models\Announcement;
use App\Models\Attendance;
use App\Models\Schedule;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;

class DashboardService
{
    /**
     * Build dashboard payload for an authenticated student.
     *
     * @return array{
     *     role: string,
     *     student: array{id:int,name:string,class:?string,homeroom_teacher:?string}|null,
     *     stats: array{attendance_percentage:int},
     *     todays_schedules: array<int, array<string,mixed>>,
     *     recent_announcements: array<int, array<string,mixed>>
     * }
     */
    public function forStudent(User $user): array
    {
        $student = $user->student()->with(['class.homeroomTeacher'])->first();
        $today = Carbon::today();
        $dayOfWeek = $today->dayOfWeekIso;

        $stats = ['attendance_percentage' => 0];
        $todaysSchedules = [];

        if ($student) {
            $total = Attendance::where('student_id', $student->id)->count();
            $present = Attendance::where('student_id', $student->id)
                ->where('status', 'hadir')
                ->count();
            $stats['attendance_percentage'] = $total > 0
                ? (int) round(($present / $total) * 100)
                : 0;

            if ($student->class_id) {
                $todaysSchedules = Schedule::where('day_of_week', $dayOfWeek)
                    ->whereHas('teachingAssignment', fn ($q) => $q->where('class_id', $student->class_id))
                    ->with(['teachingAssignment.subject', 'teachingAssignment.teacher'])
                    ->orderBy('start_time')
                    ->get()
                    ->map(fn ($s) => [
                        'id' => $s->id,
                        'start_time' => $s->start_time,
                        'end_time' => $s->end_time,
                        'subject' => $s->teachingAssignment->subject->name ?? '-',
                        'teacher' => $s->teachingAssignment->teacher->name ?? '-',
                    ])
                    ->toArray();
            }
        }

        $recentAnnouncements = Announcement::where('is_published', true)
            ->latest()
            ->take(5)
            ->get()
            ->map(fn ($a) => [
                'id' => $a->id,
                'title' => $a->title,
                'content' => Str::limit(strip_tags($a->content), 120),
                'created_at' => $a->created_at->toIso8601String(),
            ])
            ->toArray();

        return [
            'role' => 'student',
            'student' => $student ? [
                'id' => $student->id,
                'name' => $student->name,
                'class' => $student->class?->name,
                'homeroom_teacher' => $student->class?->homeroomTeacher?->name,
            ] : null,
            'stats' => $stats,
            'todays_schedules' => $todaysSchedules,
            'recent_announcements' => $recentAnnouncements,
        ];
    }
}
```

- [ ] **Step 2: Run test, confirm pass**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest tests/Unit/Services/Mobile/DashboardServiceTest.php
```

Expected: PASS (6 tests). If a test fails because a relation or column doesn't match the actual schema, read the relevant model/migration and adjust the Service or test assertions.

- [ ] **Step 3: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add src/app/Services/Mobile/DashboardService.php \
        src/tests/Unit/Services/Mobile/DashboardServiceTest.php
git commit -m "feat(api/v1): add DashboardService for student dashboard"
```

---

### Task 3: Create DashboardResource

**Files:**
- Create: `src/app/Http/Resources/Api/V1/DashboardResource.php`

- [ ] **Step 1: Create the resource**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Http/Resources/Api/V1/DashboardResource.php`:

```php
<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DashboardResource extends JsonResource
{
    /**
     * The resource wraps the service-built array as-is.
     * Instantiation: new DashboardResource($serviceArray).
     */
    public function toArray(Request $request): array
    {
        // Resource receives the plain array from DashboardService; return it untouched.
        return (array) $this->resource;
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add src/app/Http/Resources/Api/V1/DashboardResource.php
git commit -m "feat(api/v1): add DashboardResource (passthrough envelope)"
```

---

### Task 4: Write failing V1 dashboard feature test

**Files:**
- Create: `src/tests/Feature/Api/V1/Student/DashboardTest.php`

- [ ] **Step 1: Create feature test**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/tests/Feature/Api/V1/Student
```

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/tests/Feature/Api/V1/Student/DashboardTest.php`:

```php
<?php

use App\Models\Announcement;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('returns dashboard data wrapped in envelope for authenticated student', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    Announcement::factory()->count(3)->create(['is_published' => true]);

    $token = $user->createToken('mobile')->plainTextToken;

    $response = $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/dashboard');

    $response->assertOk()
        ->assertJsonStructure([
            'data' => [
                'role',
                'student' => ['id', 'name', 'class'],
                'stats' => ['attendance_percentage'],
                'todays_schedules',
                'recent_announcements',
            ],
        ])
        ->assertJsonPath('data.role', 'student')
        ->assertJsonPath('data.student.id', $student->id);
});

it('returns 401 without a token', function () {
    $this->getJson('/api/v1/student/dashboard')->assertUnauthorized();
});

it('returns 403 for teacher token', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/dashboard')
        ->assertForbidden();
});
```

- [ ] **Step 2: Run test, confirm it fails**

```bash
./vendor/bin/pest tests/Feature/Api/V1/Student/DashboardTest.php
```

Expected: FAIL with 404 (route not registered) or class-not-found for the controller.

---

### Task 5: Implement V1 MobileDashboardController + register route

**Files:**
- Create: `src/app/Http/Controllers/Api/V1/MobileDashboardController.php`
- Modify: `src/routes/api.php`

- [ ] **Step 1: Create V1 controller**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Http/Controllers/Api/V1
```

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Http/Controllers/Api/V1/MobileDashboardController.php`:

```php
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\DashboardResource;
use App\Services\Mobile\DashboardService;
use Illuminate\Http\Request;

class MobileDashboardController extends Controller
{
    public function __construct(private readonly DashboardService $service) {}

    /**
     * @OA\Get(
     *     path="/api/v1/student/dashboard",
     *     tags={"Student"},
     *     summary="Dashboard siswa",
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(response=200, description="Dashboard data"),
     *     @OA\Response(response=401, description="Token tidak valid"),
     *     @OA\Response(response=403, description="Bukan siswa"),
     * )
     */
    public function index(Request $request)
    {
        $data = $this->service->forStudent($request->user());

        return response()->json([
            'data' => (new DashboardResource($data))->resolve(),
        ]);
    }
}
```

- [ ] **Step 2: Register route**

Edit `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/routes/api.php`. Make these changes:

1. Change line 4 from:
```php
use App\Http\Controllers\Api\MobileDashboardController;
```
to:
```php
use App\Http\Controllers\Api\V1\MobileDashboardController;
```

2. Inside the `['auth:sanctum', 'throttle:mobile-api']` middleware group, replace the line:
```php
Route::get('/dashboard', [MobileDashboardController::class, 'index']);
```
with:
```php
Route::middleware('role:student')->group(function () {
    Route::get('/student/dashboard', [MobileDashboardController::class, 'index']);
});
```

- [ ] **Step 3: Run feature test, confirm pass**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest tests/Feature/Api/V1/Student/DashboardTest.php
```

Expected: PASS (3 tests).

- [ ] **Step 4: Run full regression**

```bash
./vendor/bin/pest
```

Expected: All previous tests still pass. Total should be ~74 tests (71 from P1 + 3 new feature + 6 new unit).

- [ ] **Step 5: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add src/app/Http/Controllers/Api/V1/MobileDashboardController.php \
        src/routes/api.php \
        src/tests/Feature/Api/V1/Student/DashboardTest.php
git commit -m "feat(api/v1): add student dashboard endpoint with role guard"
```

---

### Task 6: Delete legacy MobileDashboardController

**Files:**
- Delete: `src/app/Http/Controllers/Api/MobileDashboardController.php`

- [ ] **Step 1: Confirm the new route works, old file is unused**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan route:list --path=api/v1 2>&1 | grep -i dashboard
```

Expected: one line showing `GET api/v1/student/dashboard → Api\V1\MobileDashboardController@index`. No `/api/v1/dashboard` route anymore.

- [ ] **Step 2: Grep for any remaining references**

Use the Grep tool with pattern `App\\Http\\Controllers\\Api\\MobileDashboardController` across `src/`.

Expected: 0 matches.

- [ ] **Step 3: Delete the file**

```bash
rm /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Http/Controllers/Api/MobileDashboardController.php
```

- [ ] **Step 4: Run full regression**

```bash
./vendor/bin/pest
```

Expected: Still all green.

- [ ] **Step 5: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add -A src/app/Http/Controllers/Api/
git commit -m "refactor(api): remove legacy Api\\MobileDashboardController"
```

---

### Task 7: Delete pre-P1 broken mobile dashboard code

**Files:**
- Delete: `floz_mobile/lib/features/student/dashboard/` (entire directory, recursive)

- [ ] **Step 1: Inspect what's in the dashboard dir**

```bash
find /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/dashboard -type f | sed -n '1,20p'
```

Note the files. These are broken pre-P1 code (uses old `ApiClient.dio.get()` and references deleted `StorageService`).

- [ ] **Step 2: Delete the directory**

```bash
rm -rf /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/dashboard
```

- [ ] **Step 3: Flutter analyze baseline**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze lib/ 2>&1 | grep -c "error •"
```

Expected: Error count DECREASES from 29 to some smaller number (since we just deleted ~5 broken files that had compile errors). Remember this new count for later comparison.

- [ ] **Step 4: Commit the deletion**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add -A floz_mobile/lib/features/student/dashboard
git commit -m "chore(mobile): remove pre-P1 broken dashboard code"
```

---

### Task 8: Create Dashboard domain layer (entity + repository interface)

**Files:**
- Create: `floz_mobile/lib/features/student/dashboard/domain/entities/dashboard.dart`
- Create: `floz_mobile/lib/features/student/dashboard/domain/repositories/dashboard_repository.dart`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/dashboard/domain/entities
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/dashboard/domain/repositories
```

- [ ] **Step 2: Create entities**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/dashboard/domain/entities/dashboard.dart`:

```dart
class StudentDashboard {
  final StudentDashboardProfile? student;
  final DashboardStats stats;
  final List<ScheduleItem> todaysSchedules;
  final List<AnnouncementSummary> recentAnnouncements;

  const StudentDashboard({
    required this.student,
    required this.stats,
    required this.todaysSchedules,
    required this.recentAnnouncements,
  });
}

class StudentDashboardProfile {
  final int id;
  final String name;
  final String? className;
  final String? homeroomTeacher;

  const StudentDashboardProfile({
    required this.id,
    required this.name,
    required this.className,
    required this.homeroomTeacher,
  });
}

class DashboardStats {
  final int attendancePercentage;

  const DashboardStats({required this.attendancePercentage});
}

class ScheduleItem {
  final int id;
  final String startTime;
  final String endTime;
  final String subject;
  final String teacher;

  const ScheduleItem({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacher,
  });
}

class AnnouncementSummary {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;

  const AnnouncementSummary({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });
}
```

- [ ] **Step 3: Create repository interface**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/dashboard/domain/repositories/dashboard_repository.dart`:

```dart
import '../../../../../core/error/result.dart';
import '../entities/dashboard.dart';

abstract class DashboardRepository {
  Future<Result<StudentDashboard>> fetch({bool forceRefresh = false});
}
```

- [ ] **Step 4: Flutter analyze**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze lib/features/student/dashboard/domain/ 2>&1 | tail -10
```

Expected: No issues.

- [ ] **Step 5: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add floz_mobile/lib/features/student/dashboard/domain/
git commit -m "feat(mobile/dashboard): add Dashboard entity and repository interface"
```

---

### Task 9: Create Dashboard DTO + remote datasource

**Files:**
- Create: `floz_mobile/lib/features/student/dashboard/data/models/dashboard_dto.dart`
- Create: `floz_mobile/lib/features/student/dashboard/data/datasources/dashboard_remote_datasource.dart`
- Modify: `floz_mobile/lib/core/network/api_endpoints.dart`

- [ ] **Step 1: Add endpoint constant**

Edit `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/core/network/api_endpoints.dart`:

Add below `authMe`:

```dart
  static const String studentDashboard = '/student/dashboard';
```

Full file after edit:

```dart
class ApiEndpoints {
  ApiEndpoints._();

  static const String authLogin  = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authMe     = '/auth/me';

  static const String studentDashboard = '/student/dashboard';
}
```

- [ ] **Step 2: Create data directory**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/dashboard/data/models
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/dashboard/data/datasources
```

- [ ] **Step 3: Create DashboardDto**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/dashboard/data/models/dashboard_dto.dart`:

```dart
import '../../domain/entities/dashboard.dart';

class DashboardDto {
  static StudentDashboard fromJson(Map<String, dynamic> json) {
    final studentJson = json['student'];
    final statsJson = (json['stats'] as Map<String, dynamic>?) ?? const {};
    final schedules = (json['todays_schedules'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_scheduleFromJson)
        .toList(growable: false);
    final announcements = (json['recent_announcements'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_announcementFromJson)
        .toList(growable: false);

    return StudentDashboard(
      student: studentJson is Map<String, dynamic> ? _profileFromJson(studentJson) : null,
      stats: DashboardStats(
        attendancePercentage: (statsJson['attendance_percentage'] as num? ?? 0).toInt(),
      ),
      todaysSchedules: schedules,
      recentAnnouncements: announcements,
    );
  }

  static StudentDashboardProfile _profileFromJson(Map<String, dynamic> json) {
    return StudentDashboardProfile(
      id: json['id'] as int,
      name: json['name'] as String? ?? '-',
      className: json['class'] as String?,
      homeroomTeacher: json['homeroom_teacher'] as String?,
    );
  }

  static ScheduleItem _scheduleFromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] as int,
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '-',
      teacher: json['teacher']?.toString() ?? '-',
    );
  }

  static AnnouncementSummary _announcementFromJson(Map<String, dynamic> json) {
    return AnnouncementSummary(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
```

- [ ] **Step 4: Create DashboardRemoteDataSource**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/dashboard/data/datasources/dashboard_remote_datasource.dart`:

```dart
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/dashboard.dart';
import '../models/dashboard_dto.dart';

abstract class DashboardRemoteDataSource {
  Future<StudentDashboard> fetch();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient _client;

  DashboardRemoteDataSourceImpl(this._client);

  @override
  Future<StudentDashboard> fetch() async {
    final res = await _client.get(ApiEndpoints.studentDashboard);
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return DashboardDto.fromJson(data);
  }
}
```

- [ ] **Step 5: Flutter analyze**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze lib/features/student/dashboard/data/ lib/core/network/api_endpoints.dart 2>&1 | tail -10
```

Expected: No issues.

- [ ] **Step 6: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add floz_mobile/lib/features/student/dashboard/data/ \
        floz_mobile/lib/core/network/api_endpoints.dart
git commit -m "feat(mobile/dashboard): add DashboardDto and remote datasource"
```

---

### Task 10: Write failing repository test

**Files:**
- Create: `floz_mobile/test/features/student/dashboard/data/repositories/dashboard_repository_impl_test.dart`

- [ ] **Step 1: Create test directory**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/test/features/student/dashboard/data/repositories
```

- [ ] **Step 2: Write test**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/test/features/student/dashboard/data/repositories/dashboard_repository_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/core/storage/cache_box.dart';
import 'package:floz_mobile/features/student/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:floz_mobile/features/student/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:floz_mobile/features/student/dashboard/domain/entities/dashboard.dart';

class _MockRemote extends Mock implements DashboardRemoteDataSource {}
class _MockCache extends Mock implements CacheBox<dynamic> {}

StudentDashboard _fixture() => const StudentDashboard(
      student: StudentDashboardProfile(
        id: 1,
        name: 'Ahmad',
        className: '4A',
        homeroomTeacher: 'Bu Ani',
      ),
      stats: DashboardStats(attendancePercentage: 90),
      todaysSchedules: [],
      recentAnnouncements: [],
    );

Map<String, dynamic> _fixtureJson() => {
      'student': {'id': 1, 'name': 'Ahmad', 'class': '4A', 'homeroom_teacher': 'Bu Ani'},
      'stats': {'attendance_percentage': 90},
      'todays_schedules': [],
      'recent_announcements': [],
    };

void main() {
  late _MockRemote remote;
  late _MockCache cache;
  late DashboardRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    cache = _MockCache();
    repo = DashboardRepositoryImpl(remote: remote, cache: cache);
  });

  group('fetch', () {
    test('returns Success from remote and writes cache on happy path', () async {
      when(() => remote.fetch()).thenAnswer((_) async => _fixture());
      when(() => cache.put(any(), any())).thenAnswer((_) async {});
      when(() => cache.get(any())).thenAnswer((_) async => null);

      final result = await repo.fetch();

      expect(result, isA<Success<StudentDashboard>>());
      verify(() => cache.put('main', any())).called(1);
    });

    test('returns stale Success from cache when remote throws NetworkException', () async {
      when(() => remote.fetch()).thenThrow(const NetworkException('offline'));
      when(() => cache.getStale(any())).thenAnswer((_) async => _fixtureJson());

      final result = await repo.fetch();

      expect(result, isA<Success<StudentDashboard>>());
      expect((result as Success<StudentDashboard>).stale, isTrue);
    });

    test('returns NetworkFailure when remote throws and cache is empty', () async {
      when(() => remote.fetch()).thenThrow(const NetworkException('offline'));
      when(() => cache.getStale(any())).thenAnswer((_) async => null);

      final result = await repo.fetch();

      expect(result, isA<FailureResult<StudentDashboard>>());
      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });

    test('returns AuthFailure on 401', () async {
      when(() => remote.fetch()).thenThrow(const UnauthorizedException('expired'));

      final result = await repo.fetch();

      expect((result as FailureResult).failure, isA<AuthFailure>());
    });

    test('returns ServerFailure on 500', () async {
      when(() => remote.fetch()).thenThrow(const ServerException('boom'));

      final result = await repo.fetch();

      expect((result as FailureResult).failure, isA<ServerFailure>());
    });

    test('returns cached Success directly when cache is fresh', () async {
      when(() => cache.get(any())).thenAnswer((_) async => _fixtureJson());

      final result = await repo.fetch();

      expect(result, isA<Success<StudentDashboard>>());
      expect((result as Success<StudentDashboard>).stale, isFalse);
      verifyNever(() => remote.fetch());
    });

    test('bypasses cache when forceRefresh=true', () async {
      when(() => cache.get(any())).thenAnswer((_) async => _fixtureJson());
      when(() => remote.fetch()).thenAnswer((_) async => _fixture());
      when(() => cache.put(any(), any())).thenAnswer((_) async {});

      final result = await repo.fetch(forceRefresh: true);

      expect(result, isA<Success<StudentDashboard>>());
      verify(() => remote.fetch()).called(1);
    });
  });
}
```

- [ ] **Step 3: Run test, confirm fail**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter test test/features/student/dashboard/data/repositories/dashboard_repository_impl_test.dart
```

Expected: FAIL (`DashboardRepositoryImpl` not found).

---

### Task 11: Implement DashboardRepositoryImpl with cache

**Files:**
- Create: `floz_mobile/lib/features/student/dashboard/data/repositories/dashboard_repository_impl.dart`

- [ ] **Step 1: Create repositories dir**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/dashboard/data/repositories
```

- [ ] **Step 2: Implement repository**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/dashboard/data/repositories/dashboard_repository_impl.dart`:

```dart
import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/storage/cache_box.dart';
import '../../domain/entities/dashboard.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../models/dashboard_dto.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  static const _cacheKey = 'main';

  final DashboardRemoteDataSource _remote;
  final CacheBox<dynamic> _cache;

  DashboardRepositoryImpl({
    required DashboardRemoteDataSource remote,
    required CacheBox<dynamic> cache,
  })  : _remote = remote,
        _cache = cache;

  @override
  Future<Result<StudentDashboard>> fetch({bool forceRefresh = false}) async {
    // 1. Try fresh cache (unless forcing refresh)
    if (!forceRefresh) {
      final cached = await _cache.get(_cacheKey);
      if (cached is Map) {
        return Success(DashboardDto.fromJson(Map<String, dynamic>.from(cached)));
      }
    }

    // 2. Fetch from network
    try {
      final data = await _remote.fetch();
      await _cache.put(_cacheKey, _toJson(data));
      return Success(data);
    } on NetworkException catch (e) {
      // 3. Network failed — try stale cache as fallback
      final stale = await _cache.getStale(_cacheKey);
      if (stale is Map) {
        return Success(
          DashboardDto.fromJson(Map<String, dynamic>.from(stale)),
          stale: true,
        );
      }
      return FailureResult(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(ForbiddenFailure(e.message));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message, statusCode: e.statusCode));
    } on ApiException catch (e) {
      return FailureResult(ServerFailure(e.message));
    }
  }

  Map<String, dynamic> _toJson(StudentDashboard d) {
    return {
      'student': d.student == null
          ? null
          : {
              'id': d.student!.id,
              'name': d.student!.name,
              'class': d.student!.className,
              'homeroom_teacher': d.student!.homeroomTeacher,
            },
      'stats': {'attendance_percentage': d.stats.attendancePercentage},
      'todays_schedules': d.todaysSchedules
          .map((s) => {
                'id': s.id,
                'start_time': s.startTime,
                'end_time': s.endTime,
                'subject': s.subject,
                'teacher': s.teacher,
              })
          .toList(),
      'recent_announcements': d.recentAnnouncements
          .map((a) => {
                'id': a.id,
                'title': a.title,
                'content': a.content,
                'created_at': a.createdAt.toIso8601String(),
              })
          .toList(),
    };
  }
}
```

- [ ] **Step 3: Run test, confirm pass**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter test test/features/student/dashboard/data/repositories/dashboard_repository_impl_test.dart
```

Expected: PASS (7 tests).

If a test fails because the fixture JSON structure doesn't match what the DTO parses (e.g., missing field), adjust the fixture. Don't loosen the DTO parser unless there's a real reason.

- [ ] **Step 4: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add floz_mobile/lib/features/student/dashboard/data/repositories/ \
        floz_mobile/test/features/student/dashboard/data/repositories/
git commit -m "feat(mobile/dashboard): add DashboardRepositoryImpl with Hive cache"
```

---

### Task 12: Create Dashboard Riverpod providers

**Files:**
- Create: `floz_mobile/lib/features/student/dashboard/providers/dashboard_providers.dart`

- [ ] **Step 1: Create providers dir**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/dashboard/providers
```

- [ ] **Step 2: Implement providers**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/dashboard/providers/dashboard_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/cache_box.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/dashboard_remote_datasource.dart';
import '../data/repositories/dashboard_repository_impl.dart';
import '../domain/entities/dashboard.dart';
import '../domain/repositories/dashboard_repository.dart';

final dashboardCacheProvider = Provider<CacheBox<dynamic>>((ref) {
  return CacheBox<dynamic>(name: 'dashboard_cache', ttl: const Duration(minutes: 5));
});

final dashboardRemoteProvider = Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    remote: ref.watch(dashboardRemoteProvider),
    cache: ref.watch(dashboardCacheProvider),
  );
});

class DashboardNotifier extends AsyncNotifier<StudentDashboard> {
  @override
  Future<StudentDashboard> build() async {
    final result = await ref.read(dashboardRepositoryProvider).fetch();
    return _throwOrReturn(result);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await ref.read(dashboardRepositoryProvider).fetch(forceRefresh: true);
    state = await AsyncValue.guard(() async => _throwOrReturn(result));
  }

  StudentDashboard _throwOrReturn(Result<StudentDashboard> result) {
    switch (result) {
      case Success(:final data):
        return data;
      case FailureResult(:final failure):
        throw failure;
    }
  }
}

final dashboardNotifierProvider =
    AsyncNotifierProvider<DashboardNotifier, StudentDashboard>(DashboardNotifier.new);
```

- [ ] **Step 3: Flutter analyze**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze lib/features/student/dashboard/providers/ 2>&1 | tail -10
```

Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add floz_mobile/lib/features/student/dashboard/providers/
git commit -m "feat(mobile/dashboard): Riverpod providers for DashboardRepository + notifier"
```

---

### Task 13: Implement DashboardScreen UI

**Files:**
- Create: `floz_mobile/lib/features/student/dashboard/presentation/screens/dashboard_screen.dart`

- [ ] **Step 1: Create presentation dir**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/dashboard/presentation/screens
```

- [ ] **Step 2: Create DashboardScreen**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/dashboard/presentation/screens/dashboard_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../domain/entities/dashboard.dart';
import '../../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardNotifierProvider.notifier).refresh(),
        child: state.when(
          data: (dashboard) => _DashboardContent(dashboard: dashboard),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ErrorState(
            message: err is Failure ? err.message : 'Gagal memuat dashboard',
            onRetry: () => ref.read(dashboardNotifierProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final StudentDashboard dashboard;
  const _DashboardContent({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProfileCard(profile: dashboard.student),
        const SizedBox(height: 16),
        _AttendanceCard(percentage: dashboard.stats.attendancePercentage),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Jadwal Hari Ini'),
        const SizedBox(height: 8),
        if (dashboard.todaysSchedules.isEmpty)
          const _EmptyTile(message: 'Tidak ada jadwal hari ini.')
        else
          ...dashboard.todaysSchedules.map((s) => _ScheduleTile(item: s)),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Pengumuman Terbaru'),
        const SizedBox(height: 8),
        if (dashboard.recentAnnouncements.isEmpty)
          const _EmptyTile(message: 'Belum ada pengumuman.')
        else
          ...dashboard.recentAnnouncements.map((a) => _AnnouncementTile(item: a)),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final StudentDashboardProfile? profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Profil siswa belum tersedia.'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, ${profile!.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text('Kelas: ${profile!.className ?? '-'}'),
            if (profile!.homeroomTeacher != null)
              Text('Wali Kelas: ${profile!.homeroomTeacher}'),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final int percentage;
  const _AttendanceCard({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kehadiran'),
                  Text(
                    '$percentage%',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  final String message;
  const _EmptyTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final ScheduleItem item;
  const _ScheduleTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule),
      title: Text(item.subject),
      subtitle: Text('${item.startTime} – ${item.endTime} • ${item.teacher}'),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final AnnouncementSummary item;
  const _AnnouncementTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy', 'id_ID');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.campaign_outlined),
      title: Text(item.title),
      subtitle: Text(
        '${dateFmt.format(item.createdAt.toLocal())}\n${item.content}',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
    );
  }
}
```

- [ ] **Step 3: Flutter analyze**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze lib/features/student/dashboard/presentation/ 2>&1 | tail -10
```

Expected: No issues. If `intl` package is not importable, verify `intl: ^0.20.2` is in pubspec (it is, per P1 audit).

- [ ] **Step 4: Commit**

```bash
git add floz_mobile/lib/features/student/dashboard/presentation/
git commit -m "feat(mobile/dashboard): add DashboardScreen UI"
```

---

### Task 14: Widget test for DashboardScreen

**Files:**
- Create: `floz_mobile/test/features/student/dashboard/presentation/screens/dashboard_screen_test.dart`

- [ ] **Step 1: Write widget test**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/test/features/student/dashboard/presentation/screens
```

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/test/features/student/dashboard/presentation/screens/dashboard_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/student/dashboard/domain/entities/dashboard.dart';
import 'package:floz_mobile/features/student/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:floz_mobile/features/student/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:floz_mobile/features/student/dashboard/providers/dashboard_providers.dart';

class _MockRepo extends Mock implements DashboardRepository {}

const _fixture = StudentDashboard(
  student: StudentDashboardProfile(
    id: 1,
    name: 'Ahmad',
    className: '4A',
    homeroomTeacher: 'Bu Ani',
  ),
  stats: DashboardStats(attendancePercentage: 90),
  todaysSchedules: [],
  recentAnnouncements: [],
);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [dashboardRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows loading then data on happy path', (tester) async {
    when(() => repo.fetch(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(_fixture));

    await tester.pumpWidget(wrap(const DashboardScreen()));

    // Loading visible first
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Halo, Ahmad'), findsOneWidget);
    expect(find.text('Kelas: 4A'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('Tidak ada jadwal hari ini.'), findsOneWidget);
    expect(find.text('Belum ada pengumuman.'), findsOneWidget);
  });

  testWidgets('shows error state with retry on failure', (tester) async {
    when(() => repo.fetch(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const FailureResult(NetworkFailure('offline')));

    await tester.pumpWidget(wrap(const DashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('offline'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test, confirm pass**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter test test/features/student/dashboard/presentation/screens/dashboard_screen_test.dart
```

Expected: PASS (2 tests). Both the loading→data transition and the error state should work.

If the first test fails because the loading indicator isn't caught before data resolves, adjust:
```dart
// Before pumpAndSettle, the async value starts in loading immediately
await tester.pump(); // initial frame
expect(find.byType(CircularProgressIndicator), findsOneWidget);
await tester.pumpAndSettle();
```

- [ ] **Step 3: Commit**

```bash
git add floz_mobile/test/features/student/dashboard/
git commit -m "test(mobile/dashboard): widget tests for DashboardScreen"
```

---

### Task 15: Create StudentShell with bottom nav + TabPlaceholder widget

**Files:**
- Create: `floz_mobile/lib/features/student/shared/widgets/tab_placeholder.dart`
- Create: `floz_mobile/lib/features/student/shared/widgets/student_shell.dart`

- [ ] **Step 1: Create shared/widgets dir**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/shared/widgets
```

- [ ] **Step 2: Create TabPlaceholder**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/shared/widgets/tab_placeholder.dart`:

```dart
import 'package:flutter/material.dart';

class TabPlaceholder extends StatelessWidget {
  final String title;
  final String message;
  const TabPlaceholder({
    super.key,
    required this.title,
    this.message = 'Fitur ini akan hadir di pembaruan selanjutnya.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create StudentShell**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/shared/widgets/student_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/presentation/screens/dashboard_screen.dart';
import 'tab_placeholder.dart';

class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int _index = 0;

  static const _tabs = <_StudentTab>[
    _StudentTab(label: 'Beranda', icon: Icons.home_outlined, activeIcon: Icons.home),
    _StudentTab(label: 'Jadwal', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today),
    _StudentTab(label: 'Nilai', icon: Icons.grade_outlined, activeIcon: Icons.grade),
    _StudentTab(label: 'Rapor', icon: Icons.description_outlined, activeIcon: Icons.description),
    _StudentTab(label: 'Pengumuman', icon: Icons.campaign_outlined, activeIcon: Icons.campaign),
    _StudentTab(label: 'Tugas', icon: Icons.assignment_outlined, activeIcon: Icons.assignment),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          TabPlaceholder(title: 'Jadwal'),
          TabPlaceholder(title: 'Nilai'),
          TabPlaceholder(title: 'Rapor'),
          TabPlaceholder(title: 'Pengumuman'),
          TabPlaceholder(title: 'Tugas'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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

- [ ] **Step 4: Flutter analyze**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze lib/features/student/shared/ 2>&1 | tail -10
```

Expected: No issues.

- [ ] **Step 5: Commit**

```bash
git add floz_mobile/lib/features/student/shared/
git commit -m "feat(mobile/student): add StudentShell with bottom nav + TabPlaceholder"
```

---

### Task 16: Wire StudentShell into router

**Files:**
- Modify: `floz_mobile/lib/core/router/app_router.dart`

- [ ] **Step 1: Read current router**

```bash
cat /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/core/router/app_router.dart
```

Locate the `_StudentPlaceholderScreen` reference and its class definition at the bottom of the file.

- [ ] **Step 2: Replace placeholder with StudentShell**

Edit the file. Add an import at the top:

```dart
import '../../features/student/shared/widgets/student_shell.dart';
```

Change the `/student` route from:

```dart
GoRoute(
  path: '/student',
  builder: (_, __) => const _StudentPlaceholderScreen(),
),
```

to:

```dart
GoRoute(
  path: '/student',
  builder: (_, __) => const StudentShell(),
),
```

Then DELETE the `_StudentPlaceholderScreen` class definition at the bottom of the file (keep `_TeacherPlaceholderScreen` — that's still used for `/teacher`).

- [ ] **Step 3: Flutter analyze**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze lib/core/router/ 2>&1 | tail -10
```

Expected: No issues.

- [ ] **Step 4: Run all tests**

```bash
flutter test test/core/ test/features/auth/ test/features/student/
```

Expected: All tests pass (P1 tests + new dashboard tests).

- [ ] **Step 5: Commit**

```bash
git add floz_mobile/lib/core/router/app_router.dart
git commit -m "feat(mobile/router): wire StudentShell into /student route"
```

---

### Task 17: Manual integration test + DoD verification

- [ ] **Step 1: Ensure test data exists in dev DB**

Connect to dev DB and verify that a Student record is linked to `student@floz.test`. If not, seed via tinker:

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan tinker --execute='
use App\Models\User;
use App\Models\Student;
use App\Models\SchoolClass;
use App\Models\Teacher;
use App\Models\AcademicYear;
use App\Models\Announcement;

// Academic year
$ay = AcademicYear::firstOrCreate(
    ["name" => "2026/2027 - Ganjil"],
    ["start_date" => "2026-07-01", "end_date" => "2026-12-31", "is_active" => true]
);

// Homeroom teacher
$wali = Teacher::firstOrCreate(
    ["email" => "wali4a@floz.test"],
    ["name" => "Bu Ani", "nip" => "198001012010012001"]
);
User::firstOrCreate(
    ["email" => "wali4a@floz.test"],
    ["name" => "Bu Ani", "password" => bcrypt("password123"), "role" => \App\Enums\UserRole::Teacher, "is_active" => true, "email_verified_at" => now()]
);

// Class 4A
$class = SchoolClass::firstOrCreate(
    ["name" => "4A"],
    ["grade_level" => 4, "academic_year_id" => $ay->id, "homeroom_teacher_id" => $wali->id, "max_students" => 30, "status" => "active"]
);

// Student record for student@floz.test
$student = Student::firstOrCreate(
    ["email" => "student@floz.test"],
    ["name" => "Siswa Test", "nis" => "12345", "nisn" => "9876543210", "gender" => "L", "class_id" => $class->id, "status" => "active"]
);

// A few published announcements
for ($i = 1; $i <= 3; $i++) {
    Announcement::firstOrCreate(
        ["title" => "Pengumuman $i"],
        ["content" => "Ini adalah isi pengumuman nomor $i.", "is_published" => true, "user_id" => 1, "type" => "info", "target_audience" => "all"]
    );
}

echo "Seeded: student=" . $student->id . " class=" . $class->id . " wali=" . $wali->id . PHP_EOL;
'
```

- [ ] **Step 2: Start backend server**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan serve --host=127.0.0.1 --port=8000 &
SERVER_PID=$!
sleep 2
```

- [ ] **Step 3: Test via curl end-to-end**

```bash
# Login as student
TOKEN=$(curl -s -X POST http://127.0.0.1:8000/api/v1/auth/login \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d '{"email":"student@floz.test","password":"password123"}' \
  | php -r 'echo json_decode(file_get_contents("php://stdin"))->data->token;')

echo "Token: $TOKEN"

# Get dashboard
curl -s http://127.0.0.1:8000/api/v1/student/dashboard \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" | php -r '
$d = json_decode(file_get_contents("php://stdin"), true);
print_r($d);
'
```

Expected output: `{data: {role: "student", student: {...}, stats: {...}, todays_schedules: [...], recent_announcements: [...]}}`

Verify:
- `data.student.name` = "Siswa Test"
- `data.student.class` = "4A"
- `data.recent_announcements` has 3 items

- [ ] **Step 4: Run mobile app on simulator**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter run -d "iPhone 16e" --dart-define=FLOZ_API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Verify in the simulator:
- Login screen appears
- Login with `student@floz.test` / `password123`
- Redirect to `/student` → StudentShell with bottom nav
- **Beranda tab (index 0):** Shows "Halo, Siswa Test", "Kelas: 4A", "Wali Kelas: Bu Ani", attendance card (likely 0% since no attendance records seeded), 3 announcements
- **Other tabs (1-5):** Tap each → shows TabPlaceholder with construction icon + "Fitur ini akan hadir..."
- Pull to refresh on Beranda tab → triggers network fetch

- [ ] **Step 5: Verify cache fallback (airplane mode)**

In simulator Features menu → Network Link Conditioner → 100% loss. Pull to refresh on Dashboard. Should still show cached data (just shown slightly stale). Turn network back on.

- [ ] **Step 6: Stop server**

```bash
kill $SERVER_PID
```

- [ ] **Step 7: Final regression test**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest 2>&1 | tail -3
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter test test/core/ test/features/auth/ test/features/student/ 2>&1 | tail -5
flutter analyze lib/core/ lib/features/auth/ lib/features/student/dashboard/ lib/features/student/shared/ 2>&1 | tail -5
```

Expected:
- Backend: ~80 tests pass (71 P1 + 9 new)
- Mobile: ~30 tests pass (23 P1 + 7 new repo + 2 widget)
- Analyze (P2.1 scope): clean

- [ ] **Step 8: Tag milestone**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git tag p2.1-dashboard-complete
```

---

## P2.1 Definition of Done — Checklist

- [ ] `/api/v1/student/dashboard` endpoint exists, guarded by `role:student`, returns envelope `{data: {...}}`
- [ ] Legacy `/api/v1/dashboard` route and `Api\MobileDashboardController.php` are deleted
- [ ] DashboardService unit tests (6) + feature tests (3) all pass
- [ ] Full backend regression: 80+ tests green
- [ ] Mobile `features/student/dashboard` rebuilt with clean architecture (entity, DTO, datasource, repo, providers, screen)
- [ ] Repository uses Hive cache with 5-min TTL; stale fallback on network failure
- [ ] DashboardRepository unit tests (7) + DashboardScreen widget tests (2) all pass
- [ ] StudentShell widget exists with 6-tab bottom nav; dashboard is live, other 5 tabs are TabPlaceholder
- [ ] Router redirects `/student` to StudentShell (placeholder class deleted)
- [ ] Manual smoke test: login as student → see real dashboard data → switch tabs → see placeholders
- [ ] Cache fallback verified with network disconnected
- [ ] No new lint errors introduced in P2.1 scope files
- [ ] Git tag `p2.1-dashboard-complete` created

---

## Notes for the executing agent

- **P1 infrastructure is complete.** Reuse `ApiClient`, `Failure`, `Result<T>`, `CacheBox<T>`, `authSessionProvider`, `apiClientProvider` — do NOT re-create these.
- **Schema quirks from P1 execution (still apply):**
  - `Student::user()` joins via email (not user_id FK)
  - `Student::class()` method name (NOT `schoolClass()`)
  - `UserRole` enum is PascalCase (`Student`, `Teacher`, `SchoolAdmin`, `Parent`, `SuperAdmin`)
  - Attendance uses `meeting_number` INT + status values like `hadir`/`sakit`/`izin`/`alpha` (NOT `present`)
  - Announcement uses `target_audience` enum + `is_published` boolean + `user_id` author FK (NOT `class_id`)
- **The legacy student features** in `floz_mobile/lib/features/student/{schedule,grades,report_cards,announcements,assignments}` still have broken pre-P1 code. Leave them alone in P2.1 — they'll be rebuilt in P2.2-P2.6.
- **TDD discipline:** red → green → refactor → commit per task. Don't batch.
- **Commit messages:** Conventional Commits (`feat`, `fix`, `test`, `chore`, `docs`, `refactor`, `style`).
- **If a factory is missing** for a model you're testing (e.g., ScheduleFactory), create it inline as part of the task. Check `src/database/factories/` first for what's already there.
- **If the existing DashboardService test expects a column name or relation that doesn't exist in the actual schema**, STOP and read the migration/model. Don't guess. Adjust the test or the code to match the schema.
- **After P2.1 is complete**, return to writing-plans to draft P2.2 (Schedule).
