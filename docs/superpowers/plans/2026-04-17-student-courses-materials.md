# Student Courses & Materials Viewer — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable mobile students to view their subjects, drill into 16 meetings per subject, and access materials (file/link/text) uploaded by teachers via web admin.

**Architecture:** Backend exposes 3 read-only endpoints under `role:student`. Mobile adds a `student/courses` feature with two screens (CourseDetail, MeetingDetail) plus an inline horizontal-scroll section on the existing Beranda dashboard. Network-first, no cache layer (matches recap convention).

**Tech Stack:** Laravel 12, Pest 3, Sanctum, Flutter 3.11, Riverpod, Dio, mocktail, url_launcher

---

## Key Decisions

1. **Endpoints:** `GET /api/v1/student/courses`, `GET /api/v1/student/courses/{ta}/meetings`, `GET /api/v1/student/meetings/{meeting}`. All `role:student` guarded. Service-layer authz: student's class_id must match TA's class_id (throw `AuthorizationException` otherwise).
2. **Response shapes** — match spec section "Service" verbatim. Detail in tasks.
3. **No CoursesListScreen** — entry is inline horizontal scroll on Dashboard.
4. **Locked meetings visible but disabled** — shows `is_locked` flag, mobile disables tap with "Belum dibuka" affordance.
5. **External browser for files/links** — `url_launcher` (add to pubspec if not present). No in-app PDF preview.
6. **No cache** — pull-to-refresh on each screen.

---

## File Structure

### Backend — create
```
src/app/Services/Mobile/CoursesService.php
src/app/Http/Controllers/Api/V1/MobileStudentCoursesController.php
src/tests/Unit/Services/Mobile/CoursesServiceTest.php
src/tests/Feature/Api/V1/Student/CoursesTest.php
```

### Backend — modify
```
src/routes/api.php
```

### Mobile — create
```
floz_mobile/lib/features/student/courses/domain/entities/course.dart
floz_mobile/lib/features/student/courses/domain/entities/meeting_summary.dart
floz_mobile/lib/features/student/courses/domain/entities/meeting_detail.dart
floz_mobile/lib/features/student/courses/domain/entities/material_item.dart
floz_mobile/lib/features/student/courses/domain/repositories/courses_repository.dart
floz_mobile/lib/features/student/courses/data/models/course_dto.dart
floz_mobile/lib/features/student/courses/data/models/meetings_dto.dart
floz_mobile/lib/features/student/courses/data/models/meeting_detail_dto.dart
floz_mobile/lib/features/student/courses/data/datasources/courses_remote_datasource.dart
floz_mobile/lib/features/student/courses/data/repositories/courses_repository_impl.dart
floz_mobile/lib/features/student/courses/providers/courses_providers.dart
floz_mobile/lib/features/student/courses/presentation/screens/course_detail_screen.dart
floz_mobile/lib/features/student/courses/presentation/screens/meeting_detail_screen.dart
floz_mobile/test/features/student/courses/data/repositories/courses_repository_impl_test.dart
floz_mobile/test/features/student/courses/presentation/screens/course_detail_screen_test.dart
floz_mobile/test/features/student/courses/presentation/screens/meeting_detail_screen_test.dart
```

### Mobile — modify
```
floz_mobile/lib/core/network/api_endpoints.dart                                            (add 3 endpoint constants)
floz_mobile/lib/features/student/dashboard/presentation/screens/dashboard_screen.dart      (add _CoursesSection)
floz_mobile/lib/features/student/dashboard/data/models/dashboard_dto.dart                  (parse new courses array if backend includes it — see Task 5)
floz_mobile/pubspec.yaml                                                                   (add url_launcher if not present)
```

---

## Tasks

### Task 1: CoursesService TDD

**Files:**
- Create: `src/app/Services/Mobile/CoursesService.php`
- Test: `src/tests/Unit/Services/Mobile/CoursesServiceTest.php`

**Service spec:**

```php
namespace App\Services\Mobile;

use App\Models\Meeting;
use App\Models\TeachingAssignment;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;

class CoursesService
{
    /** @return array<int, array<string, mixed>> */
    public function listForStudent(User $user): array
    {
        $student = $user->student;
        if (! $student || ! $student->class_id) {
            return [];
        }

        return TeachingAssignment::where('class_id', $student->class_id)
            ->with(['subject', 'teacher'])
            ->withCount('meetings')
            ->get()
            ->map(fn (TeachingAssignment $ta) => [
                'id' => $ta->id,
                'subject_name' => $ta->subject->name ?? '-',
                'teacher_name' => $ta->teacher->name ?? '-',
                'meeting_count' => $ta->meetings_count,
                'material_count' => Meeting::where('teaching_assignment_id', $ta->id)
                    ->withCount('materials')
                    ->get()
                    ->sum('materials_count'),
            ])
            ->values()
            ->all();
    }

    public function meetingsFor(User $user, int $teachingAssignmentId): array
    {
        $student = $user->student;
        $ta = TeachingAssignment::with(['subject', 'teacher', 'schoolClass'])->findOrFail($teachingAssignmentId);
        $this->authorize($student, $ta);

        $meetings = Meeting::where('teaching_assignment_id', $ta->id)
            ->withCount('materials')
            ->orderBy('meeting_number')
            ->get()
            ->map(fn (Meeting $m) => [
                'id' => $m->id,
                'meeting_number' => $m->meeting_number,
                'title' => $m->title,
                'description' => $m->description,
                'is_locked' => (bool) $m->is_locked,
                'material_count' => $m->materials_count,
            ])
            ->all();

        return [
            'teaching_assignment' => [
                'id' => $ta->id,
                'subject_name' => $ta->subject->name ?? '-',
                'teacher_name' => $ta->teacher->name ?? '-',
                'class_name' => $ta->schoolClass->name ?? '-',
            ],
            'meetings' => $meetings,
        ];
    }

    public function meetingDetail(User $user, int $meetingId): array
    {
        $meeting = Meeting::with(['materials', 'teachingAssignment.subject', 'teachingAssignment.schoolClass'])
            ->findOrFail($meetingId);
        $this->authorize($user->student, $meeting->teachingAssignment);

        return [
            'meeting' => [
                'id' => $meeting->id,
                'meeting_number' => $meeting->meeting_number,
                'title' => $meeting->title,
                'description' => $meeting->description,
                'is_locked' => (bool) $meeting->is_locked,
                'subject_name' => $meeting->teachingAssignment->subject->name ?? '-',
                'class_name' => $meeting->teachingAssignment->schoolClass->name ?? '-',
            ],
            'materials' => $meeting->materials
                ->sortBy('sort_order')
                ->values()
                ->map(fn ($m) => [
                    'id' => $m->id,
                    'title' => $m->title,
                    'type' => $m->type,
                    'content' => $m->content,
                    'file_name' => $m->file_name,
                    'file_size' => $m->file_size,
                    'file_url' => $m->file_path ? asset('storage/'.$m->file_path) : null,
                    'url' => $m->url,
                    'sort_order' => $m->sort_order,
                ])
                ->all(),
        ];
    }

    private function authorize($student, TeachingAssignment $ta): void
    {
        if (! $student || $ta->class_id !== $student->class_id) {
            throw new AuthorizationException('Anda tidak memiliki akses ke mata pelajaran ini.');
        }
    }
}
```

**Test cases (Pest, 6 total) — write all FIRST, watch them fail, then implement:**

```php
<?php

use App\Models\Meeting;
use App\Models\MeetingMaterial;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use App\Services\Mobile\CoursesService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new CoursesService();
});

it('listForStudent returns subjects for student class with meeting + material counts', function () {
    $class = SchoolClass::factory()->create();
    $student = Student::factory()->for($class)->create();
    $user = User::factory()->create(['email' => $student->email, 'role' => 'student']);

    $teacher = Teacher::factory()->create();
    $subject = Subject::factory()->create(['name' => 'Matematika']);
    $ta = TeachingAssignment::factory()
        ->for($teacher)
        ->for($subject)
        ->create(['class_id' => $class->id]);

    $meeting1 = Meeting::factory()->create(['teaching_assignment_id' => $ta->id, 'meeting_number' => 1]);
    $meeting2 = Meeting::factory()->create(['teaching_assignment_id' => $ta->id, 'meeting_number' => 2]);
    MeetingMaterial::factory()->create(['meeting_id' => $meeting1->id]);
    MeetingMaterial::factory()->count(2)->create(['meeting_id' => $meeting2->id]);

    $result = $this->service->listForStudent($user);

    expect($result)->toHaveCount(1);
    expect($result[0])->toMatchArray([
        'id' => $ta->id,
        'subject_name' => 'Matematika',
        'teacher_name' => $teacher->name,
        'meeting_count' => 2,
        'material_count' => 3,
    ]);
});

it('listForStudent returns empty array when student has no class', function () {
    $user = User::factory()->create(['role' => 'student']);
    expect($this->service->listForStudent($user))->toBe([]);
});

it('meetingsFor returns 16 meetings with material counts', function () {
    $class = SchoolClass::factory()->create();
    $student = Student::factory()->for($class)->create();
    $user = User::factory()->create(['email' => $student->email, 'role' => 'student']);

    $ta = TeachingAssignment::factory()->create(['class_id' => $class->id]);
    Meeting::generateForTeachingAssignment($ta->id);

    $first = Meeting::where('teaching_assignment_id', $ta->id)->orderBy('meeting_number')->first();
    MeetingMaterial::factory()->count(3)->create(['meeting_id' => $first->id]);

    $result = $this->service->meetingsFor($user, $ta->id);

    expect($result['teaching_assignment'])->toHaveKeys(['id', 'subject_name', 'teacher_name', 'class_name']);
    expect($result['meetings'])->toHaveCount(16);
    expect($result['meetings'][0])->toMatchArray([
        'meeting_number' => 1,
        'material_count' => 3,
        'is_locked' => false,
    ]);
    // UTS (15) and UAS (16) are locked by default per Meeting::generateForTeachingAssignment
    $uts = collect($result['meetings'])->firstWhere('meeting_number', 15);
    expect($uts['is_locked'])->toBeTrue();
});

it('meetingsFor throws AuthorizationException when student class does not match TA class', function () {
    $studentClass = SchoolClass::factory()->create();
    $otherClass = SchoolClass::factory()->create();
    $student = Student::factory()->for($studentClass)->create();
    $user = User::factory()->create(['email' => $student->email, 'role' => 'student']);

    $ta = TeachingAssignment::factory()->create(['class_id' => $otherClass->id]);
    Meeting::generateForTeachingAssignment($ta->id);

    expect(fn () => $this->service->meetingsFor($user, $ta->id))
        ->toThrow(AuthorizationException::class);
});

it('meetingDetail returns meeting with materials sorted by sort_order', function () {
    $class = SchoolClass::factory()->create();
    $student = Student::factory()->for($class)->create();
    $user = User::factory()->create(['email' => $student->email, 'role' => 'student']);

    $ta = TeachingAssignment::factory()->create(['class_id' => $class->id]);
    $meeting = Meeting::factory()->create([
        'teaching_assignment_id' => $ta->id,
        'meeting_number' => 1,
        'title' => 'Pertemuan 1',
        'is_locked' => false,
    ]);

    MeetingMaterial::factory()->create([
        'meeting_id' => $meeting->id,
        'title' => 'Slide',
        'type' => 'file',
        'file_path' => 'materials/slide.pdf',
        'file_name' => 'slide.pdf',
        'file_size' => 102400,
        'sort_order' => 2,
    ]);
    MeetingMaterial::factory()->create([
        'meeting_id' => $meeting->id,
        'title' => 'Video YouTube',
        'type' => 'link',
        'url' => 'https://youtube.com/watch?v=xyz',
        'sort_order' => 1,
    ]);

    $result = $this->service->meetingDetail($user, $meeting->id);

    expect($result['meeting'])->toMatchArray([
        'id' => $meeting->id,
        'meeting_number' => 1,
        'title' => 'Pertemuan 1',
        'is_locked' => false,
    ]);
    expect($result['materials'])->toHaveCount(2);
    expect($result['materials'][0]['title'])->toBe('Video YouTube');
    expect($result['materials'][0]['type'])->toBe('link');
    expect($result['materials'][1]['title'])->toBe('Slide');
    expect($result['materials'][1]['file_url'])->toContain('storage/materials/slide.pdf');
});

it('meetingDetail throws AuthorizationException when student class mismatch', function () {
    $studentClass = SchoolClass::factory()->create();
    $otherClass = SchoolClass::factory()->create();
    $student = Student::factory()->for($studentClass)->create();
    $user = User::factory()->create(['email' => $student->email, 'role' => 'student']);

    $ta = TeachingAssignment::factory()->create(['class_id' => $otherClass->id]);
    $meeting = Meeting::factory()->create(['teaching_assignment_id' => $ta->id, 'meeting_number' => 1]);

    expect(fn () => $this->service->meetingDetail($user, $meeting->id))
        ->toThrow(AuthorizationException::class);
});
```

**Steps:**

- [ ] **1.1 Read sibling services** — open `src/app/Services/Mobile/RecapService.php` and `AssignmentService.php` to absorb conventions (5 min).
- [ ] **1.2 Write the test file** — create `CoursesServiceTest.php` with all 6 tests above. Run `cd src && php artisan test --env=testing tests/Unit/Services/Mobile/CoursesServiceTest.php` — expect all to fail with "Class CoursesService not found".
- [ ] **1.3 Implement CoursesService** — paste the service code above into `src/app/Services/Mobile/CoursesService.php`.
- [ ] **1.4 Run tests** — `cd src && php artisan test --env=testing tests/Unit/Services/Mobile/CoursesServiceTest.php`. Expect 6/6 pass.
- [ ] **1.5 Self-review + commit:**
  ```bash
  git add src/app/Services/Mobile/CoursesService.php src/tests/Unit/Services/Mobile/CoursesServiceTest.php
  git commit -m "feat(api/courses): CoursesService for student materials viewer (TDD)"
  ```

---

### Task 2: V1 CoursesController + Feature Tests + Routes

**Files:**
- Create: `src/app/Http/Controllers/Api/V1/MobileStudentCoursesController.php`
- Create: `src/tests/Feature/Api/V1/Student/CoursesTest.php`
- Modify: `src/routes/api.php` (add 3 routes inside `role:student` block + 1 import)

**Controller spec:**

```php
namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Mobile\CoursesService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MobileStudentCoursesController extends Controller
{
    public function __construct(private readonly CoursesService $service) {}

    public function index(Request $request): JsonResponse
    {
        return response()->json(['data' => $this->service->listForStudent($request->user())]);
    }

    public function meetings(Request $request, int $taId): JsonResponse
    {
        return response()->json(['data' => $this->service->meetingsFor($request->user(), $taId)]);
    }

    public function meeting(Request $request, int $meetingId): JsonResponse
    {
        return response()->json(['data' => $this->service->meetingDetail($request->user(), $meetingId)]);
    }
}
```

**Routes (add inside `Route::middleware('role:student')->group(...)` block in `src/routes/api.php`):**

```php
use App\Http\Controllers\Api\V1\MobileStudentCoursesController;

// inside role:student block:
Route::get('/student/courses', [MobileStudentCoursesController::class, 'index']);
Route::get('/student/courses/{ta}/meetings', [MobileStudentCoursesController::class, 'meetings']);
Route::get('/student/meetings/{meeting}', [MobileStudentCoursesController::class, 'meeting']);
```

**Test cases (Pest, 5 total) — mirror `RecapTest.php` style with Sanctum bearer tokens:**

```php
<?php

use App\Models\Meeting;
use App\Models\MeetingMaterial;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->class = SchoolClass::factory()->create();
    $this->student = Student::factory()->for($this->class)->create();
    $this->user = User::factory()->create(['email' => $this->student->email, 'role' => 'student']);
    $this->token = $this->user->createToken('mobile')->plainTextToken;
});

it('GET /student/courses returns subjects for the student class', function () {
    $teacher = Teacher::factory()->create();
    $ta = TeachingAssignment::factory()->for($teacher)->create(['class_id' => $this->class->id]);
    Meeting::factory()->create(['teaching_assignment_id' => $ta->id, 'meeting_number' => 1]);

    $this->withHeader('Authorization', "Bearer {$this->token}")
        ->getJson('/api/v1/student/courses')
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.id', $ta->id);
});

it('GET /student/courses/{ta}/meetings returns meetings list', function () {
    $ta = TeachingAssignment::factory()->create(['class_id' => $this->class->id]);
    Meeting::generateForTeachingAssignment($ta->id);

    $this->withHeader('Authorization', "Bearer {$this->token}")
        ->getJson("/api/v1/student/courses/{$ta->id}/meetings")
        ->assertOk()
        ->assertJsonCount(16, 'data.meetings')
        ->assertJsonPath('data.teaching_assignment.id', $ta->id);
});

it('GET /student/meetings/{meeting} returns materials list', function () {
    $ta = TeachingAssignment::factory()->create(['class_id' => $this->class->id]);
    $meeting = Meeting::factory()->create([
        'teaching_assignment_id' => $ta->id,
        'meeting_number' => 1,
        'is_locked' => false,
    ]);
    MeetingMaterial::factory()->create([
        'meeting_id' => $meeting->id,
        'title' => 'Slide',
        'type' => 'file',
        'file_path' => 'materials/slide.pdf',
    ]);

    $this->withHeader('Authorization', "Bearer {$this->token}")
        ->getJson("/api/v1/student/meetings/{$meeting->id}")
        ->assertOk()
        ->assertJsonPath('data.meeting.id', $meeting->id)
        ->assertJsonCount(1, 'data.materials');
});

it('returns 403 when student tries to access TA from another class', function () {
    $otherClass = SchoolClass::factory()->create();
    $ta = TeachingAssignment::factory()->create(['class_id' => $otherClass->id]);
    Meeting::generateForTeachingAssignment($ta->id);

    $this->withHeader('Authorization', "Bearer {$this->token}")
        ->getJson("/api/v1/student/courses/{$ta->id}/meetings")
        ->assertForbidden();
});

it('returns 401 without token on courses endpoint', function () {
    $this->getJson('/api/v1/student/courses')->assertUnauthorized();
});
```

**Steps:**

- [ ] **2.1 Read siblings** — `src/app/Http/Controllers/Api/V1/MobileTeacherRecapController.php` and `src/tests/Feature/Api/V1/Teacher/RecapTest.php` for conventions.
- [ ] **2.2 Write feature test file** — paste 5 tests above into `src/tests/Feature/Api/V1/Student/CoursesTest.php`. Run, expect failures (route not found / 404).
- [ ] **2.3 Implement controller** — paste controller code above.
- [ ] **2.4 Add routes** — add the import at top of `src/routes/api.php` and 3 GET routes inside the `role:student` block.
- [ ] **2.5 Run tests** — `cd src && php artisan test --env=testing tests/Feature/Api/V1/Student/CoursesTest.php`. Expect 5/5 pass.
- [ ] **2.6 Run full backend regression** — `php artisan test --env=testing` to ensure nothing else broke.
- [ ] **2.7 Commit:**
  ```bash
  git add src/app/Http/Controllers/Api/V1/MobileStudentCoursesController.php \
          src/tests/Feature/Api/V1/Student/CoursesTest.php \
          src/routes/api.php
  git commit -m "feat(api/courses): MobileStudentCoursesController + routes + feature tests"
  ```

---

### Task 3: Mobile data layer

**Files (create):**
```
floz_mobile/lib/features/student/courses/domain/entities/course.dart
floz_mobile/lib/features/student/courses/domain/entities/meeting_summary.dart
floz_mobile/lib/features/student/courses/domain/entities/meeting_detail.dart
floz_mobile/lib/features/student/courses/domain/entities/material_item.dart
floz_mobile/lib/features/student/courses/domain/repositories/courses_repository.dart
floz_mobile/lib/features/student/courses/data/models/course_dto.dart
floz_mobile/lib/features/student/courses/data/models/meetings_dto.dart
floz_mobile/lib/features/student/courses/data/models/meeting_detail_dto.dart
floz_mobile/lib/features/student/courses/data/datasources/courses_remote_datasource.dart
floz_mobile/lib/features/student/courses/data/repositories/courses_repository_impl.dart
floz_mobile/test/features/student/courses/data/repositories/courses_repository_impl_test.dart
```

**Files (modify):**
```
floz_mobile/lib/core/network/api_endpoints.dart  (add 3 constants)
```

**Entity definitions:**

```dart
// course.dart
class Course {
  final int id;
  final String subjectName;
  final String teacherName;
  final int meetingCount;
  final int materialCount;
  const Course({
    required this.id,
    required this.subjectName,
    required this.teacherName,
    required this.meetingCount,
    required this.materialCount,
  });
}

// meeting_summary.dart
class CourseInfo {
  final int id;
  final String subjectName;
  final String teacherName;
  final String className;
  const CourseInfo({
    required this.id,
    required this.subjectName,
    required this.teacherName,
    required this.className,
  });
}

class MeetingSummary {
  final int id;
  final int meetingNumber;
  final String title;
  final String? description;
  final bool isLocked;
  final int materialCount;
  const MeetingSummary({
    required this.id,
    required this.meetingNumber,
    required this.title,
    this.description,
    required this.isLocked,
    required this.materialCount,
  });
}

class CourseMeetings {
  final CourseInfo course;
  final List<MeetingSummary> meetings;
  const CourseMeetings({required this.course, required this.meetings});
}

// meeting_detail.dart
import 'material_item.dart';

class MeetingHeader {
  final int id;
  final int meetingNumber;
  final String title;
  final String? description;
  final bool isLocked;
  final String subjectName;
  final String className;
  const MeetingHeader({
    required this.id,
    required this.meetingNumber,
    required this.title,
    this.description,
    required this.isLocked,
    required this.subjectName,
    required this.className,
  });
}

class MeetingDetail {
  final MeetingHeader meeting;
  final List<MaterialItem> materials;
  const MeetingDetail({required this.meeting, required this.materials});
}

// material_item.dart
enum MaterialType { file, link, text, unknown }

MaterialType materialTypeFromString(String? raw) {
  switch (raw) {
    case 'file': return MaterialType.file;
    case 'link': return MaterialType.link;
    case 'text': return MaterialType.text;
    default: return MaterialType.unknown;
  }
}

class MaterialItem {
  final int id;
  final String title;
  final MaterialType type;
  final String? content;     // for text
  final String? fileName;    // for file
  final int? fileSize;       // bytes
  final String? fileUrl;     // absolute storage URL
  final String? url;         // for link
  final int sortOrder;
  const MaterialItem({
    required this.id,
    required this.title,
    required this.type,
    this.content,
    this.fileName,
    this.fileSize,
    this.fileUrl,
    this.url,
    required this.sortOrder,
  });
}
```

**Repository abstract:**

```dart
// courses_repository.dart
import '../../../../../core/error/result.dart';
import '../entities/course.dart';
import '../entities/meeting_summary.dart';
import '../entities/meeting_detail.dart';

abstract class CoursesRepository {
  Future<Result<List<Course>>> fetchCourses();
  Future<Result<CourseMeetings>> fetchMeetings(int taId);
  Future<Result<MeetingDetail>> fetchMeetingDetail(int meetingId);
}
```

**Endpoints to add to `api_endpoints.dart`:**

```dart
static const String studentCourses = '/student/courses';
static String studentCourseMeetings(int taId) => '/student/courses/$taId/meetings';
static String studentMeeting(int meetingId) => '/student/meetings/$meetingId';
```

**DTOs (defensive parsing, mirror `attendance_recap_dto.dart`):**

```dart
// course_dto.dart
import '../../domain/entities/course.dart';

class CourseDto {
  static List<Course> listFromJson(List<dynamic> raw) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map((j) => Course(
              id: (j['id'] as num?)?.toInt() ?? 0,
              subjectName: j['subject_name']?.toString() ?? '-',
              teacherName: j['teacher_name']?.toString() ?? '-',
              meetingCount: (j['meeting_count'] as num?)?.toInt() ?? 0,
              materialCount: (j['material_count'] as num?)?.toInt() ?? 0,
            ))
        .toList(growable: false);
  }
}

// meetings_dto.dart
import '../../domain/entities/meeting_summary.dart';

class MeetingsDto {
  static CourseMeetings fromJson(Map<String, dynamic> json) {
    final ta = json['teaching_assignment'] as Map<String, dynamic>? ?? const {};
    final list = (json['meetings'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((j) => MeetingSummary(
              id: (j['id'] as num?)?.toInt() ?? 0,
              meetingNumber: (j['meeting_number'] as num?)?.toInt() ?? 0,
              title: j['title']?.toString() ?? '-',
              description: j['description']?.toString(),
              isLocked: j['is_locked'] as bool? ?? true,
              materialCount: (j['material_count'] as num?)?.toInt() ?? 0,
            ))
        .toList(growable: false);

    return CourseMeetings(
      course: CourseInfo(
        id: (ta['id'] as num?)?.toInt() ?? 0,
        subjectName: ta['subject_name']?.toString() ?? '-',
        teacherName: ta['teacher_name']?.toString() ?? '-',
        className: ta['class_name']?.toString() ?? '-',
      ),
      meetings: list,
    );
  }
}

// meeting_detail_dto.dart
import '../../domain/entities/material_item.dart';
import '../../domain/entities/meeting_detail.dart';

class MeetingDetailDto {
  static MeetingDetail fromJson(Map<String, dynamic> json) {
    final m = json['meeting'] as Map<String, dynamic>? ?? const {};
    final mats = (json['materials'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((j) => MaterialItem(
              id: (j['id'] as num?)?.toInt() ?? 0,
              title: j['title']?.toString() ?? '-',
              type: materialTypeFromString(j['type']?.toString()),
              content: j['content']?.toString(),
              fileName: j['file_name']?.toString(),
              fileSize: (j['file_size'] as num?)?.toInt(),
              fileUrl: j['file_url']?.toString(),
              url: j['url']?.toString(),
              sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
            ))
        .toList(growable: false);

    return MeetingDetail(
      meeting: MeetingHeader(
        id: (m['id'] as num?)?.toInt() ?? 0,
        meetingNumber: (m['meeting_number'] as num?)?.toInt() ?? 0,
        title: m['title']?.toString() ?? '-',
        description: m['description']?.toString(),
        isLocked: m['is_locked'] as bool? ?? true,
        subjectName: m['subject_name']?.toString() ?? '-',
        className: m['class_name']?.toString() ?? '-',
      ),
      materials: mats,
    );
  }
}
```

**Datasource:**

```dart
// courses_remote_datasource.dart
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../models/course_dto.dart';
import '../models/meetings_dto.dart';
import '../models/meeting_detail_dto.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/meeting_summary.dart';
import '../../domain/entities/meeting_detail.dart';

class CoursesRemoteDataSource {
  final ApiClient _client;
  const CoursesRemoteDataSource(this._client);

  Future<List<Course>> fetchCourses() async {
    final body = await _client.get(ApiEndpoints.studentCourses);
    final data = body['data'] as List? ?? const [];
    return CourseDto.listFromJson(data);
  }

  Future<CourseMeetings> fetchMeetings(int taId) async {
    final body = await _client.get(ApiEndpoints.studentCourseMeetings(taId));
    return MeetingsDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<MeetingDetail> fetchMeetingDetail(int meetingId) async {
    final body = await _client.get(ApiEndpoints.studentMeeting(meetingId));
    return MeetingDetailDto.fromJson(body['data'] as Map<String, dynamic>);
  }
}
```

**Repository impl (mirror `RecapRepositoryImpl` exception ladder):**

```dart
// courses_repository_impl.dart
import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/network/api_exception.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/meeting_summary.dart';
import '../../domain/entities/meeting_detail.dart';
import '../../domain/repositories/courses_repository.dart';
import '../datasources/courses_remote_datasource.dart';

class CoursesRepositoryImpl implements CoursesRepository {
  final CoursesRemoteDataSource _remote;
  const CoursesRepositoryImpl({required CoursesRemoteDataSource remote}) : _remote = remote;

  @override
  Future<Result<List<Course>>> fetchCourses() => _guard(() => _remote.fetchCourses());

  @override
  Future<Result<CourseMeetings>> fetchMeetings(int taId) =>
      _guard(() => _remote.fetchMeetings(taId));

  @override
  Future<Result<MeetingDetail>> fetchMeetingDetail(int meetingId) =>
      _guard(() => _remote.fetchMeetingDetail(meetingId));

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

**Tests (4, mirror `recap_repository_impl_test.dart`):**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/features/student/courses/data/datasources/courses_remote_datasource.dart';
import 'package:floz_mobile/features/student/courses/data/repositories/courses_repository_impl.dart';
import 'package:floz_mobile/features/student/courses/domain/entities/course.dart';
import 'package:floz_mobile/features/student/courses/domain/entities/material_item.dart';
import 'package:floz_mobile/features/student/courses/domain/entities/meeting_detail.dart';
import 'package:floz_mobile/features/student/courses/domain/entities/meeting_summary.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements CoursesRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late CoursesRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = CoursesRepositoryImpl(remote: remote);
  });

  test('fetchCourses returns Success', () async {
    when(() => remote.fetchCourses()).thenAnswer((_) async => const [
          Course(id: 1, subjectName: 'Matematika', teacherName: 'Bu Siti',
                 meetingCount: 16, materialCount: 4),
        ]);
    final r = await repo.fetchCourses();
    expect(r, isA<Success<List<Course>>>());
    expect((r as Success).data.first.subjectName, 'Matematika');
  });

  test('fetchMeetings returns Success with course + meetings', () async {
    when(() => remote.fetchMeetings(1)).thenAnswer((_) async => const CourseMeetings(
          course: CourseInfo(id: 1, subjectName: 'Matematika', teacherName: 'Bu Siti',
                             className: 'Kelas 4A'),
          meetings: [
            MeetingSummary(id: 10, meetingNumber: 1, title: 'Pertemuan 1',
                           isLocked: false, materialCount: 2),
          ],
        ));
    final r = await repo.fetchMeetings(1);
    expect(r, isA<Success<CourseMeetings>>());
    expect((r as Success).data.meetings.first.materialCount, 2);
  });

  test('fetchMeetingDetail returns Success with materials', () async {
    when(() => remote.fetchMeetingDetail(10)).thenAnswer((_) async => const MeetingDetail(
          meeting: MeetingHeader(id: 10, meetingNumber: 1, title: 'Pertemuan 1',
                                 isLocked: false, subjectName: 'Matematika',
                                 className: 'Kelas 4A'),
          materials: [
            MaterialItem(id: 1, title: 'Slide', type: MaterialType.file,
                         fileName: 'slide.pdf', sortOrder: 1),
          ],
        ));
    final r = await repo.fetchMeetingDetail(10);
    expect(r, isA<Success<MeetingDetail>>());
    expect((r as Success).data.materials.first.type, MaterialType.file);
  });

  test('fetchCourses returns NetworkFailure on NetworkException', () async {
    when(() => remote.fetchCourses()).thenThrow(NetworkException('offline'));
    final r = await repo.fetchCourses();
    expect(r, isA<FailureResult<List<Course>>>());
    expect(((r as FailureResult).failure), isA<NetworkFailure>());
  });
}
```

**Steps:**

- [ ] **3.1 Read sibling pattern** — `floz_mobile/lib/features/teacher/recaps/` for entity / DTO / datasource / repo conventions.
- [ ] **3.2 Add endpoints** — append 3 constants to `floz_mobile/lib/core/network/api_endpoints.dart` per spec above.
- [ ] **3.3 Create entities** — 4 files under `domain/entities/`.
- [ ] **3.4 Create repository abstract** — `domain/repositories/courses_repository.dart`.
- [ ] **3.5 Create DTOs** — 3 files under `data/models/`.
- [ ] **3.6 Create datasource** — `data/datasources/courses_remote_datasource.dart`.
- [ ] **3.7 Create repository impl** — `data/repositories/courses_repository_impl.dart` (with shared `_guard<T>` helper).
- [ ] **3.8 Write 4 repo tests** — paste test file above.
- [ ] **3.9 Run tests** — `cd floz_mobile && flutter test test/features/student/courses/`. Expect 4/4 pass.
- [ ] **3.10 flutter analyze** on touched files. Must be clean.
- [ ] **3.11 Commit:**
  ```bash
  git add floz_mobile/lib/features/student/courses \
          floz_mobile/lib/core/network/api_endpoints.dart \
          floz_mobile/test/features/student/courses
  git commit -m "feat(mobile/courses): data layer + entities + DTO + repo (no cache)"
  ```

---

### Task 4: Mobile providers + screens + widget tests

**Files:**
- Create: `floz_mobile/lib/features/student/courses/providers/courses_providers.dart`
- Create: `floz_mobile/lib/features/student/courses/presentation/screens/course_detail_screen.dart`
- Create: `floz_mobile/lib/features/student/courses/presentation/screens/meeting_detail_screen.dart`
- Create: `floz_mobile/test/features/student/courses/presentation/screens/course_detail_screen_test.dart`
- Create: `floz_mobile/test/features/student/courses/presentation/screens/meeting_detail_screen_test.dart`
- Modify: `floz_mobile/pubspec.yaml` (add `url_launcher` if missing)

**Providers (`courses_providers.dart`):**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/courses_remote_datasource.dart';
import '../data/repositories/courses_repository_impl.dart';
import '../domain/entities/course.dart';
import '../domain/entities/meeting_detail.dart';
import '../domain/entities/meeting_summary.dart';
import '../domain/repositories/courses_repository.dart';

final coursesRemoteProvider = Provider<CoursesRemoteDataSource>((ref) {
  return CoursesRemoteDataSource(ref.watch(apiClientProvider));
});

final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return CoursesRepositoryImpl(remote: ref.watch(coursesRemoteProvider));
});

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final repo = ref.watch(coursesRepositoryProvider);
  final result = await repo.fetchCourses();
  return switch (result) {
    Success(:final data) => data,
    FailureResult(:final failure) => throw failure,
  };
});

final courseMeetingsProvider = FutureProvider.family<CourseMeetings, int>((ref, taId) async {
  final repo = ref.watch(coursesRepositoryProvider);
  final result = await repo.fetchMeetings(taId);
  return switch (result) {
    Success(:final data) => data,
    FailureResult(:final failure) => throw failure,
  };
});

final meetingDetailProvider = FutureProvider.family<MeetingDetail, int>((ref, meetingId) async {
  final repo = ref.watch(coursesRepositoryProvider);
  final result = await repo.fetchMeetingDetail(meetingId);
  return switch (result) {
    Success(:final data) => data,
    FailureResult(:final failure) => throw failure,
  };
});
```

**`CourseDetailScreen` requirements:**
- ConsumerWidget, takes `{int taId, String subjectName, String className}`.
- AppBar with subject + class subtitle.
- Watches `courseMeetingsProvider(taId)`. Standard loading / error / data pattern.
- Renders meetings as cards: number badge (left), title (bold), material count chip. Locked meetings: muted color + lock icon + "Belum dibuka" subtitle, no tap.
- Unlocked tap → push `MeetingDetailScreen(meetingId)`.
- Pull-to-refresh: `ref.invalidate(courseMeetingsProvider(taId))`.

**`MeetingDetailScreen` requirements:**
- ConsumerWidget, takes `int meetingId`.
- AppBar: meeting title.
- Header card: meeting number + description.
- Materials list. Per material `type`:
  - **text** → inline card with `content`. No tap.
  - **link** → tile with link icon + url text. Tap → `launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)`.
  - **file** → tile with file icon + `fileName` + formatted file size (KB/MB). Tap → `launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication)`.
- Empty state: "Belum ada materi untuk pertemuan ini." with FlozCard styled placeholder.
- Pull-to-refresh: `ref.invalidate(meetingDetailProvider(meetingId))`.

**Visual conventions:** match `RecapScreen` / `ClassesListScreen` — `AppColors.slate*` + `AppColors.primary*`, `FlozCard`, `AppSpacing.radius*`, Inter for body, SpaceGrotesk for headers, Indonesian copy throughout.

**Widget tests (3 per screen, 6 total):**

For `CourseDetailScreen` (override `coursesRepositoryProvider` with mock returning Success):
1. `shows meeting list with material counts on data`
2. `shows error state with retry on failure`
3. `locked meeting tile is not tappable / shows lock icon`

For `MeetingDetailScreen`:
1. `shows file material with filename + size`
2. `shows link material with url chip`
3. `shows empty state when materials is empty`

**Steps:**

- [ ] **4.1 Check pubspec for url_launcher** — `cd floz_mobile && grep url_launcher pubspec.yaml`. If missing, add `url_launcher: ^6.2.5` to dependencies and run `flutter pub get`.
- [ ] **4.2 Write providers** — paste code above into `providers/courses_providers.dart`.
- [ ] **4.3 Write `MeetingDetailScreen`** — implement per requirements above. Use `package:url_launcher/url_launcher.dart`.
- [ ] **4.4 Write `CourseDetailScreen`** — implement per requirements above; pushes `MeetingDetailScreen` via `Navigator.of(context).push(MaterialPageRoute(...))`.
- [ ] **4.5 Write widget tests** — 3 each per the spec above. Mirror `recap_screen_test.dart` style: `ProviderScope(overrides: [coursesRepositoryProvider.overrideWithValue(_FakeRepo())])`. Use mocktail for the fake repo.
- [ ] **4.6 Run tests** — `flutter test test/features/student/courses/presentation/`. Expect 6/6 pass.
- [ ] **4.7 flutter analyze** on touched files. Clean.
- [ ] **4.8 Commit:**
  ```bash
  git add floz_mobile/lib/features/student/courses/providers \
          floz_mobile/lib/features/student/courses/presentation \
          floz_mobile/test/features/student/courses/presentation \
          floz_mobile/pubspec.yaml floz_mobile/pubspec.lock
  git commit -m "feat(mobile/courses): CourseDetailScreen + MeetingDetailScreen + providers + widget tests"
  ```

---

### Task 5: Wire entry point on Beranda dashboard

**Files (modify):**
- `floz_mobile/lib/features/student/dashboard/presentation/screens/dashboard_screen.dart` — add `_CoursesSection` between attendance stat card and "Jadwal Hari Ini" section.

**Approach:** The new section is a horizontal `ListView` of compact `Course` cards. Reads `coursesProvider` (FutureProvider from Task 4). On tap, push `CourseDetailScreen`.

**`_CoursesSection` widget spec:**

```dart
// Inside dashboard_screen.dart, after the existing private widgets.
class _CoursesSection extends ConsumerWidget {
  const _CoursesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCourses = ref.watch(coursesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Mata Pelajaran Saya', count: asyncCourses.value?.length ?? 0),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: asyncCourses.when(
            data: (list) {
              if (list.isEmpty) {
                return const _EmptyBanner(
                  icon: Icons.menu_book_outlined,
                  message: 'Belum ada mata pelajaran terdaftar.',
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _CourseCard(course: list[i]),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary600),
            ),
            error: (_, __) => const _EmptyBanner(
              icon: Icons.error_outline,
              message: 'Gagal memuat mata pelajaran.',
            ),
          ),
        ),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: FlozCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CourseDetailScreen(
                taId: course.id,
                subjectName: course.subjectName,
                className: '',  // not surfaced on the card
              ),
            ),
          );
        },
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
              ),
              child: const Icon(Icons.menu_book_rounded, color: AppColors.primary600, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              course.subjectName,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              course.teacherName,
              style: const TextStyle(fontSize: 11, color: AppColors.slate500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.event_note_rounded, size: 12, color: AppColors.slate400),
                const SizedBox(width: 4),
                Text('${course.meetingCount}', style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
                const SizedBox(width: 8),
                Icon(Icons.attach_file_rounded, size: 12, color: AppColors.slate400),
                const SizedBox(width: 4),
                Text('${course.materialCount}', style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

**Insert into the existing `_DashboardContent.items` list** between the attendance stat card and the "Jadwal Hari Ini" section header. Wrap in `_DashboardItem` like other items, with `spacingBefore: true` so the gap is consistent.

**Steps:**

- [ ] **5.1 Add imports to dashboard_screen.dart** — `Course` entity, `CourseDetailScreen`, `coursesProvider`.
- [ ] **5.2 Insert `_CoursesSection` widget** at the bottom of the file, after the existing private widgets.
- [ ] **5.3 Insert `_CourseCard` widget** below `_CoursesSection`.
- [ ] **5.4 Insert into `_DashboardContent.items` list** between attendance stat (current index 1) and "Jadwal Hari Ini" header.
- [ ] **5.5 flutter analyze** + run existing dashboard tests if any (`flutter test test/features/student/dashboard/`).
- [ ] **5.6 Commit:**
  ```bash
  git add floz_mobile/lib/features/student/dashboard/presentation/screens/dashboard_screen.dart
  git commit -m "feat(mobile/dashboard): add 'Mata Pelajaran Saya' section, wire to CourseDetailScreen"
  ```

---

### Task 6: Integration — regression + manual smoke test + tag

**Steps:**

- [ ] **6.1 Backend regression** — `cd src && php artisan test --env=testing 2>&1 | tail -10`. Expect 197+ passed (previous 187 + 6 service + 5 feature = 198).
- [ ] **6.2 Mobile regression** — `cd floz_mobile && flutter test 2>&1 | tail -10`. Expect ~108 passed (previous 98 + 4 repo + 6 widget = 108).
- [ ] **6.3 Seed data for manual check (optional)** — via tinker, create 1 MeetingMaterial of each type (file/link/text) on an existing meeting belonging to the demo class. Skip if dev DB already has materials.
- [ ] **6.4 Web/mobile smoke test:**
  - Backend already running (confirm `curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/login` returns 200).
  - On simulator: open Beranda. New "Mata Pelajaran Saya" section visible above "Jadwal Hari Ini".
  - Tap a course card → CourseDetailScreen with 16 meeting tiles (UTS/UAS locked).
  - Tap an unlocked meeting → MeetingDetailScreen showing materials.
  - Tap a file material → opens in external viewer; tap link → opens in browser; text shows inline.
- [ ] **6.5 Tag:** `git tag courses-materials-complete`.
- [ ] **6.6 Verify tag** — `git tag -l '*courses*'` should show the tag.

---

## Notes for executing agent

- **Safety:** NEVER run `migrate:fresh` or `migrate:refresh`. Tests use `RefreshDatabase` against the testing DB only. Always `--env=testing` for backend tests. The `.env.testing` file exists at `src/.env.testing`.
- **Web verification preference:** No web changes in this plan. If any are needed (e.g. seeding via tinker), follow the existing project preference: use Playwright MCP to verify visible web changes rather than asking the user to open the browser manually.
- **Existing patterns to follow exactly:**
  - Backend service shape → `RecapService.php`
  - Backend controller shape → `MobileTeacherRecapController.php`
  - Backend feature test shape → `RecapTest.php`
  - Mobile data layer → `floz_mobile/lib/features/teacher/recaps/`
  - Mobile widget test → `recap_screen_test.dart`
- **`Meeting::generateForTeachingAssignment($id)`** is a static helper that creates 16 meetings (1-14 unlocked, 15-16 locked). Use it in tests to populate full meeting sets.
- **`asset('storage/'.$path)`** assumes Laravel storage is symlinked (`php artisan storage:link` already run). If not, swap to `Storage::url($path)` for portability.
- **`url_launcher`** may need iOS Info.plist additions for `LSApplicationQueriesSchemes`. Out of scope for this plan; if iOS testing fails to open links, add `https`/`http` to that list and document it in a follow-up.
- **`launchUrl` returns Future<bool>** — handle it but don't block on the result. Show snackbar `'Tidak dapat membuka tautan.'` on `false`.
- **No test exists yet for student/dashboard screen** — the dashboard already has multiple sections without widget tests. Adding one is out of scope for this plan; cover via Task 4 widget tests + Task 6 manual smoke test.
