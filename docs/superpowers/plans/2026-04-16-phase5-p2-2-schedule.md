# Phase 5 — P2.2 Student Schedule Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `Jadwal` tab placeholder with a working weekly schedule view — backend V1 endpoint (`/api/v1/student/schedules`) with service + resource + tests, mobile feature module rebuilt from scratch with Hive cache, Jadwal tab shows real data.

**Architecture:** Backend migrates `Api\MobileScheduleController` → `Api\V1\MobileScheduleController` using thin-controller → Service → Resource pattern. Mobile rebuilds `features/student/schedule` with clean architecture. Screen shows grouped-by-day cards using the existing `FlozCard` + `StaggeredEntry` primitives for cohesive visual language with the dashboard.

**Tech Stack:**
- Backend: Laravel 12, Pest, Sanctum, Postgres
- Mobile: Flutter 3.11, Riverpod, Dio, Hive, intl, mocktail
- Contract: `docs/api/CONTRACT.md` (envelope `{data: ...}`)

**Spec source:** `docs/superpowers/specs/2026-04-15-phase5-rest-api-mobile-design.md` (Slice #2 Schedule)

---

## Key Decisions

1. **Endpoint path:** `GET /api/v1/student/schedules` (plural). Legacy `/api/v1/schedules` removed. `role:student` middleware guard.
2. **Response shape:** Grouped by `day_of_week` (1=Monday, 7=Sunday per migration comment), envelope `{data: [{day: int, day_name: string, items: [...]}]}`. Include `day_name` for UI convenience.
3. **Today-only subroute dropped from P2.2.** The full weekly endpoint is cheap enough — mobile filters client-side for a "today highlight" if needed. Drops legacy `GET /schedules/today` surface area.
4. **Schedule model uses UUID primary keys** — factory must honor `HasUuids` trait (Laravel auto-generates on create).
5. **Mobile cache TTL:** 1 day (schedules rarely change mid-week). Matches spec §6.4.
6. **Schedule screen UI:** Vertical list grouped by day, today's day highlighted with primary color accent rail; empty-day rows hidden (no "Sunday: no classes" clutter). Uses the dashboard's `_ScheduleTile` visual pattern for cohesion.
7. **Day names:** Hardcoded Indonesian in the service (`Senin`, `Selasa`, …). Keeps backend responsible for i18n labels rather than scattering across mobile.

---

## File Structure

### Backend — files to create
```
src/app/Http/Controllers/Api/V1/MobileScheduleController.php
src/app/Services/Mobile/ScheduleService.php
src/app/Http/Resources/Api/V1/ScheduleResource.php
src/database/factories/ScheduleFactory.php
src/tests/Unit/Services/Mobile/ScheduleServiceTest.php
src/tests/Feature/Api/V1/Student/ScheduleTest.php
```

### Backend — files to modify
```
src/routes/api.php
```

### Backend — files to delete
```
src/app/Http/Controllers/Api/MobileScheduleController.php
```

### Mobile — files to delete (pre-P1 broken)
```
floz_mobile/lib/features/student/schedule/   (entire directory, recursive)
```

### Mobile — files to create
```
floz_mobile/lib/features/student/schedule/domain/entities/weekly_schedule.dart
floz_mobile/lib/features/student/schedule/domain/repositories/schedule_repository.dart
floz_mobile/lib/features/student/schedule/data/models/schedule_dto.dart
floz_mobile/lib/features/student/schedule/data/datasources/schedule_remote_datasource.dart
floz_mobile/lib/features/student/schedule/data/repositories/schedule_repository_impl.dart
floz_mobile/lib/features/student/schedule/providers/schedule_providers.dart
floz_mobile/lib/features/student/schedule/presentation/screens/schedule_screen.dart
floz_mobile/test/features/student/schedule/data/repositories/schedule_repository_impl_test.dart
floz_mobile/test/features/student/schedule/presentation/screens/schedule_screen_test.dart
```

### Mobile — files to modify
```
floz_mobile/lib/core/network/api_endpoints.dart
floz_mobile/lib/features/student/shared/widgets/student_shell.dart
```

---

## Tasks

### Task 1: Create ScheduleFactory (UUID-aware)

**Files:**
- Create: `src/database/factories/ScheduleFactory.php`

**Why:** Needed for service + feature tests. Schedule uses `HasUuids` — factory must not hardcode `id` (Laravel auto-generates). Factory must chain `TeachingAssignment::factory()`.

- [ ] **Step 1: Create the factory**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/database/factories/ScheduleFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Models\Schedule;
use App\Models\TeachingAssignment;
use Illuminate\Database\Eloquent\Factories\Factory;

class ScheduleFactory extends Factory
{
    protected $model = Schedule::class;

    public function definition(): array
    {
        return [
            'teaching_assignment_id' => TeachingAssignment::factory(),
            'day_of_week' => fake()->numberBetween(1, 5),
            'start_time' => '07:00:00',
            'end_time'   => '08:30:00',
        ];
    }

    public function onDay(int $dayOfWeek): static
    {
        return $this->state(fn () => ['day_of_week' => $dayOfWeek]);
    }

    public function at(string $start, string $end): static
    {
        return $this->state(fn () => [
            'start_time' => $start,
            'end_time' => $end,
        ]);
    }
}
```

- [ ] **Step 2: Smoke test the factory**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan tinker --execute='
\App\Models\Schedule::factory()->count(2)->make()->each(fn($s) => print($s->day_of_week . " " . $s->start_time . PHP_EOL));
' 2>&1 | tail -5
```

Expected: prints `1 07:00:00` (or similar) twice. No errors about missing UUID.

- [ ] **Step 3: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add src/database/factories/ScheduleFactory.php
git commit -m "test(factory): add ScheduleFactory with day/time state helpers"
```

---

### Task 2: Write failing ScheduleService unit test

**Files:**
- Create: `src/tests/Unit/Services/Mobile/ScheduleServiceTest.php`

- [ ] **Step 1: Create test file**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/tests/Unit/Services/Mobile/ScheduleServiceTest.php`:

```php
<?php

use App\Models\Schedule;
use App\Models\Student;
use App\Models\TeachingAssignment;
use App\Models\User;
use App\Services\Mobile\ScheduleService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new ScheduleService();
});

it('returns empty list when student has no class', function () {
    $student = Student::factory()->create(['class_id' => null]);
    $user = User::where('email', $student->email)->first();

    $result = $this->service->forStudent($user);

    expect($result)->toBe([]);
});

it('returns schedules grouped by day_of_week with indonesian day names', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    $ta = TeachingAssignment::factory()->create(['class_id' => $student->class_id]);

    // 2 schedules on Monday (day 1), 1 on Wednesday (day 3)
    Schedule::factory()->onDay(1)->at('07:00:00', '08:30:00')->create([
        'teaching_assignment_id' => $ta->id,
    ]);
    Schedule::factory()->onDay(1)->at('08:30:00', '10:00:00')->create([
        'teaching_assignment_id' => $ta->id,
    ]);
    Schedule::factory()->onDay(3)->at('07:00:00', '08:30:00')->create([
        'teaching_assignment_id' => $ta->id,
    ]);

    $result = $this->service->forStudent($user);

    expect($result)->toHaveCount(2);

    expect($result[0]['day'])->toBe(1);
    expect($result[0]['day_name'])->toBe('Senin');
    expect($result[0]['items'])->toHaveCount(2);

    expect($result[1]['day'])->toBe(3);
    expect($result[1]['day_name'])->toBe('Rabu');
    expect($result[1]['items'])->toHaveCount(1);
});

it('sorts items within a day by start_time ascending', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $ta = TeachingAssignment::factory()->create(['class_id' => $student->class_id]);

    Schedule::factory()->onDay(2)->at('10:00:00', '11:30:00')->create([
        'teaching_assignment_id' => $ta->id,
    ]);
    Schedule::factory()->onDay(2)->at('07:00:00', '08:30:00')->create([
        'teaching_assignment_id' => $ta->id,
    ]);

    $result = $this->service->forStudent($user);

    expect($result[0]['items'][0]['start_time'])->toBe('07:00');
    expect($result[0]['items'][1]['start_time'])->toBe('10:00');
});

it('only returns schedules from teaching assignments in the student\'s class', function () {
    $studentA = Student::factory()->create();
    $studentB = Student::factory()->create();
    $userA = User::where('email', $studentA->email)->first();

    $taA = TeachingAssignment::factory()->create(['class_id' => $studentA->class_id]);
    $taB = TeachingAssignment::factory()->create(['class_id' => $studentB->class_id]);

    Schedule::factory()->onDay(1)->create(['teaching_assignment_id' => $taA->id]);
    Schedule::factory()->onDay(1)->create(['teaching_assignment_id' => $taB->id]);

    $result = $this->service->forStudent($userA);

    expect($result)->toHaveCount(1);
    expect($result[0]['items'])->toHaveCount(1);
});

it('includes subject name and teacher name in each item', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $ta = TeachingAssignment::factory()->create(['class_id' => $student->class_id]);

    Schedule::factory()->onDay(1)->create(['teaching_assignment_id' => $ta->id]);

    $result = $this->service->forStudent($user);
    $item = $result[0]['items'][0];

    expect($item)->toHaveKeys(['id', 'start_time', 'end_time', 'subject', 'teacher']);
    expect($item['subject'])->not->toBeEmpty();
    expect($item['teacher'])->not->toBeEmpty();
});
```

- [ ] **Step 2: Run test, confirm fail**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest tests/Unit/Services/Mobile/ScheduleServiceTest.php 2>&1 | tail -15
```

Expected: FAIL with `Class "App\Services\Mobile\ScheduleService" not found`.

---

### Task 3: Implement ScheduleService

**Files:**
- Create: `src/app/Services/Mobile/ScheduleService.php`

- [ ] **Step 1: Create service**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Services/Mobile/ScheduleService.php`:

```php
<?php

namespace App\Services\Mobile;

use App\Models\Schedule;
use App\Models\User;

class ScheduleService
{
    /**
     * Indonesian day-of-week labels keyed by ISO day number (1=Mon, 7=Sun).
     */
    private const DAY_NAMES = [
        1 => 'Senin',
        2 => 'Selasa',
        3 => 'Rabu',
        4 => 'Kamis',
        5 => 'Jumat',
        6 => 'Sabtu',
        7 => 'Minggu',
    ];

    /**
     * Build weekly schedule payload for an authenticated student.
     *
     * @return array<int, array{day:int, day_name:string, items: array<int, array<string,mixed>>}>
     */
    public function forStudent(User $user): array
    {
        $student = $user->student;
        if (! $student || ! $student->class_id) {
            return [];
        }

        $grouped = Schedule::query()
            ->whereHas(
                'teachingAssignment',
                fn ($q) => $q->where('class_id', $student->class_id)
            )
            ->with(['teachingAssignment.subject', 'teachingAssignment.teacher'])
            ->orderBy('day_of_week')
            ->orderBy('start_time')
            ->get()
            ->groupBy('day_of_week');

        $result = [];
        foreach ($grouped as $day => $items) {
            $result[] = [
                'day' => (int) $day,
                'day_name' => self::DAY_NAMES[(int) $day] ?? 'Hari',
                'items' => $items
                    ->map(fn (Schedule $s) => [
                        'id' => (string) $s->id,
                        'start_time' => $s->start_time,
                        'end_time' => $s->end_time,
                        'subject' => $s->teachingAssignment->subject->name ?? '-',
                        'teacher' => $s->teachingAssignment->teacher->name ?? '-',
                    ])
                    ->values()
                    ->all(),
            ];
        }

        return $result;
    }
}
```

- [ ] **Step 2: Run test, confirm pass**

```bash
./vendor/bin/pest tests/Unit/Services/Mobile/ScheduleServiceTest.php 2>&1 | tail -15
```

Expected: PASS (5 tests).

Common failure notes:
- If `start_time`/`end_time` assertions fail with `'07:00:00'` vs `'07:00'`: Schedule model casts to `datetime:H:i` which should give `'07:00'` format. If actual output is `'07:00:00'`, adjust the service to format explicitly: `substr($s->start_time, 0, 5)`.
- If item count is 0: check that the `whereHas` relation path matches the actual relation name on Schedule (should be `teachingAssignment`, not `teaching_assignment`).

- [ ] **Step 3: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add src/app/Services/Mobile/ScheduleService.php src/tests/Unit/Services/Mobile/ScheduleServiceTest.php
git commit -m "feat(api/v1): add ScheduleService for student weekly schedule"
```

---

### Task 4: Create ScheduleResource (passthrough)

**Files:**
- Create: `src/app/Http/Resources/Api/V1/ScheduleResource.php`

- [ ] **Step 1: Create resource**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Http/Resources/Api/V1/ScheduleResource.php`:

```php
<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Passthrough resource — ScheduleService already returns the correctly
 * shaped array, this wrapper exists so controllers can use the same
 * Resource pattern across all slices.
 */
class ScheduleResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return (array) $this->resource;
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add src/app/Http/Resources/Api/V1/ScheduleResource.php
git commit -m "feat(api/v1): add ScheduleResource (passthrough envelope)"
```

---

### Task 5: Write failing V1 schedule feature test + implement controller + register route

**Files:**
- Create: `src/tests/Feature/Api/V1/Student/ScheduleTest.php`
- Create: `src/app/Http/Controllers/Api/V1/MobileScheduleController.php`
- Modify: `src/routes/api.php`

- [ ] **Step 1: Write failing feature test**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/tests/Feature/Api/V1/Student/ScheduleTest.php`:

```php
<?php

use App\Models\Schedule;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('returns weekly schedule grouped by day for authenticated student', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $ta = TeachingAssignment::factory()->create(['class_id' => $student->class_id]);
    Schedule::factory()->onDay(1)->create(['teaching_assignment_id' => $ta->id]);
    Schedule::factory()->onDay(3)->create(['teaching_assignment_id' => $ta->id]);

    $token = $user->createToken('mobile')->plainTextToken;

    $response = $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/schedules');

    $response->assertOk()
        ->assertJsonStructure([
            'data' => [
                '*' => [
                    'day',
                    'day_name',
                    'items' => [
                        '*' => ['id', 'start_time', 'end_time', 'subject', 'teacher'],
                    ],
                ],
            ],
        ])
        ->assertJsonPath('data.0.day', 1)
        ->assertJsonPath('data.0.day_name', 'Senin')
        ->assertJsonPath('data.1.day', 3)
        ->assertJsonPath('data.1.day_name', 'Rabu');
});

it('returns empty data array when student has no schedule', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/schedules')
        ->assertOk()
        ->assertJsonPath('data', []);
});

it('returns 401 without a token', function () {
    $this->getJson('/api/v1/student/schedules')->assertUnauthorized();
});

it('returns 403 for teacher token', function () {
    $teacher = Teacher::factory()->create();
    $token = $teacher->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/schedules')
        ->assertForbidden();
});
```

- [ ] **Step 2: Run test, confirm fail**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest tests/Feature/Api/V1/Student/ScheduleTest.php 2>&1 | tail -15
```

Expected: FAIL — likely 404 for all tests (route not registered) or controller-not-found.

- [ ] **Step 3: Create V1 controller**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Http/Controllers/Api/V1/MobileScheduleController.php`:

```php
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ScheduleResource;
use App\Services\Mobile\ScheduleService;
use Illuminate\Http\Request;

class MobileScheduleController extends Controller
{
    public function __construct(private readonly ScheduleService $service) {}

    /**
     * @OA\Get(
     *     path="/api/v1/student/schedules",
     *     tags={"Student"},
     *     summary="Jadwal mingguan siswa",
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(response=200, description="Schedule grouped by day"),
     *     @OA\Response(response=401, description="Token tidak valid"),
     *     @OA\Response(response=403, description="Bukan siswa"),
     * )
     */
    public function index(Request $request)
    {
        $data = $this->service->forStudent($request->user());

        return response()->json([
            'data' => (new ScheduleResource($data))->resolve(),
        ]);
    }
}
```

- [ ] **Step 4: Register route**

Read `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/routes/api.php`. Locate:

```php
use App\Http\Controllers\Api\MobileScheduleController;
```

Change to:

```php
use App\Http\Controllers\Api\V1\MobileScheduleController;
```

Inside the `['auth:sanctum', 'throttle:mobile-api']` middleware group, locate:

```php
// Schedules
Route::get('/schedules', [MobileScheduleController::class, 'index']);
Route::get('/schedules/today', [MobileScheduleController::class, 'today']);
```

Replace with:

```php
Route::middleware('role:student')->group(function () {
    Route::get('/student/schedules', [MobileScheduleController::class, 'index']);
});
```

(Legacy `/schedules` and `/schedules/today` routes are removed. Teacher will get its own endpoint in P3.)

**IMPORTANT:** Do NOT touch the existing `/student/dashboard` line or the other slice routes. Only modify the 3 lines above.

If P2.1 already created a `Route::middleware('role:student')->group(function () { ... })` block for the dashboard, add the schedules route inside that existing block rather than creating a second identical block.

- [ ] **Step 5: Run feature test, confirm pass**

```bash
./vendor/bin/pest tests/Feature/Api/V1/Student/ScheduleTest.php 2>&1 | tail -15
```

Expected: PASS (4 tests).

- [ ] **Step 6: Run full regression**

```bash
./vendor/bin/pest 2>&1 | tail -3
```

Expected: ~90 tests pass (80 prior + 5 unit + 4 feature + 1 factory smoke).

- [ ] **Step 7: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add src/app/Http/Controllers/Api/V1/MobileScheduleController.php \
        src/tests/Feature/Api/V1/Student/ScheduleTest.php \
        src/routes/api.php
git commit -m "feat(api/v1): add student schedules endpoint with role guard"
```

---

### Task 6: Delete legacy MobileScheduleController

**Files:**
- Delete: `src/app/Http/Controllers/Api/MobileScheduleController.php`

- [ ] **Step 1: Verify route registration**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan route:list --path=api/v1 2>&1 | grep -i schedule
```

Expected: one line `GET api/v1/student/schedules → Api\V1\MobileScheduleController@index`. No `/api/v1/schedules` or `/api/v1/schedules/today`.

- [ ] **Step 2: Grep for stale references**

Use the Grep tool with pattern `App\\Http\\Controllers\\Api\\MobileScheduleController` across `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/`.

Expected: 0 matches.

- [ ] **Step 3: Delete old file**

```bash
rm /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Http/Controllers/Api/MobileScheduleController.php
```

- [ ] **Step 4: Run full regression**

```bash
./vendor/bin/pest 2>&1 | tail -3
```

Expected: still all green (~90 tests).

- [ ] **Step 5: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add -A src/app/Http/Controllers/Api/
git commit -m "refactor(api): remove legacy Api\\MobileScheduleController"
```

---

### Task 7: Delete pre-P1 broken mobile schedule code

**Files:**
- Delete: `floz_mobile/lib/features/student/schedule/` (entire directory, recursive)

- [ ] **Step 1: Inspect what's in the dir**

```bash
find /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/schedule -type f 2>&1 | sed -n '1,20p'
```

Note files present. Expected: ~5-6 broken pre-P1 Dart files.

- [ ] **Step 2: Count analyze errors BEFORE deletion**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze 2>&1 | grep -c "error •"
```

Remember this number. Expected: ~19 (post P2.1).

- [ ] **Step 3: Delete the directory**

```bash
rm -rf /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/schedule
```

- [ ] **Step 4: Count errors AFTER**

```bash
flutter analyze 2>&1 | grep -c "error •"
```

Expected: LOWER than baseline (broken schedule files removed their own errors).

If count went UP, some other file imported from the deleted schedule dir. Grep for the import and either update or delete the referencing file.

- [ ] **Step 5: Commit deletion**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add -A floz_mobile/lib/features/student/schedule
git commit -m "chore(mobile): remove pre-P1 broken schedule code"
```

---

### Task 8: Mobile — schedule domain + DTO + datasource + endpoint const

**Files:**
- Create: `floz_mobile/lib/features/student/schedule/domain/entities/weekly_schedule.dart`
- Create: `floz_mobile/lib/features/student/schedule/domain/repositories/schedule_repository.dart`
- Create: `floz_mobile/lib/features/student/schedule/data/models/schedule_dto.dart`
- Create: `floz_mobile/lib/features/student/schedule/data/datasources/schedule_remote_datasource.dart`
- Modify: `floz_mobile/lib/core/network/api_endpoints.dart`

- [ ] **Step 1: Create directory scaffold**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/schedule/domain/entities
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/schedule/domain/repositories
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/schedule/data/models
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/schedule/data/datasources
```

- [ ] **Step 2: Create entity**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/schedule/domain/entities/weekly_schedule.dart`:

```dart
/// A single day's block of the weekly schedule.
class ScheduleDay {
  final int day; // 1=Senin ... 7=Minggu
  final String dayName;
  final List<ScheduleEntry> items;

  const ScheduleDay({
    required this.day,
    required this.dayName,
    required this.items,
  });
}

/// One period within a day — a class session.
class ScheduleEntry {
  final String id;
  final String startTime; // 'HH:mm'
  final String endTime;
  final String subject;
  final String teacher;

  const ScheduleEntry({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacher,
  });
}

/// Top-level weekly schedule — a list of days (only non-empty days returned
/// by the backend).
class WeeklySchedule {
  final List<ScheduleDay> days;
  const WeeklySchedule({required this.days});

  bool get isEmpty => days.isEmpty;
}
```

- [ ] **Step 3: Create repository interface**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/schedule/domain/repositories/schedule_repository.dart`:

```dart
import '../../../../../core/error/result.dart';
import '../entities/weekly_schedule.dart';

abstract class ScheduleRepository {
  Future<Result<WeeklySchedule>> fetch({bool forceRefresh = false});
}
```

- [ ] **Step 4: Create DTO**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/schedule/data/models/schedule_dto.dart`:

```dart
import '../../domain/entities/weekly_schedule.dart';

class ScheduleDto {
  static WeeklySchedule fromJson(List<dynamic> json) {
    final days = json
        .whereType<Map<String, dynamic>>()
        .map(_dayFromJson)
        .toList(growable: false);
    return WeeklySchedule(days: days);
  }

  static ScheduleDay _dayFromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_entryFromJson)
        .toList(growable: false);
    return ScheduleDay(
      day: (json['day'] as num?)?.toInt() ?? 0,
      dayName: json['day_name'] as String? ?? '-',
      items: items,
    );
  }

  static ScheduleEntry _entryFromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: json['id']?.toString() ?? '',
      startTime: _trimTime(json['start_time']?.toString() ?? ''),
      endTime: _trimTime(json['end_time']?.toString() ?? ''),
      subject: json['subject']?.toString() ?? '-',
      teacher: json['teacher']?.toString() ?? '-',
    );
  }

  static String _trimTime(String raw) {
    if (raw.length >= 5) return raw.substring(0, 5);
    return raw;
  }
}
```

- [ ] **Step 5: Create remote datasource**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/schedule/data/datasources/schedule_remote_datasource.dart`:

```dart
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/weekly_schedule.dart';
import '../models/schedule_dto.dart';

abstract class ScheduleRemoteDataSource {
  Future<WeeklySchedule> fetch();
}

class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  final ApiClient _client;
  ScheduleRemoteDataSourceImpl(this._client);

  @override
  Future<WeeklySchedule> fetch() async {
    final res = await _client.get(ApiEndpoints.studentSchedules);
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as List? ?? const [];
    return ScheduleDto.fromJson(data);
  }
}
```

- [ ] **Step 6: Add endpoint constant**

Read `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/core/network/api_endpoints.dart`. It currently has:

```dart
class ApiEndpoints {
  ApiEndpoints._();

  static const String authLogin  = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authMe     = '/auth/me';

  static const String studentDashboard = '/student/dashboard';
}
```

Add `studentSchedules` constant below `studentDashboard`:

```dart
  static const String studentSchedules = '/student/schedules';
```

- [ ] **Step 7: Flutter analyze**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze lib/features/student/schedule/ lib/core/network/api_endpoints.dart 2>&1 | tail -10
```

Expected: No issues.

- [ ] **Step 8: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add floz_mobile/lib/features/student/schedule/domain \
        floz_mobile/lib/features/student/schedule/data \
        floz_mobile/lib/core/network/api_endpoints.dart
git commit -m "feat(mobile/schedule): domain entities, DTO, remote datasource"
```

---

### Task 9: Write failing repository test + implement with cache

**Files:**
- Create: `floz_mobile/test/features/student/schedule/data/repositories/schedule_repository_impl_test.dart`
- Create: `floz_mobile/lib/features/student/schedule/data/repositories/schedule_repository_impl.dart`

- [ ] **Step 1: Create test dir**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/test/features/student/schedule/data/repositories
```

- [ ] **Step 2: Write failing test**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/test/features/student/schedule/data/repositories/schedule_repository_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/core/storage/cache_box.dart';
import 'package:floz_mobile/features/student/schedule/data/datasources/schedule_remote_datasource.dart';
import 'package:floz_mobile/features/student/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:floz_mobile/features/student/schedule/domain/entities/weekly_schedule.dart';

class _MockRemote extends Mock implements ScheduleRemoteDataSource {}
class _MockCache extends Mock implements CacheBox<dynamic> {}

WeeklySchedule _fixture() => const WeeklySchedule(
      days: [
        ScheduleDay(day: 1, dayName: 'Senin', items: [
          ScheduleEntry(
            id: 'uuid-1',
            startTime: '07:00',
            endTime: '08:30',
            subject: 'Matematika',
            teacher: 'Bu Ani',
          ),
        ]),
      ],
    );

List<dynamic> _fixtureJson() => [
      {
        'day': 1,
        'day_name': 'Senin',
        'items': [
          {
            'id': 'uuid-1',
            'start_time': '07:00',
            'end_time': '08:30',
            'subject': 'Matematika',
            'teacher': 'Bu Ani',
          },
        ],
      },
    ];

void main() {
  late _MockRemote remote;
  late _MockCache cache;
  late ScheduleRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    cache = _MockCache();
    repo = ScheduleRepositoryImpl(remote: remote, cache: cache);
  });

  test('returns Success from remote and writes cache on happy path', () async {
    when(() => cache.get(any())).thenAnswer((_) async => null);
    when(() => remote.fetch()).thenAnswer((_) async => _fixture());
    when(() => cache.put(any(), any())).thenAnswer((_) async {});

    final result = await repo.fetch();

    expect(result, isA<Success<WeeklySchedule>>());
    verify(() => cache.put('main', any())).called(1);
  });

  test('returns stale Success from cache on NetworkException', () async {
    when(() => cache.get(any())).thenAnswer((_) async => null);
    when(() => remote.fetch()).thenThrow(const NetworkException('offline'));
    when(() => cache.getStale(any())).thenAnswer((_) async => _fixtureJson());

    final result = await repo.fetch();

    expect(result, isA<Success<WeeklySchedule>>());
    expect((result as Success<WeeklySchedule>).stale, isTrue);
  });

  test('returns NetworkFailure when remote fails and cache empty', () async {
    when(() => cache.get(any())).thenAnswer((_) async => null);
    when(() => remote.fetch()).thenThrow(const NetworkException('offline'));
    when(() => cache.getStale(any())).thenAnswer((_) async => null);

    final result = await repo.fetch();

    expect(result, isA<FailureResult<WeeklySchedule>>());
    expect((result as FailureResult).failure, isA<NetworkFailure>());
  });

  test('returns cached Success directly when cache is fresh', () async {
    when(() => cache.get(any())).thenAnswer((_) async => _fixtureJson());

    final result = await repo.fetch();

    expect(result, isA<Success<WeeklySchedule>>());
    expect((result as Success<WeeklySchedule>).stale, isFalse);
    verifyNever(() => remote.fetch());
  });

  test('bypasses cache when forceRefresh=true', () async {
    when(() => cache.get(any())).thenAnswer((_) async => _fixtureJson());
    when(() => remote.fetch()).thenAnswer((_) async => _fixture());
    when(() => cache.put(any(), any())).thenAnswer((_) async {});

    final result = await repo.fetch(forceRefresh: true);

    expect(result, isA<Success<WeeklySchedule>>());
    verify(() => remote.fetch()).called(1);
  });
}
```

- [ ] **Step 3: Run test, confirm fail**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter test test/features/student/schedule/data/repositories/schedule_repository_impl_test.dart 2>&1 | tail -15
```

Expected: FAIL (`ScheduleRepositoryImpl` not found).

- [ ] **Step 4: Create repositories dir**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/schedule/data/repositories
```

- [ ] **Step 5: Implement repository**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/schedule/data/repositories/schedule_repository_impl.dart`:

```dart
import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/storage/cache_box.dart';
import '../../domain/entities/weekly_schedule.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_remote_datasource.dart';
import '../models/schedule_dto.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  static const _cacheKey = 'main';

  final ScheduleRemoteDataSource _remote;
  final CacheBox<dynamic> _cache;

  ScheduleRepositoryImpl({
    required ScheduleRemoteDataSource remote,
    required CacheBox<dynamic> cache,
  })  : _remote = remote,
        _cache = cache;

  @override
  Future<Result<WeeklySchedule>> fetch({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _cache.get(_cacheKey);
      if (cached is List) {
        return Success(ScheduleDto.fromJson(cached));
      }
    }

    try {
      final data = await _remote.fetch();
      await _cache.put(_cacheKey, _toJson(data));
      return Success(data);
    } on NetworkException catch (e) {
      final stale = await _cache.getStale(_cacheKey);
      if (stale is List) {
        return Success(ScheduleDto.fromJson(stale), stale: true);
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

  List<Map<String, dynamic>> _toJson(WeeklySchedule s) {
    return s.days
        .map((d) => {
              'day': d.day,
              'day_name': d.dayName,
              'items': d.items
                  .map((e) => {
                        'id': e.id,
                        'start_time': e.startTime,
                        'end_time': e.endTime,
                        'subject': e.subject,
                        'teacher': e.teacher,
                      })
                  .toList(),
            })
        .toList();
  }
}
```

- [ ] **Step 6: Run test, confirm pass**

```bash
flutter test test/features/student/schedule/data/repositories/schedule_repository_impl_test.dart 2>&1 | tail -15
```

Expected: PASS (5 tests).

- [ ] **Step 7: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add floz_mobile/lib/features/student/schedule/data/repositories \
        floz_mobile/test/features/student/schedule
git commit -m "feat(mobile/schedule): add ScheduleRepositoryImpl with Hive cache"
```

---

### Task 10: Riverpod providers

**Files:**
- Create: `floz_mobile/lib/features/student/schedule/providers/schedule_providers.dart`

- [ ] **Step 1: Create providers dir**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/schedule/providers
```

- [ ] **Step 2: Implement providers**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/schedule/providers/schedule_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/cache_box.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/schedule_remote_datasource.dart';
import '../data/repositories/schedule_repository_impl.dart';
import '../domain/entities/weekly_schedule.dart';
import '../domain/repositories/schedule_repository.dart';

final scheduleCacheProvider = Provider<CacheBox<dynamic>>((ref) {
  return CacheBox<dynamic>(name: 'schedule_cache', ttl: const Duration(hours: 24));
});

final scheduleRemoteProvider = Provider<ScheduleRemoteDataSource>((ref) {
  return ScheduleRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl(
    remote: ref.watch(scheduleRemoteProvider),
    cache: ref.watch(scheduleCacheProvider),
  );
});

class ScheduleNotifier extends AsyncNotifier<WeeklySchedule> {
  @override
  Future<WeeklySchedule> build() async {
    final result = await ref.read(scheduleRepositoryProvider).fetch();
    return _throwOrReturn(result);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await ref
        .read(scheduleRepositoryProvider)
        .fetch(forceRefresh: true);
    state = await AsyncValue.guard(() async => _throwOrReturn(result));
  }

  WeeklySchedule _throwOrReturn(Result<WeeklySchedule> result) {
    switch (result) {
      case Success(:final data):
        return data;
      case FailureResult(:final failure):
        throw failure;
    }
  }
}

final scheduleNotifierProvider =
    AsyncNotifierProvider<ScheduleNotifier, WeeklySchedule>(ScheduleNotifier.new);
```

- [ ] **Step 3: Flutter analyze**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze lib/features/student/schedule/providers 2>&1 | tail -10
```

Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add floz_mobile/lib/features/student/schedule/providers
git commit -m "feat(mobile/schedule): Riverpod providers for ScheduleRepository + notifier"
```

---

### Task 11: ScheduleScreen UI + widget test

**Files:**
- Create: `floz_mobile/lib/features/student/schedule/presentation/screens/schedule_screen.dart`
- Create: `floz_mobile/test/features/student/schedule/presentation/screens/schedule_screen_test.dart`

- [ ] **Step 1: Create directories**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/schedule/presentation/screens
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/test/features/student/schedule/presentation/screens
```

- [ ] **Step 2: Create ScheduleScreen**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/schedule/presentation/screens/schedule_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/weekly_schedule.dart';
import '../../providers/schedule_providers.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleNotifierProvider);
    final todayIso = DateTime.now().weekday; // 1=Monday ... 7=Sunday

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Jadwal'),
        toolbarHeight: 56,
      ),
      body: RefreshIndicator(
        color: AppColors.primary600,
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        onRefresh: () =>
            ref.read(scheduleNotifierProvider.notifier).refresh(),
        child: state.when(
          data: (schedule) => _ScheduleContent(
            schedule: schedule,
            todayDayOfWeek: todayIso,
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary600),
          ),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              ErrorState(
                message: err is Failure ? err.message : 'Gagal memuat jadwal',
                onRetry: () =>
                    ref.read(scheduleNotifierProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Content ─────────────────────────────────────────────────────────────

class _ScheduleContent extends StatelessWidget {
  const _ScheduleContent({
    required this.schedule,
    required this.todayDayOfWeek,
  });

  final WeeklySchedule schedule;
  final int todayDayOfWeek;

  @override
  Widget build(BuildContext context) {
    if (schedule.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          _EmptyBanner(),
        ],
      );
    }

    final items = <Widget>[];
    for (var i = 0; i < schedule.days.length; i++) {
      final day = schedule.days[i];
      final isToday = day.day == todayDayOfWeek;
      items.add(
        StaggeredEntry(
          index: items.length,
          child: Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 18, bottom: 8),
            child: _DaySectionHeader(day: day, isToday: isToday),
          ),
        ),
      );
      for (final entry in day.items) {
        items.add(
          StaggeredEntry(
            index: items.length,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ScheduleTile(entry: entry, isToday: isToday),
            ),
          ),
        );
      }
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: items,
    );
  }
}

class _DaySectionHeader extends StatelessWidget {
  const _DaySectionHeader({required this.day, required this.isToday});
  final ScheduleDay day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          day.dayName,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isToday ? AppColors.primary700 : AppColors.slate900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 8),
        if (isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.primary200),
            ),
            child: const Text(
              'Hari ini',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        const Spacer(),
        Text(
          '${day.items.length} pelajaran',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.slate400,
          ),
        ),
      ],
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.entry, required this.isToday});
  final ScheduleEntry entry;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlozCard(
      padding: const EdgeInsets.all(14),
      borderColor: isToday ? AppColors.primary200 : null,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary600 : AppColors.slate300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.startTime,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  entry.endTime,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.slate400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.subject,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  entry.teacher,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.slate500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBanner extends StatelessWidget {
  const _EmptyBanner();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
          ),
          child: const Icon(
            Icons.calendar_today_outlined,
            size: 36,
            color: AppColors.primary600,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Belum ada jadwal',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Jadwal pelajaran akan muncul di sini\nsetelah guru mengatur jadwal kelas.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.slate500,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Create widget test**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/test/features/student/schedule/presentation/screens/schedule_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/student/schedule/domain/entities/weekly_schedule.dart';
import 'package:floz_mobile/features/student/schedule/domain/repositories/schedule_repository.dart';
import 'package:floz_mobile/features/student/schedule/presentation/screens/schedule_screen.dart';
import 'package:floz_mobile/features/student/schedule/providers/schedule_providers.dart';

class _MockRepo extends Mock implements ScheduleRepository {}

const _fixture = WeeklySchedule(days: [
  ScheduleDay(
    day: 1,
    dayName: 'Senin',
    items: [
      ScheduleEntry(
        id: 'uuid-1',
        startTime: '07:00',
        endTime: '08:30',
        subject: 'Matematika',
        teacher: 'Bu Ani',
      ),
      ScheduleEntry(
        id: 'uuid-2',
        startTime: '08:30',
        endTime: '10:00',
        subject: 'Bahasa Indonesia',
        teacher: 'Pak Budi',
      ),
    ],
  ),
]);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [scheduleRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows day section header and entries on happy path',
      (tester) async {
    when(() => repo.fetch(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(_fixture));

    await tester.pumpWidget(wrap(const ScheduleScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Senin'), findsOneWidget);
    expect(find.text('2 pelajaran'), findsOneWidget);
    expect(find.text('Matematika'), findsOneWidget);
    expect(find.text('Bahasa Indonesia'), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('08:30'), findsNWidgets(2)); // start of 2nd + end of 1st
    expect(find.text('Bu Ani'), findsOneWidget);
    expect(find.text('Pak Budi'), findsOneWidget);
  });

  testWidgets('shows empty banner when schedule has no days', (tester) async {
    when(() => repo.fetch(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(WeeklySchedule(days: [])));

    await tester.pumpWidget(wrap(const ScheduleScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada jadwal'), findsOneWidget);
  });

  testWidgets('shows error state with retry on failure', (tester) async {
    when(() => repo.fetch(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer(
            (_) async => const FailureResult(NetworkFailure('offline')));

    await tester.pumpWidget(wrap(const ScheduleScreen()));
    await tester.pumpAndSettle();

    expect(find.text('offline'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run test, confirm pass**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter test test/features/student/schedule/presentation/screens/schedule_screen_test.dart 2>&1 | tail -15
```

Expected: PASS (3 tests).

- [ ] **Step 5: Flutter analyze**

```bash
flutter analyze lib/features/student/schedule test/features/student/schedule 2>&1 | tail -10
```

Expected: No issues.

- [ ] **Step 6: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add floz_mobile/lib/features/student/schedule/presentation \
        floz_mobile/test/features/student/schedule/presentation
git commit -m "feat(mobile/schedule): ScheduleScreen UI with today highlight + widget tests"
```

---

### Task 12: Wire ScheduleScreen into StudentShell + manual verification

**Files:**
- Modify: `floz_mobile/lib/features/student/shared/widgets/student_shell.dart`

- [ ] **Step 1: Read current shell**

```bash
cat /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/shared/widgets/student_shell.dart
```

Note the `IndexedStack` children list — tab 0 is DashboardScreen, tab 1 is `TabPlaceholder(title: 'Jadwal')`.

- [ ] **Step 2: Replace Jadwal placeholder with ScheduleScreen**

Edit `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/shared/widgets/student_shell.dart`:

Add import at the top (after the existing dashboard import):

```dart
import '../../schedule/presentation/screens/schedule_screen.dart';
```

Then in the `IndexedStack` children list, replace:

```dart
TabPlaceholder(title: 'Jadwal'),
```

with:

```dart
ScheduleScreen(),
```

Leave the other 4 TabPlaceholder entries untouched (they get replaced in P2.3–P2.6).

- [ ] **Step 3: Flutter analyze**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze lib/features/student/shared/widgets/student_shell.dart 2>&1 | tail -10
```

Expected: No issues.

- [ ] **Step 4: Full regression**

```bash
flutter test test/core test/features/auth test/features/student 2>&1 | tail -5
```

Expected: All tests pass.

- [ ] **Step 5: Seed a few schedules for live test**

Make sure the backend dev server is not running (we'll start it shortly):

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan tinker --execute='
use App\Models\Student;
use App\Models\User;
use App\Models\TeachingAssignment;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\AcademicYear;
use App\Models\Schedule;

$student = Student::where("email", "student@floz.test")->first();
if (!$student || !$student->class_id) {
    echo "ABORT: seed student@floz.test via P2.1 seeder first" . PHP_EOL;
    exit;
}
$classId = $student->class_id;
$ay = AcademicYear::where("is_active", true)->first() ?? AcademicYear::first();

// Create two subjects + reuse existing wali teacher
$mtk = Subject::firstOrCreate(
    ["code" => "MTK-4"],
    ["name" => "Matematika", "type" => "Muatan Nasional", "kkm" => 75]
);
$bind = Subject::firstOrCreate(
    ["code" => "BIND-4"],
    ["name" => "Bahasa Indonesia", "type" => "Muatan Nasional", "kkm" => 75]
);

$wali = Teacher::where("email", "wali4a@floz.test")->first();

$taMtk = TeachingAssignment::firstOrCreate(
    ["subject_id" => $mtk->id, "class_id" => $classId, "academic_year_id" => $ay->id],
    ["teacher_id" => $wali->id]
);
$taBind = TeachingAssignment::firstOrCreate(
    ["subject_id" => $bind->id, "class_id" => $classId, "academic_year_id" => $ay->id],
    ["teacher_id" => $wali->id]
);

$rows = [
    ["ta" => $taMtk,  "day" => 1, "start" => "07:00:00", "end" => "08:30:00"],
    ["ta" => $taBind, "day" => 1, "start" => "08:30:00", "end" => "10:00:00"],
    ["ta" => $taMtk,  "day" => 2, "start" => "07:00:00", "end" => "08:30:00"],
    ["ta" => $taBind, "day" => 3, "start" => "07:00:00", "end" => "08:30:00"],
    ["ta" => $taMtk,  "day" => 4, "start" => "09:00:00", "end" => "10:30:00"],
    ["ta" => $taBind, "day" => 5, "start" => "07:00:00", "end" => "08:30:00"],
];

foreach ($rows as $r) {
    Schedule::firstOrCreate(
        [
            "teaching_assignment_id" => $r["ta"]->id,
            "day_of_week" => $r["day"],
            "start_time" => $r["start"],
        ],
        ["end_time" => $r["end"]]
    );
}

echo "seeded " . count($rows) . " schedules for class " . $classId . PHP_EOL;
' 2>&1 | tail -5
```

Expected: `seeded 6 schedules for class <id>`.

- [ ] **Step 6: Start server and test end-to-end via curl**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src

# Kill any prior server first
pkill -f "artisan serve" 2>&1 || true
sleep 1

php artisan serve --host=127.0.0.1 --port=8000 &
SERVER_PID=$!
sleep 2

TOKEN=$(curl -s -X POST http://127.0.0.1:8000/api/v1/auth/login \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d '{"email":"student@floz.test","password":"password123"}' \
  | php -r 'echo json_decode(file_get_contents("php://stdin"))->data->token;')

curl -s http://127.0.0.1:8000/api/v1/student/schedules \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" \
  | php -r 'echo json_encode(json_decode(file_get_contents("php://stdin")), JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);'

echo ""
```

Expected: envelope `{data: [{day: 1, day_name: "Senin", items: [...2 items]}, {day: 2, ...}, {day: 3, ...}, {day: 4, ...}, {day: 5, ...}]}`. 5 days total, each with the expected items.

Keep the server running — we'll hot-reload the mobile app.

- [ ] **Step 7: Hot reload mobile app**

In the terminal where `flutter run` is active, press `R` (capital R) for a full restart. The Jadwal tab should now show the real schedule screen. Tap into Jadwal tab in the bottom nav and verify:
- 5 day sections rendered (Senin through Jumat)
- Today's day (whatever it is) highlighted with orange accent rail + "Hari ini" pill + orange day-name color
- Other days show slate-300 rail
- Pull to refresh works
- Tapping back to Beranda still shows dashboard

- [ ] **Step 8: Stop server + commit milestone**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
pkill -f "artisan serve" 2>&1 || true
git add floz_mobile/lib/features/student/shared/widgets/student_shell.dart
git commit -m "feat(mobile/student): wire ScheduleScreen into Jadwal tab"
git tag p2.2-schedule-complete
git log --oneline -10
```

---

## P2.2 Definition of Done — Checklist

- [ ] `GET /api/v1/student/schedules` endpoint registered, guarded by `role:student`, returns envelope
- [ ] Legacy `/api/v1/schedules` and `/api/v1/schedules/today` routes removed; `Api\MobileScheduleController` file deleted
- [ ] `ScheduleService` + `ScheduleResource` + `ScheduleFactory` exist; 5 unit + 4 feature tests green
- [ ] Mobile `features/student/schedule` fully rebuilt with clean architecture
- [ ] `ScheduleRepositoryImpl` uses Hive cache (1 day TTL) with stale fallback
- [ ] 5 repo unit tests + 3 widget tests green
- [ ] StudentShell Jadwal tab shows real schedule screen (placeholder removed)
- [ ] Curl test shows full weekly schedule in envelope format
- [ ] Mobile simulator shows day sections with today highlight
- [ ] Backend total: ~94 tests pass (80 prior + 5 unit + 4 feature + 5 mobile = 94)
- [ ] Git tag `p2.2-schedule-complete` created

---

## Notes for the executing agent

- **Schedule uses UUID primary keys.** The factory creates schedules without an explicit `id` — Laravel's `HasUuids` trait generates one on save. Tests that assert on `id` should expect a UUID string, not an integer.
- **`start_time` / `end_time` casting:** The model casts to `datetime:H:i`, so accessing `$schedule->start_time` returns a Carbon object that serializes as `"07:00"` in JSON (5-char string). If your ScheduleService test fails because it gets `"07:00:00"` (8-char), adjust the service to explicitly trim via `substr($s->start_time, 0, 5)`.
- **TeachingAssignment observer auto-creates 16 Meetings.** If you see extra meeting rows after creating a TA in a test, that's expected and harmless — they don't affect schedule queries.
- **P2.1 left a `Route::middleware('role:student')->group(...)` block in `routes/api.php`.** Add the new `/student/schedules` route INSIDE that existing block. Don't create a second block.
- **The `ApiClient.get()` return type.** `_client.get(...)` returns `Response<dynamic>` where `.data` is the decoded JSON body — could be `Map` or `List` depending on endpoint. For schedules, the top-level `data` field is a List, so the datasource extracts it as such.
- **Pattern cohesion:** the Schedule tile visual design mirrors the dashboard's schedule tile for visual continuity. Do NOT redesign — the user has already approved the FlozCard + vertical rail + time-stack pattern in P2.1 UI rebuild.
- **After P2.2 is complete**, return to writing-plans to draft P2.3 (Grades).
