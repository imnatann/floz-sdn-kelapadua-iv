# Phase 5 — P4 Attendance Input Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable teachers to input daily attendance per meeting from their phone — view the student roster, toggle each student's status (hadir/sakit/izin/alpha), add optional notes, and submit. This is the first **mutation** feature in the mobile app.

**Architecture:** Backend adds 2 endpoints to the existing teacher route group: `GET /teacher/meetings/{meeting}/attendance` (load roster with existing statuses) and `POST` same path (submit/update attendance entries in a DB transaction using `updateOrCreate`). Mobile adds `features/teacher/attendance/` with a stateful `AttendanceInputScreen` that manages local form state, submits via repository, and shows success/error feedback. The screen is reached by tapping a meeting in `ClassDetailScreen`.

**Tech Stack:**
- Backend: Laravel 12, Pest, Sanctum, Postgres (unique constraint enforcement)
- Mobile: Flutter 3.11, Riverpod, Dio, mocktail
- Contract: `docs/api/CONTRACT.md` (envelope `{data: ...}`)

**Spec source:** `docs/superpowers/specs/2026-04-15-phase5-rest-api-mobile-design.md` §8 (Data Flow — Teacher Input Absen)

---

## Key Decisions

1. **Endpoints:** `GET /api/v1/teacher/meetings/{meeting}/attendance` (roster) + `POST` same path (submit). Both `role:teacher` guarded.
2. **Roster response:** `{data: {meeting: {id, meeting_number, title}, class: {id, name}, teaching_assignment: {id, subject: {id, name}}, students: [{id, name, status, note}]}}`. `status` is null if no attendance record exists yet for that meeting_number.
3. **Submit payload:** `{entries: [{student_id: int, status: "hadir"|"sakit"|"izin"|"alpha", note: string|null}]}`. Validated via `StoreAttendanceRequest`.
4. **Submit response:** Refreshed roster (same shape as GET) — mobile updates UI in one round-trip.
5. **DB operation:** `Attendance::updateOrCreate` with unique key `(class_id, semester_id, meeting_number, student_id)`. Uses `DB::transaction`. Sets `recorded_by` to current user ID.
6. **Authorization:** `MeetingPolicy::recordAttendance` (created P1 T17) — checks `$meeting->teachingAssignment->teacher_id === $user->teacher->id`.
7. **Semester resolution:** Uses the active semester (`Semester::where('is_active', true)->first()`). If no active semester, return 422 error.
8. **Mobile form state:** `AttendanceInputScreen` is a `ConsumerStatefulWidget` with local `Map<int, AttendanceEntry>` state. Each row is a student with a status selector (4 toggle chips: H/S/I/A). Submit button sends all entries.
9. **Online-only:** No offline queue. Network failure → snackbar error + retry. Form data persists in widget state.
10. **Meeting ID type:** `int` (Meeting model does NOT use UUIDs — unlike Schedule, it uses auto-increment integer PK).

---

## File Structure

### Backend — create
```
src/app/Http/Controllers/Api/V1/MobileTeacherAttendanceController.php
src/app/Http/Requests/Api/V1/Attendance/StoreAttendanceRequest.php
src/app/Services/Mobile/AttendanceService.php
src/tests/Unit/Services/Mobile/AttendanceServiceTest.php
src/tests/Feature/Api/V1/Teacher/AttendanceTest.php
```

### Backend — modify
```
src/routes/api.php
```

### Mobile — create
```
floz_mobile/lib/features/teacher/attendance/domain/entities/attendance_roster.dart
floz_mobile/lib/features/teacher/attendance/domain/repositories/attendance_repository.dart
floz_mobile/lib/features/teacher/attendance/data/models/attendance_dto.dart
floz_mobile/lib/features/teacher/attendance/data/datasources/attendance_remote_datasource.dart
floz_mobile/lib/features/teacher/attendance/data/repositories/attendance_repository_impl.dart
floz_mobile/lib/features/teacher/attendance/providers/attendance_providers.dart
floz_mobile/lib/features/teacher/attendance/presentation/screens/attendance_input_screen.dart
floz_mobile/test/features/teacher/attendance/data/repositories/attendance_repository_impl_test.dart
floz_mobile/test/features/teacher/attendance/presentation/screens/attendance_input_screen_test.dart
```

### Mobile — modify
```
floz_mobile/lib/core/network/api_endpoints.dart
floz_mobile/lib/features/teacher/classes/presentation/screens/class_detail_screen.dart
```

---

## Tasks

### Task 1: AttendanceService — getRoster + store (TDD)

**Files:**
- Create: `src/tests/Unit/Services/Mobile/AttendanceServiceTest.php`
- Create: `src/app/Services/Mobile/AttendanceService.php`

- [ ] **Step 1: Write failing test**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/tests/Unit/Services/Mobile/AttendanceServiceTest.php`:

```php
<?php

use App\Models\Attendance;
use App\Models\Meeting;
use App\Models\Semester;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use App\Services\Mobile\AttendanceService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new AttendanceService();

    // Seed active semester
    $this->semester = Semester::factory()->create(['is_active' => true]);
});

it('returns roster with students and their attendance status', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->where('meeting_number', 1)->first();

    // 2 students in the class
    $s1 = Student::factory()->create(['class_id' => $ta->class_id]);
    $s2 = Student::factory()->create(['class_id' => $ta->class_id]);

    // s1 already has attendance for this meeting
    Attendance::factory()->create([
        'student_id' => $s1->id,
        'class_id' => $ta->class_id,
        'semester_id' => $this->semester->id,
        'meeting_number' => $meeting->meeting_number,
        'status' => 'hadir',
    ]);

    $roster = $this->service->getRoster($meeting, $user);

    expect($roster)->toHaveKeys(['meeting', 'class', 'teaching_assignment', 'students']);
    expect($roster['students'])->toHaveCount(2);

    // s1 should have status 'hadir', s2 should have null status
    $s1Data = collect($roster['students'])->firstWhere('id', $s1->id);
    $s2Data = collect($roster['students'])->firstWhere('id', $s2->id);

    expect($s1Data['status'])->toBe('hadir');
    expect($s2Data['status'])->toBeNull();
});

it('stores attendance entries using updateOrCreate in transaction', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->where('meeting_number', 1)->first();
    $student = Student::factory()->create(['class_id' => $ta->class_id]);

    $entries = [
        ['student_id' => $student->id, 'status' => 'hadir', 'note' => null],
    ];

    $result = $this->service->store($meeting, $entries, $user);

    expect($result)->toHaveKey('students');
    expect(Attendance::where('student_id', $student->id)->count())->toBe(1);

    $att = Attendance::where('student_id', $student->id)->first();
    expect($att->status)->toBe('hadir');
    expect($att->meeting_number)->toBe($meeting->meeting_number);
    expect($att->class_id)->toBe($ta->class_id);
    expect($att->semester_id)->toBe($this->semester->id);
    expect($att->recorded_by)->toBe($user->id);
});

it('updates existing attendance on second submit (updateOrCreate)', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->where('meeting_number', 1)->first();
    $student = Student::factory()->create(['class_id' => $ta->class_id]);

    // First submit
    $this->service->store($meeting, [
        ['student_id' => $student->id, 'status' => 'hadir', 'note' => null],
    ], $user);

    // Second submit with changed status
    $this->service->store($meeting, [
        ['student_id' => $student->id, 'status' => 'sakit', 'note' => 'Demam'],
    ], $user);

    expect(Attendance::where('student_id', $student->id)->count())->toBe(1);
    $att = Attendance::where('student_id', $student->id)->first();
    expect($att->status)->toBe('sakit');
    expect($att->notes)->toBe('Demam');
});

it('throws exception when no active semester exists', function () {
    // Deactivate all semesters
    Semester::query()->update(['is_active' => false]);

    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->where('meeting_number', 1)->first();

    $this->service->getRoster($meeting, $user);
})->throws(\RuntimeException::class, 'Tidak ada semester aktif');

it('returns students ordered by name', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->where('meeting_number', 1)->first();

    Student::factory()->create(['class_id' => $ta->class_id, 'name' => 'Zahra']);
    Student::factory()->create(['class_id' => $ta->class_id, 'name' => 'Ahmad']);

    $roster = $this->service->getRoster($meeting, $user);

    expect($roster['students'][0]['name'])->toBe('Ahmad');
    expect($roster['students'][1]['name'])->toBe('Zahra');
});
```

- [ ] **Step 2: Run test, confirm fail**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest tests/Unit/Services/Mobile/AttendanceServiceTest.php 2>&1 | tail -10
```

Expected: FAIL ("AttendanceService not found").

- [ ] **Step 3: Implement AttendanceService**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Services/Mobile/AttendanceService.php`:

```php
<?php

namespace App\Services\Mobile;

use App\Models\Attendance;
use App\Models\Meeting;
use App\Models\Semester;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class AttendanceService
{
    /**
     * Get roster for a meeting: students with their current attendance status.
     */
    public function getRoster(Meeting $meeting, User $user): array
    {
        $ta = $meeting->teachingAssignment()->with(['subject', 'schoolClass'])->first();
        $semester = $this->getActiveSemester();

        $students = $ta->schoolClass->students()
            ->where('status', 'active')
            ->orderBy('name')
            ->get()
            ->map(function ($student) use ($ta, $semester, $meeting) {
                $att = Attendance::where('student_id', $student->id)
                    ->where('class_id', $ta->class_id)
                    ->where('semester_id', $semester->id)
                    ->where('meeting_number', $meeting->meeting_number)
                    ->first();

                return [
                    'id' => $student->id,
                    'name' => $student->name,
                    'nis' => $student->nis,
                    'status' => $att?->status,
                    'note' => $att?->notes,
                ];
            })
            ->values()
            ->all();

        return [
            'meeting' => [
                'id' => $meeting->id,
                'meeting_number' => $meeting->meeting_number,
                'title' => $meeting->title,
            ],
            'class' => [
                'id' => $ta->schoolClass->id,
                'name' => $ta->schoolClass->name,
            ],
            'teaching_assignment' => [
                'id' => $ta->id,
                'subject' => [
                    'id' => $ta->subject->id,
                    'name' => $ta->subject->name,
                ],
            ],
            'students' => $students,
        ];
    }

    /**
     * Store/update attendance entries for a meeting.
     * Returns refreshed roster.
     */
    public function store(Meeting $meeting, array $entries, User $user): array
    {
        $ta = $meeting->teachingAssignment;
        $semester = $this->getActiveSemester();

        DB::transaction(function () use ($entries, $ta, $meeting, $semester, $user) {
            foreach ($entries as $entry) {
                Attendance::updateOrCreate(
                    [
                        'class_id' => $ta->class_id,
                        'semester_id' => $semester->id,
                        'meeting_number' => $meeting->meeting_number,
                        'student_id' => $entry['student_id'],
                    ],
                    [
                        'status' => $entry['status'],
                        'notes' => $entry['note'] ?? null,
                        'date' => now()->toDateString(),
                        'recorded_by' => $user->id,
                    ]
                );
            }
        });

        return $this->getRoster($meeting, $user);
    }

    private function getActiveSemester(): Semester
    {
        $semester = Semester::where('is_active', true)->first();
        if (! $semester) {
            throw new \RuntimeException('Tidak ada semester aktif. Hubungi admin untuk mengaktifkan semester.');
        }

        return $semester;
    }
}
```

- [ ] **Step 4: Run test, confirm pass**

```bash
./vendor/bin/pest tests/Unit/Services/Mobile/AttendanceServiceTest.php
```

Expected: PASS (5 tests).

- [ ] **Step 5: Full regression + commit**

```bash
./vendor/bin/pest 2>&1 | tail -3
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add src/app/Services/Mobile/AttendanceService.php \
        src/tests/Unit/Services/Mobile/AttendanceServiceTest.php
git commit -m "feat(api/v1): add AttendanceService with getRoster + store"
```

---

### Task 2: StoreAttendanceRequest FormRequest

**Files:**
- Create: `src/app/Http/Requests/Api/V1/Attendance/StoreAttendanceRequest.php`

- [ ] **Step 1: Create the FormRequest**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Http/Requests/Api/V1/Attendance
```

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Http/Requests/Api/V1/Attendance/StoreAttendanceRequest.php`:

```php
<?php

namespace App\Http\Requests\Api\V1\Attendance;

use Illuminate\Foundation\Http\FormRequest;

class StoreAttendanceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Authz handled by Policy in controller
    }

    public function rules(): array
    {
        return [
            'entries' => ['required', 'array', 'min:1'],
            'entries.*.student_id' => ['required', 'integer', 'exists:students,id'],
            'entries.*.status' => ['required', 'string', 'in:hadir,sakit,izin,alpha'],
            'entries.*.note' => ['nullable', 'string', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'entries.required' => 'Data absensi wajib diisi.',
            'entries.*.student_id.required' => 'ID siswa wajib diisi.',
            'entries.*.student_id.exists' => 'Siswa tidak ditemukan.',
            'entries.*.status.required' => 'Status kehadiran wajib diisi.',
            'entries.*.status.in' => 'Status harus salah satu dari: hadir, sakit, izin, alpha.',
        ];
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add src/app/Http/Requests/Api/V1/Attendance/StoreAttendanceRequest.php
git commit -m "feat(api/v1): add StoreAttendanceRequest FormRequest"
```

---

### Task 3: V1 Controller + Feature Tests + Route Registration

**Files:**
- Create: `src/app/Http/Controllers/Api/V1/MobileTeacherAttendanceController.php`
- Create: `src/tests/Feature/Api/V1/Teacher/AttendanceTest.php`
- Modify: `src/routes/api.php`

- [ ] **Step 1: Write failing feature test**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/tests/Feature/Api/V1/Teacher/AttendanceTest.php`:

```php
<?php

use App\Models\Attendance;
use App\Models\Meeting;
use App\Models\Semester;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->semester = Semester::factory()->create(['is_active' => true]);
});

it('returns attendance roster for a meeting', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->first();
    Student::factory()->count(3)->create(['class_id' => $ta->class_id]);

    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson("/api/v1/teacher/meetings/{$meeting->id}/attendance")
        ->assertOk()
        ->assertJsonStructure([
            'data' => [
                'meeting' => ['id', 'meeting_number', 'title'],
                'class' => ['id', 'name'],
                'teaching_assignment' => ['id', 'subject'],
                'students' => [
                    '*' => ['id', 'name', 'nis', 'status', 'note'],
                ],
            ],
        ])
        ->assertJsonCount(3, 'data.students');
});

it('submits attendance and returns refreshed roster', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->first();
    $student = Student::factory()->create(['class_id' => $ta->class_id]);

    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/teacher/meetings/{$meeting->id}/attendance", [
            'entries' => [
                ['student_id' => $student->id, 'status' => 'hadir', 'note' => null],
            ],
        ])
        ->assertOk()
        ->assertJsonPath('data.students.0.status', 'hadir');

    expect(Attendance::count())->toBe(1);
});

it('returns 422 for invalid status', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->first();
    $student = Student::factory()->create(['class_id' => $ta->class_id]);
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/teacher/meetings/{$meeting->id}/attendance", [
            'entries' => [
                ['student_id' => $student->id, 'status' => 'invalid_status'],
            ],
        ])
        ->assertStatus(422)
        ->assertJsonStructure(['message', 'errors']);
});

it('returns 403 for another teacher\'s meeting', function () {
    $teacherA = Teacher::factory()->create();
    $teacherB = Teacher::factory()->create();
    $taB = TeachingAssignment::factory()->create(['teacher_id' => $teacherB->id]);
    $meetingB = $taB->meetings()->first();

    $tokenA = $teacherA->user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$tokenA}")
        ->getJson("/api/v1/teacher/meetings/{$meetingB->id}/attendance")
        ->assertForbidden();
});

it('returns 403 for student accessing teacher endpoint', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/teacher/meetings/1/attendance')
        ->assertForbidden();
});

it('returns 401 without token', function () {
    $this->getJson('/api/v1/teacher/meetings/1/attendance')
        ->assertUnauthorized();
});
```

- [ ] **Step 2: Run test, confirm fail**

```bash
./vendor/bin/pest tests/Feature/Api/V1/Teacher/AttendanceTest.php 2>&1 | tail -10
```

Expected: FAIL (404 — routes not registered).

- [ ] **Step 3: Create V1 controller**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Http/Controllers/Api/V1/MobileTeacherAttendanceController.php`:

```php
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Attendance\StoreAttendanceRequest;
use App\Models\Meeting;
use App\Services\Mobile\AttendanceService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\Request;

class MobileTeacherAttendanceController extends Controller
{
    public function __construct(private readonly AttendanceService $service) {}

    /**
     * GET /api/v1/teacher/meetings/{meeting}/attendance
     * Load roster with current attendance statuses.
     */
    public function show(Request $request, int $meetingId)
    {
        $meeting = Meeting::findOrFail($meetingId);
        $this->authorizeTeacher($request->user(), $meeting);

        return response()->json([
            'data' => $this->service->getRoster($meeting, $request->user()),
        ]);
    }

    /**
     * POST /api/v1/teacher/meetings/{meeting}/attendance
     * Submit/update attendance entries.
     */
    public function store(StoreAttendanceRequest $request, int $meetingId)
    {
        $meeting = Meeting::findOrFail($meetingId);
        $this->authorizeTeacher($request->user(), $meeting);

        $roster = $this->service->store(
            $meeting,
            $request->validated('entries'),
            $request->user()
        );

        return response()->json(['data' => $roster]);
    }

    private function authorizeTeacher(mixed $user, Meeting $meeting): void
    {
        if (! $user->teacher ||
            $meeting->teachingAssignment->teacher_id !== $user->teacher->id) {
            throw new AuthorizationException('Anda tidak memiliki akses ke pertemuan ini.');
        }
    }
}
```

- [ ] **Step 4: Register routes**

Edit `src/routes/api.php`. Add import at top:

```php
use App\Http\Controllers\Api\V1\MobileTeacherAttendanceController;
```

Inside the existing `Route::middleware('role:teacher')->group(...)` block, add:

```php
Route::get('/teacher/meetings/{meeting}/attendance', [MobileTeacherAttendanceController::class, 'show']);
Route::post('/teacher/meetings/{meeting}/attendance', [MobileTeacherAttendanceController::class, 'store']);
```

- [ ] **Step 5: Run feature test, confirm pass**

```bash
./vendor/bin/pest tests/Feature/Api/V1/Teacher/AttendanceTest.php
```

Expected: PASS (6 tests).

If the 403 test for "another teacher's meeting" fails with 500 instead of 403, it's because `AuthorizationException` needs to be mapped by the exception handler. Check that `bootstrap/app.php` exception render catches `AuthorizationException` → 403 (it does, from P1 Task 9).

- [ ] **Step 6: Full regression + commit**

```bash
./vendor/bin/pest 2>&1 | tail -3
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add src/app/Http/Controllers/Api/V1/MobileTeacherAttendanceController.php \
        src/tests/Feature/Api/V1/Teacher/AttendanceTest.php \
        src/routes/api.php
git commit -m "feat(api/v1): add teacher attendance roster + submit endpoints"
```

---

### Task 4: Mobile — domain entities + DTO + datasource + endpoint

**Files:**
- Create: `floz_mobile/lib/features/teacher/attendance/domain/entities/attendance_roster.dart`
- Create: `floz_mobile/lib/features/teacher/attendance/domain/repositories/attendance_repository.dart`
- Create: `floz_mobile/lib/features/teacher/attendance/data/models/attendance_dto.dart`
- Create: `floz_mobile/lib/features/teacher/attendance/data/datasources/attendance_remote_datasource.dart`
- Modify: `floz_mobile/lib/core/network/api_endpoints.dart`

- [ ] **Step 1: Create directories**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/teacher/attendance/domain/entities
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/teacher/attendance/domain/repositories
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/teacher/attendance/data/models
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/teacher/attendance/data/datasources
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/teacher/attendance/data/repositories
```

- [ ] **Step 2: Create entity**

Create `attendance_roster.dart`:

```dart
class AttendanceRoster {
  final MeetingInfo meeting;
  final ClassInfo classInfo;
  final SubjectInfo subject;
  final List<StudentAttendance> students;

  const AttendanceRoster({
    required this.meeting,
    required this.classInfo,
    required this.subject,
    required this.students,
  });
}

class MeetingInfo {
  final int id;
  final int meetingNumber;
  final String title;
  const MeetingInfo({required this.id, required this.meetingNumber, required this.title});
}

class ClassInfo {
  final int id;
  final String name;
  const ClassInfo({required this.id, required this.name});
}

class SubjectInfo {
  final int id;
  final String name;
  const SubjectInfo({required this.id, required this.name});
}

class StudentAttendance {
  final int id;
  final String name;
  final String nis;
  final String? status; // null = not yet recorded
  final String? note;

  const StudentAttendance({
    required this.id,
    required this.name,
    required this.nis,
    this.status,
    this.note,
  });
}
```

- [ ] **Step 3: Create repository interface**

```dart
import '../../../../../core/error/result.dart';
import '../entities/attendance_roster.dart';

abstract class AttendanceRepository {
  Future<Result<AttendanceRoster>> fetchRoster(int meetingId);
  Future<Result<AttendanceRoster>> submitAttendance(
    int meetingId,
    List<Map<String, dynamic>> entries,
  );
}
```

- [ ] **Step 4: Create DTO**

Parse roster from `Map<String, dynamic>` (both GET and POST return same shape).

```dart
import '../../domain/entities/attendance_roster.dart';

class AttendanceRosterDto {
  static AttendanceRoster fromJson(Map<String, dynamic> json) {
    final meetingJson = json['meeting'] as Map<String, dynamic>? ?? {};
    final classJson = json['class'] as Map<String, dynamic>? ?? {};
    final taJson = json['teaching_assignment'] as Map<String, dynamic>? ?? {};
    final subjectJson = taJson['subject'] as Map<String, dynamic>? ?? {};
    final studentsJson = json['students'] as List? ?? [];

    return AttendanceRoster(
      meeting: MeetingInfo(
        id: (meetingJson['id'] as num?)?.toInt() ?? 0,
        meetingNumber: (meetingJson['meeting_number'] as num?)?.toInt() ?? 0,
        title: meetingJson['title'] as String? ?? '-',
      ),
      classInfo: ClassInfo(
        id: (classJson['id'] as num?)?.toInt() ?? 0,
        name: classJson['name'] as String? ?? '-',
      ),
      subject: SubjectInfo(
        id: (subjectJson['id'] as num?)?.toInt() ?? 0,
        name: subjectJson['name'] as String? ?? '-',
      ),
      students: studentsJson
          .whereType<Map<String, dynamic>>()
          .map((s) => StudentAttendance(
                id: (s['id'] as num?)?.toInt() ?? 0,
                name: s['name'] as String? ?? '-',
                nis: s['nis']?.toString() ?? '-',
                status: s['status'] as String?,
                note: s['note'] as String?,
              ))
          .toList(growable: false),
    );
  }
}
```

- [ ] **Step 5: Create datasource**

```dart
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/attendance_roster.dart';
import '../models/attendance_dto.dart';

abstract class AttendanceRemoteDataSource {
  Future<AttendanceRoster> fetchRoster(int meetingId);
  Future<AttendanceRoster> submitAttendance(int meetingId, List<Map<String, dynamic>> entries);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final ApiClient _client;
  AttendanceRemoteDataSourceImpl(this._client);

  @override
  Future<AttendanceRoster> fetchRoster(int meetingId) async {
    final res = await _client.get(
      '${ApiEndpoints.teacherMeetings}/$meetingId/attendance',
    );
    final body = res.data as Map<String, dynamic>;
    return AttendanceRosterDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<AttendanceRoster> submitAttendance(
    int meetingId,
    List<Map<String, dynamic>> entries,
  ) async {
    final res = await _client.post(
      '${ApiEndpoints.teacherMeetings}/$meetingId/attendance',
      body: {'entries': entries},
    );
    final body = res.data as Map<String, dynamic>;
    return AttendanceRosterDto.fromJson(body['data'] as Map<String, dynamic>);
  }
}
```

- [ ] **Step 6: Add endpoint constant**

Edit `api_endpoints.dart`, add:
```dart
  static const String teacherMeetings = '/teacher/meetings';
```

- [ ] **Step 7: Analyze + commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze lib/features/teacher/attendance/ lib/core/network/api_endpoints.dart 2>&1 | tail -5
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add floz_mobile/lib/features/teacher/attendance/domain \
        floz_mobile/lib/features/teacher/attendance/data/models \
        floz_mobile/lib/features/teacher/attendance/data/datasources \
        floz_mobile/lib/core/network/api_endpoints.dart
git commit -m "feat(mobile/attendance): domain entities, DTO, remote datasource"
```

---

### Task 5: Mobile — repository impl + tests

**Files:**
- Create: `floz_mobile/lib/features/teacher/attendance/data/repositories/attendance_repository_impl.dart`
- Create: `floz_mobile/test/features/teacher/attendance/data/repositories/attendance_repository_impl_test.dart`

No cache for attendance (always fresh — both roster load and submit are real-time). Repository catches typed exceptions and returns `Result<T>`.

- [ ] **Step 1: Write failing test (4 tests: fetch happy, fetch error, submit happy, submit error)**

- [ ] **Step 2: Implement repository (simple pass-through with error mapping)**

- [ ] **Step 3: Run test, confirm pass**

- [ ] **Step 4: Commit**

```bash
git add floz_mobile/lib/features/teacher/attendance/data/repositories \
        floz_mobile/test/features/teacher/attendance
git commit -m "feat(mobile/attendance): AttendanceRepositoryImpl + tests"
```

---

### Task 6: Mobile — providers

**Files:**
- Create: `floz_mobile/lib/features/teacher/attendance/providers/attendance_providers.dart`

Create:
- `attendanceRemoteProvider` — AttendanceRemoteDataSourceImpl(apiClientProvider)
- `attendanceRepositoryProvider` — AttendanceRepositoryImpl(remote)
- `attendanceRosterProvider` — `FutureProvider.family<AttendanceRoster, int>` (by meetingId) — loads roster
- `AttendanceSubmitController` — `AsyncNotifier<void>` with `submit(int meetingId, List<Map<String, dynamic>> entries)` method

```bash
git add floz_mobile/lib/features/teacher/attendance/providers
git commit -m "feat(mobile/attendance): Riverpod providers for roster + submit"
```

---

### Task 7: Mobile — AttendanceInputScreen (stateful form)

**Files:**
- Create: `floz_mobile/lib/features/teacher/attendance/presentation/screens/attendance_input_screen.dart`

Design (the core of P4):
- AppBar: "Absensi Pertemuan {N}" + subtitle "{subject} - {class}"
- Header card: meeting title + date + total students count
- Student list: each row is a FlozCard with:
  - Student name (left)
  - NIS (subtitle)
  - 4 toggle chips: H (hadir, green), S (sakit, amber), I (izin, blue), A (alpha, red)
  - Optional note text field (appears when status ≠ hadir)
- Bottom bar: sticky submit button "Simpan Absensi" (full width, primary)
- Summary row above button: "14 hadir, 1 sakit, 0 izin, 0 alpha"
- Loading overlay on submit

**State management:**
- Screen receives `meetingId` param
- On init: `ref.watch(attendanceRosterProvider(meetingId))` → loads roster
- Local state: `Map<int, _EditableEntry>` initialized from roster's student statuses
- Each toggle chip updates local state (no API call until submit)
- Submit button: collects all entries → calls `attendanceSubmitController.submit(meetingId, entries)`
- On success: snackbar "Absensi berhasil disimpan" + pop back
- On error: snackbar error, form stays

```bash
git add floz_mobile/lib/features/teacher/attendance/presentation
git commit -m "feat(mobile/attendance): AttendanceInputScreen with status toggles + submit"
```

---

### Task 8: Mobile — widget test

**Files:**
- Create: `floz_mobile/test/features/teacher/attendance/presentation/screens/attendance_input_screen_test.dart`

3 tests:
- Shows student list with status toggles on happy path
- Shows error state with retry on roster load failure
- Submit button calls repository (mock submit, verify)

```bash
git add floz_mobile/test/features/teacher/attendance
git commit -m "test(mobile/attendance): widget tests for AttendanceInputScreen"
```

---

### Task 9: Wire attendance into ClassDetailScreen navigation

**Files:**
- Modify: `floz_mobile/lib/features/teacher/classes/presentation/screens/class_detail_screen.dart`

Add: when teacher taps a meeting tile in ClassDetailScreen, navigate to `AttendanceInputScreen(meetingId: meeting.id)`.

Currently meetings are listed but not tappable (or tappable but go nowhere). Add `FlozCard.onTap` that pushes `AttendanceInputScreen`.

```bash
git add floz_mobile/lib/features/teacher/classes/presentation/screens/class_detail_screen.dart
git commit -m "feat(mobile/teacher): navigate from meeting tile to AttendanceInputScreen"
```

---

### Task 10: Integration test + DoD verification

- [ ] **Step 1: Start server, login as teacher, test via curl**

```bash
# Seed teacher data if not already
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan serve --host=127.0.0.1 --port=8000 &
sleep 2

TOKEN=$(curl -s -X POST http://127.0.0.1:8000/api/v1/auth/login \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d '{"email":"teacher@floz.test","password":"password123"}' \
  | php -r 'echo json_decode(file_get_contents("php://stdin"))->data->token;')

# Get first teaching assignment ID
TA_ID=$(curl -s http://127.0.0.1:8000/api/v1/teacher/teaching-assignments \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" \
  | php -r '$d=json_decode(file_get_contents("php://stdin"),true); echo $d["data"][0]["id"];')

# Get first meeting ID
MEETING_ID=$(curl -s "http://127.0.0.1:8000/api/v1/teacher/teaching-assignments/$TA_ID/meetings" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" \
  | php -r '$d=json_decode(file_get_contents("php://stdin"),true); echo $d["data"]["meetings"][0]["id"];')

echo "TA=$TA_ID MEETING=$MEETING_ID"

# GET roster
curl -s "http://127.0.0.1:8000/api/v1/teacher/meetings/$MEETING_ID/attendance" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" \
  | php -r '$d=json_decode(file_get_contents("php://stdin"),true); echo "Students: ".count($d["data"]["students"])."\n";'

# POST attendance
STUDENT_ID=$(curl -s "http://127.0.0.1:8000/api/v1/teacher/meetings/$MEETING_ID/attendance" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" \
  | php -r '$d=json_decode(file_get_contents("php://stdin"),true); echo $d["data"]["students"][0]["id"];')

curl -s -X POST "http://127.0.0.1:8000/api/v1/teacher/meetings/$MEETING_ID/attendance" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" -H "Content-Type: application/json" \
  -d "{\"entries\":[{\"student_id\":$STUDENT_ID,\"status\":\"hadir\",\"note\":null}]}" \
  | php -r '$d=json_decode(file_get_contents("php://stdin"),true); echo $d["data"]["students"][0]["status"]."\n";'
```

- [ ] **Step 2: Run full tests**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src && ./vendor/bin/pest 2>&1 | tail -3
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile && flutter test test/core test/features 2>&1 | tail -3
```

- [ ] **Step 3: Tag milestone**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git tag p4-attendance-input-complete
```

---

## P4 Definition of Done

- [ ] `GET /api/v1/teacher/meetings/{id}/attendance` — returns roster with student statuses
- [ ] `POST /api/v1/teacher/meetings/{id}/attendance` — submits/updates attendance via `updateOrCreate` in transaction
- [ ] Validation: entries required, status must be hadir/sakit/izin/alpha
- [ ] Authorization: only the meeting's teacher can access (403 for others)
- [ ] AttendanceService: 5 unit tests pass
- [ ] Feature tests: 6 pass (roster, submit, validation, authz, role, token)
- [ ] Mobile: AttendanceInputScreen with status toggle chips + submit
- [ ] Tapping a meeting in ClassDetailScreen opens AttendanceInputScreen
- [ ] Submit success: snackbar + navigate back
- [ ] Submit failure: snackbar error, form persists
- [ ] 4 repo tests + 3 widget tests pass
- [ ] Git tag `p4-attendance-input-complete`

---

## Notes for executing agent

- **Attendance unique constraint:** `(class_id, semester_id, meeting_number, student_id)`. The `updateOrCreate` uses these 4 columns as the "find" key. The "update" values are `status`, `notes`, `date`, `recorded_by`.
- **Meeting model uses INTEGER primary key** (auto-increment), NOT UUID. So `Meeting::findOrFail($meetingId)` with an int works fine. Route parameter `{meeting}` is int.
- **Active semester:** The service resolves via `Semester::where('is_active', true)->first()`. If no active semester exists, it throws `RuntimeException` → returns 500 with envelope error. The seeder created an active semester (Genap 2025/2026).
- **`recorded_by`** column stores the User ID (not Teacher ID) of who recorded the attendance.
- **Attendance `notes` column** (not `note`) — the migration uses `notes` (plural). The API accepts `note` (singular) in the request payload, but the service stores it in the `notes` column. This mismatch is intentional: API uses singular for consistency, model uses plural because that's what the migration defined.
- **Mobile form state:** Use a local `Map<int, String>` for statuses and `Map<int, String?>` for notes, keyed by student ID. Initialize from roster data. The toggle chips update local state only — no API call until submit button is pressed.
- **No cache.** Attendance is always real-time (no Hive box). Both fetch and submit go directly to network.
- **Same safety rules:** NEVER run migrate. NEVER touch `.env`. Tests use RefreshDatabase.
