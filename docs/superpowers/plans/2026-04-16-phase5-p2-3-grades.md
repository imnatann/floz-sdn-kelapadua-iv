# Phase 5 — P2.3 Student Grades Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `Nilai` tab placeholder with a working grades view — two backend V1 endpoints (`/api/v1/student/grades` list + `/api/v1/student/grades/{subjectId}` detail), mobile feature with list→detail navigation, Hive cache.

**Architecture:** Same vertical-slice pattern as P2.1/P2.2. Backend migrates `Api\MobileGradeController` → `Api\V1\MobileGradeController` with student-only scope (teacher branch removed — P3). Mobile rebuilds `features/student/grades` with clean architecture. List screen shows subjects with average scores; tapping a subject opens detail screen with score breakdown.

**Tech Stack:** Laravel 12, Pest, Flutter 3.11, Riverpod, Dio, Hive, mocktail

**Spec source:** `docs/superpowers/specs/2026-04-15-phase5-rest-api-mobile-design.md` (Slice #3 Grades-student)

---

## Key Decisions

1. **Endpoints:** `GET /api/v1/student/grades` (list by subject with averages) + `GET /api/v1/student/grades/{subjectId}` (detail scores). Both `role:student` guarded.
2. **List response shape:** `{data: [{subject_id, subject_name, average, grade_count, kkm}]}` — preserved from existing controller plus `kkm` field from Subject model.
3. **Detail response shape:** `{data: {subject: {id, name, kkm}, grades: [{id, daily_test_avg, mid_test, final_test, final_score, predicate, semester, notes, created_at}]}}`
4. **Grade model columns for SD:** `daily_test_avg`, `mid_test`, `final_test`, `final_score`, `predicate`. The `knowledge_score`/`skill_score` fields exist but are SMP/SMA — we show them if non-null.
5. **Cache TTL:** 1 hour (spec §6.4).
6. **Mobile navigation:** GradesListScreen is the tab content; tapping a subject pushes GradeDetailScreen (within the IndexedStack — NOT a go_router push, just a local Navigator inside the tab).
7. **Existing factories:** `GradeFactory`, `SubjectFactory`, `SemesterFactory` all exist from P1 T16.

---

## File Structure

### Backend — create
```
src/app/Http/Controllers/Api/V1/MobileGradeController.php
src/app/Services/Mobile/GradeService.php
src/tests/Unit/Services/Mobile/GradeServiceTest.php
src/tests/Feature/Api/V1/Student/GradeTest.php
```

### Backend — modify
```
src/routes/api.php
```

### Backend — delete
```
src/app/Http/Controllers/Api/MobileGradeController.php
```

### Mobile — delete (broken pre-P1)
```
floz_mobile/lib/features/student/grades/   (entire directory)
```

### Mobile — create
```
floz_mobile/lib/features/student/grades/domain/entities/student_grades.dart
floz_mobile/lib/features/student/grades/domain/repositories/grade_repository.dart
floz_mobile/lib/features/student/grades/data/models/grade_dto.dart
floz_mobile/lib/features/student/grades/data/datasources/grade_remote_datasource.dart
floz_mobile/lib/features/student/grades/data/repositories/grade_repository_impl.dart
floz_mobile/lib/features/student/grades/providers/grade_providers.dart
floz_mobile/lib/features/student/grades/presentation/screens/grades_list_screen.dart
floz_mobile/lib/features/student/grades/presentation/screens/grade_detail_screen.dart
floz_mobile/test/features/student/grades/data/repositories/grade_repository_impl_test.dart
floz_mobile/test/features/student/grades/presentation/screens/grades_list_screen_test.dart
```

### Mobile — modify
```
floz_mobile/lib/core/network/api_endpoints.dart
floz_mobile/lib/features/student/shared/widgets/student_shell.dart
```

---

## Tasks

### Task 1: GradeService + test (TDD)

**Files:**
- Create: `src/tests/Unit/Services/Mobile/GradeServiceTest.php`
- Create: `src/app/Services/Mobile/GradeService.php`

- [ ] **Step 1: Write failing test**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/tests/Unit/Services/Mobile/GradeServiceTest.php`:

```php
<?php

use App\Models\Grade;
use App\Models\Student;
use App\Models\Subject;
use App\Models\User;
use App\Services\Mobile\GradeService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new GradeService();
});

it('returns grades grouped by subject with averages for student', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $subject = Subject::factory()->create();

    Grade::factory()->create([
        'student_id' => $student->id,
        'subject_id' => $subject->id,
        'class_id' => $student->class_id,
        'final_score' => 85.00,
    ]);

    $result = $this->service->listForStudent($user);

    expect($result)->toHaveCount(1);
    expect($result[0])->toHaveKeys(['subject_id', 'subject_name', 'average', 'grade_count', 'kkm']);
    expect($result[0]['subject_name'])->toBe($subject->name);
    expect($result[0]['average'])->toBe(85.0);
    expect($result[0]['grade_count'])->toBe(1);
});

it('returns empty list when student has no grades', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    $result = $this->service->listForStudent($user);

    expect($result)->toBe([]);
});

it('returns detail grades for a specific subject', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $subject = Subject::factory()->create();

    Grade::factory()->create([
        'student_id' => $student->id,
        'subject_id' => $subject->id,
        'class_id' => $student->class_id,
        'daily_test_avg' => 80.00,
        'mid_test' => 85.00,
        'final_test' => 90.00,
        'final_score' => 85.00,
        'predicate' => 'A',
    ]);

    $result = $this->service->detailForStudent($user, $subject->id);

    expect($result['subject'])->toMatchArray(['id' => $subject->id, 'name' => $subject->name]);
    expect($result['grades'])->toHaveCount(1);
    expect($result['grades'][0])->toHaveKeys([
        'id', 'daily_test_avg', 'mid_test', 'final_test',
        'final_score', 'predicate', 'semester',
    ]);
});

it('returns empty grades array when student has no grades in specified subject', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $subject = Subject::factory()->create();

    $result = $this->service->detailForStudent($user, $subject->id);

    expect($result['subject'])->toMatchArray(['id' => $subject->id, 'name' => $subject->name]);
    expect($result['grades'])->toBe([]);
});
```

- [ ] **Step 2: Run test, confirm fail**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest tests/Unit/Services/Mobile/GradeServiceTest.php 2>&1 | tail -10
```

Expected: FAIL ("GradeService not found").

- [ ] **Step 3: Implement GradeService**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Services/Mobile/GradeService.php`:

```php
<?php

namespace App\Services\Mobile;

use App\Models\Grade;
use App\Models\Subject;
use App\Models\User;

class GradeService
{
    /**
     * List grades grouped by subject with averages.
     *
     * @return array<int, array{subject_id:int, subject_name:string, average:float, grade_count:int, kkm:float}>
     */
    public function listForStudent(User $user): array
    {
        $student = $user->student;
        if (! $student) {
            return [];
        }

        return Grade::where('student_id', $student->id)
            ->with('subject')
            ->get()
            ->groupBy('subject_id')
            ->map(function ($subjectGrades, $subjectId) {
                $subject = $subjectGrades->first()->subject;
                $avg = round($subjectGrades->avg('final_score'), 1);

                return [
                    'subject_id' => (int) $subjectId,
                    'subject_name' => $subject->name ?? '-',
                    'average' => (float) $avg,
                    'grade_count' => $subjectGrades->count(),
                    'kkm' => (float) ($subject->kkm ?? 75),
                ];
            })
            ->values()
            ->all();
    }

    /**
     * Detail grades for a specific subject.
     *
     * @return array{subject: array{id:int, name:string, kkm:float}, grades: array}
     */
    public function detailForStudent(User $user, int $subjectId): array
    {
        $student = $user->student;
        $subject = Subject::find($subjectId);

        $grades = [];
        if ($student) {
            $grades = Grade::where('student_id', $student->id)
                ->where('subject_id', $subjectId)
                ->with('semester')
                ->get()
                ->map(fn (Grade $g) => [
                    'id' => $g->id,
                    'daily_test_avg' => (float) ($g->daily_test_avg ?? 0),
                    'mid_test' => (float) ($g->mid_test ?? 0),
                    'final_test' => (float) ($g->final_test ?? 0),
                    'knowledge_score' => $g->knowledge_score ? (float) $g->knowledge_score : null,
                    'skill_score' => $g->skill_score ? (float) $g->skill_score : null,
                    'final_score' => (float) ($g->final_score ?? 0),
                    'predicate' => $g->predicate ?? '-',
                    'semester' => $g->semester ? $g->semester->name : '-',
                    'notes' => $g->notes,
                    'created_at' => $g->created_at?->toIso8601String(),
                ])
                ->all();
        }

        return [
            'subject' => [
                'id' => $subject?->id,
                'name' => $subject?->name ?? '-',
                'kkm' => (float) ($subject?->kkm ?? 75),
            ],
            'grades' => $grades,
        ];
    }
}
```

- [ ] **Step 4: Run test, confirm pass**

```bash
./vendor/bin/pest tests/Unit/Services/Mobile/GradeServiceTest.php
```

Expected: PASS (4 tests).

If `semester` relation doesn't exist on Grade model, check and adjust. The existing model shows relations for `student()` and `subject()` — `semester()` may need to be added OR the test assertion adjusted.

Read `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Models/Grade.php` to check if `semester()` relation exists. If not, use raw column: `'semester' => 'Semester ' . $g->semester_id` or just omit.

- [ ] **Step 5: Run full regression**

```bash
./vendor/bin/pest 2>&1 | tail -3
```

Expected: 93 tests (89 + 4 new).

- [ ] **Step 6: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add src/app/Services/Mobile/GradeService.php \
        src/tests/Unit/Services/Mobile/GradeServiceTest.php
git commit -m "feat(api/v1): add GradeService for student grades list + detail"
```

---

### Task 2: V1 controller + feature test + route registration

**Files:**
- Create: `src/app/Http/Controllers/Api/V1/MobileGradeController.php`
- Create: `src/tests/Feature/Api/V1/Student/GradeTest.php`
- Modify: `src/routes/api.php`

- [ ] **Step 1: Write failing feature test**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/tests/Feature/Api/V1/Student/GradeTest.php`:

```php
<?php

use App\Models\Grade;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('returns grades list by subject for authenticated student', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $subject = Subject::factory()->create();
    Grade::factory()->create([
        'student_id' => $student->id,
        'subject_id' => $subject->id,
        'class_id' => $student->class_id,
        'final_score' => 85.00,
    ]);
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/grades')
        ->assertOk()
        ->assertJsonStructure([
            'data' => ['*' => ['subject_id', 'subject_name', 'average', 'grade_count', 'kkm']],
        ])
        ->assertJsonPath('data.0.subject_name', $subject->name);
});

it('returns grade detail for a subject', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $subject = Subject::factory()->create();
    Grade::factory()->create([
        'student_id' => $student->id,
        'subject_id' => $subject->id,
        'class_id' => $student->class_id,
        'final_score' => 85.00,
        'predicate' => 'A',
    ]);
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/student/grades/{$subject->id}")
        ->assertOk()
        ->assertJsonStructure([
            'data' => [
                'subject' => ['id', 'name', 'kkm'],
                'grades' => ['*' => ['id', 'final_score', 'predicate']],
            ],
        ]);
});

it('returns 401 without token', function () {
    $this->getJson('/api/v1/student/grades')->assertUnauthorized();
});

it('returns 403 for teacher', function () {
    $teacher = Teacher::factory()->create();
    $token = $teacher->user->createToken('mobile')->plainTextToken;
    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/student/grades')
        ->assertForbidden();
});
```

- [ ] **Step 2: Run test, confirm fail**

```bash
./vendor/bin/pest tests/Feature/Api/V1/Student/GradeTest.php 2>&1 | tail -10
```

Expected: FAIL (404).

- [ ] **Step 3: Create V1 controller**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Http/Controllers/Api/V1/MobileGradeController.php`:

```php
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Mobile\GradeService;
use Illuminate\Http\Request;

class MobileGradeController extends Controller
{
    public function __construct(private readonly GradeService $service) {}

    public function index(Request $request)
    {
        return response()->json([
            'data' => $this->service->listForStudent($request->user()),
        ]);
    }

    public function show(Request $request, int $subjectId)
    {
        return response()->json([
            'data' => $this->service->detailForStudent($request->user(), $subjectId),
        ]);
    }
}
```

- [ ] **Step 4: Register routes**

Edit `src/routes/api.php`:

1. Change import: `use App\Http\Controllers\Api\MobileGradeController;` → `use App\Http\Controllers\Api\V1\MobileGradeController;`

2. Remove legacy grade routes:
```php
Route::get('/grades', [MobileGradeController::class, 'index']);
Route::get('/grades/{subjectId}', [MobileGradeController::class, 'show']);
```

3. Inside the `Route::middleware('role:student')->group(...)` block, add:
```php
Route::get('/student/grades', [MobileGradeController::class, 'index']);
Route::get('/student/grades/{subjectId}', [MobileGradeController::class, 'show']);
```

- [ ] **Step 5: Run test, confirm pass**

```bash
./vendor/bin/pest tests/Feature/Api/V1/Student/GradeTest.php
```

Expected: PASS (4 tests).

- [ ] **Step 6: Full regression + commit**

```bash
./vendor/bin/pest 2>&1 | tail -3
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add src/app/Http/Controllers/Api/V1/MobileGradeController.php \
        src/tests/Feature/Api/V1/Student/GradeTest.php \
        src/routes/api.php
git commit -m "feat(api/v1): add student grades list + detail endpoints"
```

---

### Task 3: Delete legacy MobileGradeController

- [ ] **Step 1: Grep for stale references, delete, regression, commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
# Grep tool: pattern `App\\Http\\Controllers\\Api\\MobileGradeController` in src/
rm src/app/Http/Controllers/Api/MobileGradeController.php
cd src && ./vendor/bin/pest 2>&1 | tail -3
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add -A src/app/Http/Controllers/Api/
git commit -m "refactor(api): remove legacy Api\\MobileGradeController"
```

---

### Task 4: Delete pre-P1 broken mobile grades code

- [ ] **Step 1: Delete + analyze + commit**

```bash
rm -rf /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/grades
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile && flutter analyze 2>&1 | grep -c "error •"
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add -A floz_mobile/lib/features/student/grades
git commit -m "chore(mobile): remove pre-P1 broken grades code"
```

---

### Task 5: Mobile domain + DTO + datasource + endpoint constants

**Files to create:** entity, repo interface, DTO, datasource  
**Files to modify:** `api_endpoints.dart`

- [ ] **Step 1: Scaffold directories**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/grades/domain/entities
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/grades/domain/repositories
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/grades/data/models
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/grades/data/datasources
```

- [ ] **Step 2: Create entity**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/grades/domain/entities/student_grades.dart`:

```dart
class SubjectGradeSummary {
  final int subjectId;
  final String subjectName;
  final double average;
  final int gradeCount;
  final double kkm;

  const SubjectGradeSummary({
    required this.subjectId,
    required this.subjectName,
    required this.average,
    required this.gradeCount,
    required this.kkm,
  });

  bool get aboveKkm => average >= kkm;
}

class GradeDetail {
  final int id;
  final double dailyTestAvg;
  final double midTest;
  final double finalTest;
  final double? knowledgeScore;
  final double? skillScore;
  final double finalScore;
  final String predicate;
  final String semester;
  final String? notes;
  final DateTime? createdAt;

  const GradeDetail({
    required this.id,
    required this.dailyTestAvg,
    required this.midTest,
    required this.finalTest,
    this.knowledgeScore,
    this.skillScore,
    required this.finalScore,
    required this.predicate,
    required this.semester,
    this.notes,
    this.createdAt,
  });
}

class SubjectGradeInfo {
  final int subjectId;
  final String subjectName;
  final double kkm;
  final List<GradeDetail> grades;

  const SubjectGradeInfo({
    required this.subjectId,
    required this.subjectName,
    required this.kkm,
    required this.grades,
  });
}
```

- [ ] **Step 3: Create repository interface**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/grades/domain/repositories/grade_repository.dart`:

```dart
import '../../../../../core/error/result.dart';
import '../entities/student_grades.dart';

abstract class GradeRepository {
  Future<Result<List<SubjectGradeSummary>>> fetchList({bool forceRefresh = false});
  Future<Result<SubjectGradeInfo>> fetchDetail(int subjectId);
}
```

- [ ] **Step 4: Create DTO**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/grades/data/models/grade_dto.dart`:

```dart
import '../../domain/entities/student_grades.dart';

class GradeDto {
  static List<SubjectGradeSummary> listFromJson(List<dynamic> json) {
    return json
        .whereType<Map<String, dynamic>>()
        .map((j) => SubjectGradeSummary(
              subjectId: (j['subject_id'] as num?)?.toInt() ?? 0,
              subjectName: j['subject_name'] as String? ?? '-',
              average: (j['average'] as num?)?.toDouble() ?? 0,
              gradeCount: (j['grade_count'] as num?)?.toInt() ?? 0,
              kkm: (j['kkm'] as num?)?.toDouble() ?? 75,
            ))
        .toList(growable: false);
  }

  static SubjectGradeInfo detailFromJson(Map<String, dynamic> json) {
    final subjectJson = json['subject'] as Map<String, dynamic>? ?? {};
    final gradesList = (json['grades'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_gradeDetailFromJson)
        .toList(growable: false);

    return SubjectGradeInfo(
      subjectId: (subjectJson['id'] as num?)?.toInt() ?? 0,
      subjectName: subjectJson['name'] as String? ?? '-',
      kkm: (subjectJson['kkm'] as num?)?.toDouble() ?? 75,
      grades: gradesList,
    );
  }

  static GradeDetail _gradeDetailFromJson(Map<String, dynamic> j) {
    return GradeDetail(
      id: (j['id'] as num?)?.toInt() ?? 0,
      dailyTestAvg: (j['daily_test_avg'] as num?)?.toDouble() ?? 0,
      midTest: (j['mid_test'] as num?)?.toDouble() ?? 0,
      finalTest: (j['final_test'] as num?)?.toDouble() ?? 0,
      knowledgeScore: (j['knowledge_score'] as num?)?.toDouble(),
      skillScore: (j['skill_score'] as num?)?.toDouble(),
      finalScore: (j['final_score'] as num?)?.toDouble() ?? 0,
      predicate: j['predicate'] as String? ?? '-',
      semester: j['semester'] as String? ?? '-',
      notes: j['notes'] as String?,
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
    );
  }
}
```

- [ ] **Step 5: Create datasource**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/grades/data/datasources/grade_remote_datasource.dart`:

```dart
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/student_grades.dart';
import '../models/grade_dto.dart';

abstract class GradeRemoteDataSource {
  Future<List<SubjectGradeSummary>> fetchList();
  Future<SubjectGradeInfo> fetchDetail(int subjectId);
}

class GradeRemoteDataSourceImpl implements GradeRemoteDataSource {
  final ApiClient _client;
  GradeRemoteDataSourceImpl(this._client);

  @override
  Future<List<SubjectGradeSummary>> fetchList() async {
    final res = await _client.get(ApiEndpoints.studentGrades);
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as List? ?? const [];
    return GradeDto.listFromJson(data);
  }

  @override
  Future<SubjectGradeInfo> fetchDetail(int subjectId) async {
    final res = await _client.get('${ApiEndpoints.studentGrades}/$subjectId');
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return GradeDto.detailFromJson(data);
  }
}
```

- [ ] **Step 6: Add endpoint constants**

Edit `floz_mobile/lib/core/network/api_endpoints.dart`. Add after `studentSchedules`:

```dart
  static const String studentGrades = '/student/grades';
```

- [ ] **Step 7: Analyze + commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze lib/features/student/grades/ lib/core/network/api_endpoints.dart 2>&1 | tail -10
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add floz_mobile/lib/features/student/grades/domain \
        floz_mobile/lib/features/student/grades/data \
        floz_mobile/lib/core/network/api_endpoints.dart
git commit -m "feat(mobile/grades): domain entities, DTO, remote datasource"
```

---

### Task 6: Repository impl with cache + test (TDD)

**Files to create:**
- `floz_mobile/lib/features/student/grades/data/repositories/grade_repository_impl.dart`
- `floz_mobile/test/features/student/grades/data/repositories/grade_repository_impl_test.dart`

- [ ] **Step 1: Write failing test, then implement, confirm GREEN**

Follow exact same pattern as P2.1 Task 10+11 and P2.2 Task 9. Repository impl:
- `fetchList`: cache key `'list'`, 1h TTL, stale fallback on NetworkException
- `fetchDetail`: NO cache (detail view always fresh from network — keeps it simple)

Test cases for `fetchList` (5 tests): happy+cache-write, stale fallback, network+empty, fresh cache hit, forceRefresh bypass.
Test case for `fetchDetail` (2 tests): happy path, network failure → FailureResult.

Total: 7 tests.

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/grades/data/repositories
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/test/features/student/grades/data/repositories
```

The repository impl caches the list as `List<Map<String, dynamic>>` (serialized from entities via a `_toJson` method). Detail endpoint does NOT cache.

- [ ] **Step 2: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add floz_mobile/lib/features/student/grades/data/repositories \
        floz_mobile/test/features/student/grades/data/repositories
git commit -m "feat(mobile/grades): add GradeRepositoryImpl with Hive cache"
```

---

### Task 7: Providers + GradesListScreen + GradeDetailScreen + widget test + wire to shell

This is the final combined task for P2.3. Creates:
- `providers/grade_providers.dart`
- `presentation/screens/grades_list_screen.dart`
- `presentation/screens/grade_detail_screen.dart`
- `test/.../grades_list_screen_test.dart`
- Updates `student_shell.dart` (replace Nilai tab placeholder)

- [ ] **Step 1: Create providers**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/grades/providers
```

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/grades/providers/grade_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/cache_box.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/grade_remote_datasource.dart';
import '../data/repositories/grade_repository_impl.dart';
import '../domain/entities/student_grades.dart';
import '../domain/repositories/grade_repository.dart';

final gradeCacheProvider = Provider<CacheBox<dynamic>>((ref) {
  return CacheBox<dynamic>(name: 'grade_cache', ttl: const Duration(hours: 1));
});

final gradeRemoteProvider = Provider<GradeRemoteDataSource>((ref) {
  return GradeRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final gradeRepositoryProvider = Provider<GradeRepository>((ref) {
  return GradeRepositoryImpl(
    remote: ref.watch(gradeRemoteProvider),
    cache: ref.watch(gradeCacheProvider),
  );
});

class GradeListNotifier extends AsyncNotifier<List<SubjectGradeSummary>> {
  @override
  Future<List<SubjectGradeSummary>> build() async {
    final result = await ref.read(gradeRepositoryProvider).fetchList();
    switch (result) {
      case Success(:final data):
        return data;
      case FailureResult(:final failure):
        throw failure;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await ref.read(gradeRepositoryProvider).fetchList(forceRefresh: true);
    state = await AsyncValue.guard(() async {
      switch (result) {
        case Success(:final data):
          return data;
        case FailureResult(:final failure):
          throw failure;
      }
    });
  }
}

final gradeListNotifierProvider =
    AsyncNotifierProvider<GradeListNotifier, List<SubjectGradeSummary>>(GradeListNotifier.new);

final gradeDetailProvider = FutureProvider.family<SubjectGradeInfo, int>((ref, subjectId) async {
  final result = await ref.read(gradeRepositoryProvider).fetchDetail(subjectId);
  switch (result) {
    case Success(:final data):
      return data;
    case FailureResult(:final failure):
      throw failure;
  }
});
```

- [ ] **Step 2: Create GradesListScreen**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/grades/presentation/screens
```

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/grades/presentation/screens/grades_list_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/student_grades.dart';
import '../../providers/grade_providers.dart';
import 'grade_detail_screen.dart';

class GradesListScreen extends ConsumerWidget {
  const GradesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gradeListNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary600,
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          onRefresh: () => ref.read(gradeListNotifierProvider.notifier).refresh(),
          child: state.when(
            data: (grades) => _GradesList(grades: grades),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary600)),
            error: (err, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                ErrorState(
                  message: err is Failure ? err.message : 'Gagal memuat nilai',
                  onRetry: () => ref.read(gradeListNotifierProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradesList extends StatelessWidget {
  const _GradesList({required this.grades});
  final List<SubjectGradeSummary> grades;

  @override
  Widget build(BuildContext context) {
    if (grades.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                ),
                child: const Icon(Icons.grade_outlined, size: 36, color: AppColors.primary600),
              ),
              const SizedBox(height: 20),
              const Text('Belum ada nilai', style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.slate900)),
              const SizedBox(height: 6),
              const Text('Nilai akan muncul setelah guru memasukkan penilaian.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.slate500, height: 1.5)),
            ],
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: grades.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final g = grades[i];
        return StaggeredEntry(
          index: i,
          child: FlozCard(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GradeDetailScreen(
                    subjectId: g.subjectId,
                    subjectName: g.subjectName,
                  ),
                ),
              );
            },
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: g.aboveKkm ? AppColors.success50 : AppColors.danger50,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  ),
                  child: Center(
                    child: Text(
                      g.average.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: g.aboveKkm ? AppColors.success500 : AppColors.danger500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.subjectName, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.slate900, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('KKM ${g.kkm.toStringAsFixed(0)} • ${g.gradeCount} penilaian', style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.slate400, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Create GradeDetailScreen**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student/grades/presentation/screens/grade_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/student_grades.dart';
import '../../providers/grade_providers.dart';

class GradeDetailScreen extends ConsumerWidget {
  const GradeDetailScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  final int subjectId;
  final String subjectName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gradeDetailProvider(subjectId));

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(title: Text(subjectName)),
      body: state.when(
        data: (info) => _DetailContent(info: info),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary600)),
        error: (err, _) => ErrorState(
          message: err is Failure ? err.message : 'Gagal memuat detail nilai',
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.info});
  final SubjectGradeInfo info;

  @override
  Widget build(BuildContext context) {
    if (info.grades.isEmpty) {
      return const Center(child: Text('Belum ada nilai untuk mata pelajaran ini.', style: TextStyle(color: AppColors.slate500)));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: info.grades.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final g = info.grades[i];
        return StaggeredEntry(
          index: i,
          child: FlozCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                      ),
                      child: Text(g.semester, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary700)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: g.finalScore >= info.kkm ? AppColors.success50 : AppColors.danger50,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                      ),
                      child: Text(
                        g.predicate,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: g.finalScore >= info.kkm ? AppColors.success500 : AppColors.danger500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ScoreRow('Rata-rata Harian', g.dailyTestAvg),
                _ScoreRow('UTS', g.midTest),
                _ScoreRow('UAS', g.finalTest),
                if (g.knowledgeScore != null) _ScoreRow('Pengetahuan', g.knowledgeScore!),
                if (g.skillScore != null) _ScoreRow('Keterampilan', g.skillScore!),
                const Divider(height: 20, color: AppColors.slate100),
                _ScoreRow('Nilai Akhir', g.finalScore, isBold: true),
                if (g.notes != null && g.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Catatan: ${g.notes}', style: const TextStyle(fontSize: 12, color: AppColors.slate600, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(this.label, this.value, {this.isBold = false});
  final String label;
  final double value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.slate600, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500))),
          Text(value.toStringAsFixed(1), style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: AppColors.slate900)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Create widget test**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/test/features/student/grades/presentation/screens
```

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/test/features/student/grades/presentation/screens/grades_list_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/student/grades/domain/entities/student_grades.dart';
import 'package:floz_mobile/features/student/grades/domain/repositories/grade_repository.dart';
import 'package:floz_mobile/features/student/grades/presentation/screens/grades_list_screen.dart';
import 'package:floz_mobile/features/student/grades/providers/grade_providers.dart';

class _MockRepo extends Mock implements GradeRepository {}

const _fixture = [
  SubjectGradeSummary(subjectId: 1, subjectName: 'Matematika', average: 85, gradeCount: 2, kkm: 75),
  SubjectGradeSummary(subjectId: 2, subjectName: 'Bahasa Indonesia', average: 70, gradeCount: 1, kkm: 75),
];

void main() {
  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [gradeRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows subject list with scores', (tester) async {
    when(() => repo.fetchList(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(_fixture));

    await tester.pumpWidget(wrap(const GradesListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Matematika'), findsOneWidget);
    expect(find.text('85'), findsOneWidget);
    expect(find.text('Bahasa Indonesia'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
  });

  testWidgets('shows empty state', (tester) async {
    when(() => repo.fetchList(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(<SubjectGradeSummary>[]));

    await tester.pumpWidget(wrap(const GradesListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada nilai'), findsOneWidget);
  });

  testWidgets('shows error with retry', (tester) async {
    when(() => repo.fetchList(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const FailureResult(NetworkFailure('offline')));

    await tester.pumpWidget(wrap(const GradesListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('offline'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Wire into StudentShell**

Edit `floz_mobile/lib/features/student/shared/widgets/student_shell.dart`:

Add import:
```dart
import '../../grades/presentation/screens/grades_list_screen.dart';
```

Replace `TabPlaceholder(title: 'Nilai')` with `GradesListScreen()` in the IndexedStack.

- [ ] **Step 6: Run all tests + analyze + commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter test test/core test/features 2>&1 | tail -5
flutter analyze lib/features/student/grades lib/features/student/shared 2>&1 | tail -10
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add floz_mobile/lib/features/student/grades/providers \
        floz_mobile/lib/features/student/grades/presentation \
        floz_mobile/test/features/student/grades \
        floz_mobile/lib/features/student/shared/widgets/student_shell.dart
git commit -m "feat(mobile/grades): GradesListScreen + GradeDetailScreen + wire to Nilai tab"
git tag p2.3-grades-complete
```

---

## P2.3 Definition of Done

- [ ] `GET /api/v1/student/grades` + `/api/v1/student/grades/{subjectId}` exist, role:student guarded
- [ ] Legacy grade routes + controller deleted
- [ ] GradeService: 4 unit tests + 4 feature tests pass
- [ ] Mobile: clean architecture, repo with Hive 1h cache, list+detail screens
- [ ] StudentShell Nilai tab shows GradesListScreen → tap → GradeDetailScreen
- [ ] 3 widget tests pass
- [ ] Backend 97+ tests, Mobile 50+ tests
- [ ] Git tag `p2.3-grades-complete`

---

## Notes for executing agent

- **GradeFactory already exists** from P1 T16. Use it. Also SubjectFactory, SemesterFactory exist.
- **Grade model relations:** `student()`, `subject()` exist. Check if `semester()` exists before using it — the model may NOT have a semester() relation defined. If missing, read the model first and either add the relation OR use raw `semester_id`.
- **`description` column** is in fillable on web Grade model but NOT in the P2.3 API response. That's intentional — description is internal teacher notes, not student-facing.
- **Navigation pattern:** GradesListScreen uses `Navigator.of(context).push(MaterialPageRoute(...))` for detail — NOT go_router. This keeps it simple within the IndexedStack tab without global routing.
- **Score color logic:** `aboveKkm` getter on `SubjectGradeSummary` compares `average >= kkm`. Green for above, red for below. Same color semantics as attendance card.
- **Same safety rules as P2.1/P2.2:** NEVER run migrate. NEVER modify `.env`. Tests use RefreshDatabase.
