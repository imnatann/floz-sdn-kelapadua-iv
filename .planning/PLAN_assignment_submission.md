# Plan: Student Assignment Submission POST

## Goal

Add a POST endpoint that lets a student submit their answer (text + optional link) to an `OfflineAssignment` via the mobile app, and wire the Flutter UI to call it — replacing the current static "kumpulkan secara langsung" placeholder banner.

---

## Scope decision

**Only `OfflineAssignment` (type `manual` or `quiz`) — NOT `Task` or `Exam`.**

Rationale:
- The mobile API already exposes *only* `offline_assignments` through `MobileAssignmentController` / `AssignmentService`.
- `task_scores` and `exam_scores` have no `answer_text` / `answer_link` columns; they are teacher-set grade ledgers, not student submission buckets. Adding student-facing submission there would require schema changes *and* business-logic rewrites beyond MVP scope.
- The web `OfflineAssignmentController` already has a working student-submission code path (`storeSubmission`) writing to `offline_assignment_submissions`. We reuse that exact table.
- **Quiz submissions** (type `quiz`): MVP supports submitting `answer_text` only. Auto-grading via `offline_assignment_questions` / `offline_assignment_answers` is a future task (Task 0-future).

**In-scope for this plan:**
- `manual` assignments: `answer_text` (nullable) + `answer_link` (nullable). At least one must be present.
- `quiz` assignments: `answer_text` only (students write a free-text answer; teacher grades manually in web UI — auto-grading deferred).

**Out of scope (future):**
- Multipart file upload (no presigned-URL infra; no S3 config populated). Files can be linked via `answer_link` (Google Drive, etc.).
- True quiz auto-grading (per-question `offline_assignment_answers` rows).
- `Task` and `Exam` submission endpoints.

---

## Endpoint design

- **Method + URL:** `POST /api/v1/student/assignments/{id}/submit`
- **Auth:** `auth:sanctum` + `role:student` (same as existing GET routes)
- **Request body (JSON):**
  ```json
  {
    "answer_text": "...",   // nullable string, max 10000 chars
    "answer_link": "..."    // nullable URL string, max 2048 chars
  }
  ```
  Constraint: at least one of `answer_text` or `answer_link` must be present (validated via `required_without`).
- **Validation rules (FormRequest `SubmitAssignmentRequest`):**
  ```
  answer_text  — nullable | string | max:10000 | required_without:answer_link
  answer_link  — nullable | url | max:2048   | required_without:answer_text
  ```
- **Response shape (201 Created):**
  ```json
  {
    "data": {
      "submission_id": 42,
      "status": "submitted",
      "submitted_at": "2026-05-08T10:00:00.000000Z",
      "is_late": false
    }
  }
  ```
- **Error cases:**
  - `401` — no Sanctum token
  - `403` — user is not a student OR assignment does not belong to student's class
  - `404` — assignment not found or inactive
  - `409` — student has already submitted (idempotency: reject re-submission; teacher must clear it via web)
  - `422` — validation fails (both fields missing / link not a URL / text too long)
- **Idempotency:** Reject with `409` if `offline_assignment_submissions` row already exists for `(offline_assignment_id, student_id)`. The web flow uses `firstOrNew` (allows re-submission); the mobile MVP is stricter — one-shot submit only, consistent with `oa_submissions_unique` DB constraint.

---

## Data model changes

**No new migration needed.** Table `offline_assignment_submissions` (created in `2026_02_18_000001`) already has:
- `offline_assignment_id` FK
- `student_id` FK
- `submitted_at` datetime nullable
- `answer_text` text nullable
- `answer_link` string nullable
- `grade`, `correction_note`, `correction_file` (teacher-set, untouched by student)
- Unique constraint `oa_submissions_unique (offline_assignment_id, student_id)`

`OfflineAssignmentSubmission::$fillable` already includes all needed fields.

---

## File structure

### Backend — create
| Path | Purpose |
|------|---------|
| `src/app/Http/Requests/Api/V1/SubmitAssignmentRequest.php` | FormRequest with validation rules |
| `src/tests/Feature/Api/V1/Student/AssignmentSubmissionTest.php` | Pest feature tests |

### Backend — modify
| Path | Change |
|------|--------|
| `src/app/Http/Controllers/Api/V1/MobileAssignmentController.php` | Add `submit(SubmitAssignmentRequest, int $id)` method |
| `src/app/Services/Mobile/AssignmentService.php` | Add `submitForStudent(User, int $id, array $data): array` |
| `src/routes/api.php` | Register `Route::post('/student/assignments/{id}/submit', ...)` inside `role:student` group |

### Mobile — create
| Path | Purpose |
|------|---------|
| `floz_mobile/lib/features/student/assignments/presentation/screens/assignment_submit_screen.dart` | New screen: text field + link field + Submit button |

### Mobile — modify
| Path | Change |
|------|---------|
| `floz_mobile/lib/features/student/assignments/data/datasources/assignment_remote_datasource.dart` | Add `submitAssignment(int id, {String? answerText, String? answerLink})` |
| `floz_mobile/lib/features/student/assignments/data/repositories/assignment_repository_impl.dart` | Implement `submit(...)` wrapping datasource + error mapping |
| `floz_mobile/lib/features/student/assignments/domain/repositories/assignment_repository.dart` | Add abstract `submit(...)` method |
| `floz_mobile/lib/features/student/assignments/providers/assignment_providers.dart` | Add `submitAssignmentProvider` (StateNotifier or AsyncNotifier) |
| `floz_mobile/lib/core/network/api_endpoints.dart` | Add `studentAssignmentSubmit(int id)` helper |
| `floz_mobile/lib/features/student/assignments/presentation/screens/assignment_detail_screen.dart` | Replace `_NoSubmissionBanner` with a tappable "Kumpulkan" button that navigates to submit screen; invalidate `assignmentDetailProvider` on success |

---

## Tasks (TDD task-by-task with acceptance criteria)

---

### Task 1: Backend — FormRequest + Route Registration

**Files:**
- `src/app/Http/Requests/Api/V1/SubmitAssignmentRequest.php` (create)
- `src/routes/api.php` (modify)
- `src/app/Http/Controllers/Api/V1/MobileAssignmentController.php` (stub only — returns 501 for now)

**Goal:** Route exists, auth + role guard fires, validation fires. No business logic yet.

- [ ] **Step 1: Write failing test** — add to new file `src/tests/Feature/Api/V1/Student/AssignmentSubmissionTest.php`:

```php
<?php

use App\Models\OfflineAssignment;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

// ─── Auth / authz guards ──────────────────────────────────────────────────────

it('rejects unauthenticated submit', function () {
    $assignment = OfflineAssignment::factory()->create(['status' => 'active']);

    $this->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [
        'answer_text' => 'My answer',
    ])->assertUnauthorized();
});

it('rejects teacher role on submit', function () {
    $teacher = \App\Models\Teacher::factory()->create();
    $user    = User::where('email', $teacher->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()->create(['status' => 'active']);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [
            'answer_text' => 'My answer',
        ])->assertForbidden();
});

// ─── Validation ───────────────────────────────────────────────────────────────

it('returns 422 when both answer_text and answer_link are missing', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()
        ->withClasses([$student->class_id])
        ->create(['status' => 'active']);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [])
        ->assertUnprocessable();
});

it('returns 422 when answer_link is not a URL', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()
        ->withClasses([$student->class_id])
        ->create(['status' => 'active']);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [
            'answer_link' => 'not-a-url',
        ])->assertUnprocessable();
});
```

- [ ] **Step 2:** Run `./vendor/bin/pest tests/Feature/Api/V1/Student/AssignmentSubmissionTest.php` — confirm `Route [api/v1/student/assignments/{id}/submit] not defined` failure.

- [ ] **Step 3: Implement**

  **`src/app/Http/Requests/Api/V1/SubmitAssignmentRequest.php`:**
  ```php
  <?php

  namespace App\Http\Requests\Api\V1;

  use Illuminate\Foundation\Http\FormRequest;

  class SubmitAssignmentRequest extends FormRequest
  {
      public function authorize(): bool { return true; }

      public function rules(): array
      {
          return [
              'answer_text' => ['nullable', 'string', 'max:10000', 'required_without:answer_link'],
              'answer_link' => ['nullable', 'url', 'max:2048', 'required_without:answer_text'],
          ];
      }
  }
  ```

  **`src/app/Http/Controllers/Api/V1/MobileAssignmentController.php`** — add method stub:
  ```php
  public function submit(SubmitAssignmentRequest $request, int $id)
  {
      return response()->json(['message' => 'not implemented'], 501);
  }
  ```
  Add import: `use App\Http\Requests\Api\V1\SubmitAssignmentRequest;`

  **`src/routes/api.php`** — inside `role:student` group, after existing assignment routes:
  ```php
  Route::post('/student/assignments/{id}/submit', [MobileAssignmentController::class, 'submit']);
  ```

- [ ] **Step 4:** Run tests — auth/authz tests pass; validation tests pass; stub returns 501 (not tested yet).
- [ ] **Step 5:** Commit `feat(api/v1): add SubmitAssignmentRequest + route stub`

---

### Task 2: Backend — Service method (business logic)

**Files:**
- `src/app/Services/Mobile/AssignmentService.php` (modify)
- `src/tests/Feature/Api/V1/Student/AssignmentSubmissionTest.php` (extend)

**Goal:** Happy-path submit creates DB row; 404 for wrong class; 409 on duplicate.

- [ ] **Step 1: Write failing tests** — append to `AssignmentSubmissionTest.php`:

```php
// ─── Business logic ───────────────────────────────────────────────────────────

it('returns 404 when assignment not in student class', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()->create(['status' => 'active']); // no class link

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [
            'answer_text' => 'My answer',
        ])->assertNotFound();
});

it('creates submission and returns 201 with correct structure', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()
        ->withClasses([$student->class_id])
        ->create(['status' => 'active', 'type' => 'manual']);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [
            'answer_text' => 'My detailed answer.',
            'answer_link' => 'https://drive.google.com/file/xyz',
        ])
        ->assertCreated()
        ->assertJsonStructure(['data' => ['submission_id', 'status', 'submitted_at', 'is_late']]);

    $this->assertDatabaseHas('offline_assignment_submissions', [
        'offline_assignment_id' => $assignment->id,
        'student_id'            => $student->id,
        'answer_text'           => 'My detailed answer.',
        'answer_link'           => 'https://drive.google.com/file/xyz',
    ]);
});

it('returns status submitted (not graded) immediately after submit', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()
        ->withClasses([$student->class_id])
        ->create(['status' => 'active']);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [
            'answer_text' => 'Answer',
        ])
        ->assertJsonPath('data.status', 'submitted');
});

it('flags is_late true when submitted after due_date', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()
        ->withClasses([$student->class_id])
        ->create(['status' => 'active', 'due_date' => now()->subDay()]);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [
            'answer_text' => 'Late answer',
        ])
        ->assertCreated()
        ->assertJsonPath('data.is_late', true);
});

it('returns 409 when student submits twice', function () {
    $student = Student::factory()->create();
    $user    = User::where('email', $student->email)->first();
    $token   = $user->createToken('mobile')->plainTextToken;

    $assignment = OfflineAssignment::factory()
        ->withClasses([$student->class_id])
        ->create(['status' => 'active']);

    \App\Models\OfflineAssignmentSubmission::create([
        'offline_assignment_id' => $assignment->id,
        'student_id'            => $student->id,
        'submitted_at'          => now(),
        'answer_text'           => 'First submit',
    ]);

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson("/api/v1/student/assignments/{$assignment->id}/submit", [
            'answer_text' => 'Second attempt',
        ])
        ->assertStatus(409);
});
```

- [ ] **Step 2:** Run — all new tests fail with `501` or assertion errors.

- [ ] **Step 3: Implement**

  **`src/app/Services/Mobile/AssignmentService.php`** — add method:
  ```php
  use App\Models\OfflineAssignmentSubmission;

  public function submitForStudent(User $user, int $id, array $data): array
  {
      $student = $user->student;
      if (! $student || ! $student->class_id) {
          abort(403, 'Student profile not found.');
      }

      $assignment = OfflineAssignment::whereHas('classes', fn ($q) => $q->where('class_id', $student->class_id))
          ->where('status', 'active')
          ->find($id);

      if (! $assignment) {
          abort(404, 'Tugas tidak ditemukan.');
      }

      $existing = OfflineAssignmentSubmission::where('offline_assignment_id', $assignment->id)
          ->where('student_id', $student->id)
          ->exists();

      if ($existing) {
          abort(409, 'Tugas sudah dikumpulkan.');
      }

      $submittedAt = now();
      $isLate      = $assignment->due_date && $submittedAt->gt($assignment->due_date);

      $submission = OfflineAssignmentSubmission::create([
          'offline_assignment_id' => $assignment->id,
          'student_id'            => $student->id,
          'submitted_at'          => $submittedAt,
          'answer_text'           => $data['answer_text'] ?? null,
          'answer_link'           => $data['answer_link'] ?? null,
      ]);

      return [
          'submission_id' => $submission->id,
          'status'        => 'submitted',
          'submitted_at'  => $submission->submitted_at->toISOString(),
          'is_late'       => $isLate,
      ];
  }
  ```

  **`src/app/Http/Controllers/Api/V1/MobileAssignmentController.php`** — replace stub:
  ```php
  public function submit(SubmitAssignmentRequest $request, int $id)
  {
      $data = $this->service->submitForStudent($request->user(), $id, $request->validated());
      return response()->json(['data' => $data], 201);
  }
  ```

- [ ] **Step 4:** Run full `AssignmentSubmissionTest.php` — all tests green.
- [ ] **Step 5:** Commit `feat(api/v1): implement student assignment submission endpoint`

---

### Task 3: Mobile — Datasource + Repository + Domain interface

**Files:**
- `floz_mobile/lib/core/network/api_endpoints.dart` (modify)
- `floz_mobile/lib/features/student/assignments/domain/repositories/assignment_repository.dart` (modify)
- `floz_mobile/lib/features/student/assignments/data/datasources/assignment_remote_datasource.dart` (modify)
- `floz_mobile/lib/features/student/assignments/data/repositories/assignment_repository_impl.dart` (modify)

**Goal:** Data layer can POST and return a typed result. No UI yet.

- [ ] **Step 1: Write failing test** — create `floz_mobile/test/features/student/assignments/assignment_submission_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:floz_mobile/core/network/api_client.dart';
import 'package:floz_mobile/features/student/assignments/data/datasources/assignment_remote_datasource.dart';

@GenerateMocks([ApiClient])
import 'assignment_submission_test.mocks.dart';

void main() {
  late MockApiClient mockClient;
  late AssignmentRemoteDataSourceImpl datasource;

  setUp(() {
    mockClient = MockApiClient();
    datasource = AssignmentRemoteDataSourceImpl(mockClient);
  });

  test('submitAssignment posts to correct endpoint and returns SubmissionResult', () async {
    when(mockClient.post(
      '/student/assignments/7/submit',
      body: {'answer_text': 'hello', 'answer_link': null},
    )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 201,
          data: {
            'data': {
              'submission_id': 1,
              'status': 'submitted',
              'submitted_at': '2026-05-08T10:00:00.000000Z',
              'is_late': false,
            }
          },
        ));

    final result = await datasource.submitAssignment(7, answerText: 'hello');
    expect(result.status, 'submitted');
    expect(result.isLate, false);
  });
}
```

- [ ] **Step 2:** Run `flutter test test/features/student/assignments/assignment_submission_test.dart` — compilation error (method doesn't exist yet).

- [ ] **Step 3: Implement**

  **Add entity** — append to `floz_mobile/lib/features/student/assignments/domain/entities/assignment.dart`:
  ```dart
  class SubmissionResult {
    final int submissionId;
    final String status;
    final DateTime submittedAt;
    final bool isLate;

    const SubmissionResult({
      required this.submissionId,
      required this.status,
      required this.submittedAt,
      required this.isLate,
    });

    factory SubmissionResult.fromJson(Map<String, dynamic> json) {
      return SubmissionResult(
        submissionId: (json['submission_id'] as num).toInt(),
        status: json['status'] as String,
        submittedAt: DateTime.parse(json['submitted_at'] as String),
        isLate: json['is_late'] as bool? ?? false,
      );
    }
  }
  ```

  **`api_endpoints.dart`** — add:
  ```dart
  static String studentAssignmentSubmit(int id) => '/student/assignments/$id/submit';
  ```

  **`assignment_repository.dart`** — add abstract method:
  ```dart
  Future<Result<SubmissionResult>> submit(int id, {String? answerText, String? answerLink});
  ```

  **`assignment_remote_datasource.dart`** — add:
  ```dart
  Future<SubmissionResult> submitAssignment(int id, {String? answerText, String? answerLink});
  ```
  Implementation in `AssignmentRemoteDataSourceImpl`:
  ```dart
  @override
  Future<SubmissionResult> submitAssignment(int id, {String? answerText, String? answerLink}) async {
    final res = await _client.post(
      ApiEndpoints.studentAssignmentSubmit(id),
      body: {'answer_text': answerText, 'answer_link': answerLink},
    );
    final body = res.data as Map<String, dynamic>;
    return SubmissionResult.fromJson(body['data'] as Map<String, dynamic>);
  }
  ```

  **`assignment_repository_impl.dart`** — add:
  ```dart
  @override
  Future<Result<SubmissionResult>> submit(int id, {String? answerText, String? answerLink}) async {
    try {
      final data = await _remote.submitAssignment(id, answerText: answerText, answerLink: answerLink);
      return Success(data);
    } on NetworkException catch (e) {
      return FailureResult(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(ForbiddenFailure(e.message));
    } on ValidationException catch (e) {
      return FailureResult(ValidationFailure(e.message));
    } on ApiException catch (e) {
      return FailureResult(ServerFailure(e.message));
    }
  }
  ```
  Note: add `ValidationFailure` to `core/error/failure.dart` if not already present (check before implementing).

- [ ] **Step 4:** Run `flutter test` — test passes.
- [ ] **Step 5:** Commit `feat(mobile/assignments): data layer for submission POST`

---

### Task 4: Mobile — Provider + Submit Screen UI

**Files:**
- `floz_mobile/lib/features/student/assignments/providers/assignment_providers.dart` (modify)
- `floz_mobile/lib/features/student/assignments/presentation/screens/assignment_submit_screen.dart` (create)
- `floz_mobile/lib/features/student/assignments/presentation/screens/assignment_detail_screen.dart` (modify)

**Goal:** Student can tap "Kumpulkan" on detail screen, fill a form, submit. On success: detail screen reloads showing submitted status.

- [ ] **Step 1: Write widget test** — create `floz_mobile/test/features/student/assignments/assignment_submit_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:floz_mobile/features/student/assignments/domain/repositories/assignment_repository.dart';
import 'package:floz_mobile/features/student/assignments/providers/assignment_providers.dart';
import 'package:floz_mobile/features/student/assignments/presentation/screens/assignment_submit_screen.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/student/assignments/domain/entities/assignment.dart';

@GenerateMocks([AssignmentRepository])
import 'assignment_submit_screen_test.mocks.dart';

void main() {
  testWidgets('shows text field, link field, and submit button', (tester) async {
    final mockRepo = MockAssignmentRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AssignmentSubmitScreen(assignmentId: 1),
        ),
      ),
    );

    expect(find.byKey(const Key('answer_text_field')), findsOneWidget);
    expect(find.byKey(const Key('answer_link_field')), findsOneWidget);
    expect(find.byKey(const Key('submit_button')), findsOneWidget);
  });

  testWidgets('shows error snackbar when both fields empty', (tester) async {
    final mockRepo = MockAssignmentRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AssignmentSubmitScreen(assignmentId: 1),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pump();

    expect(find.text('Isi jawaban atau link terlebih dahulu.'), findsOneWidget);
    verifyNever(mockRepo.submit(any));
  });

  testWidgets('calls repository submit and pops on success', (tester) async {
    final mockRepo = MockAssignmentRepository();
    when(mockRepo.submit(1, answerText: 'My answer', answerLink: null))
        .thenAnswer((_) async => Success(SubmissionResult(
              submissionId: 10,
              status: 'submitted',
              submittedAt: DateTime.now(),
              isLate: false,
            )));

    final navigator = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          navigatorKey: navigator,
          home: const AssignmentSubmitScreen(assignmentId: 1),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('answer_text_field')), 'My answer');
    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pumpAndSettle();

    verify(mockRepo.submit(1, answerText: 'My answer', answerLink: null)).called(1);
  });
}
```

- [ ] **Step 2:** Run `flutter test test/.../assignment_submit_screen_test.dart` — compile error (screen doesn't exist).

- [ ] **Step 3: Implement**

  **`assignment_submit_screen.dart`** (new):
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../../../../../core/error/failure.dart';
  import '../../../../../core/error/result.dart';
  import '../../providers/assignment_providers.dart';

  class AssignmentSubmitScreen extends ConsumerStatefulWidget {
    const AssignmentSubmitScreen({super.key, required this.assignmentId});
    final int assignmentId;

    @override
    ConsumerState<AssignmentSubmitScreen> createState() => _AssignmentSubmitScreenState();
  }

  class _AssignmentSubmitScreenState extends ConsumerState<AssignmentSubmitScreen> {
    final _textCtrl = TextEditingController();
    final _linkCtrl = TextEditingController();
    bool _loading = false;

    @override
    void dispose() {
      _textCtrl.dispose();
      _linkCtrl.dispose();
      super.dispose();
    }

    Future<void> _submit() async {
      final text = _textCtrl.text.trim().isEmpty ? null : _textCtrl.text.trim();
      final link = _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim();

      if (text == null && link == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Isi jawaban atau link terlebih dahulu.')),
        );
        return;
      }

      setState(() => _loading = true);
      final result = await ref
          .read(assignmentRepositoryProvider)
          .submit(widget.assignmentId, answerText: text, answerLink: link);
      if (!mounted) return;
      setState(() => _loading = false);

      switch (result) {
        case Success():
          // Invalidate detail so the parent screen refreshes
          ref.invalidate(assignmentDetailProvider(widget.assignmentId));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tugas berhasil dikumpulkan!')),
          );
          Navigator.of(context).pop(true);
        case FailureResult(:final failure):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kumpulkan Tugas')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('answer_text_field'),
                controller: _textCtrl,
                decoration: const InputDecoration(
                  labelText: 'Jawaban',
                  hintText: 'Tulis jawabanmu di sini...',
                  border: OutlineInputBorder(),
                ),
                minLines: 4,
                maxLines: 12,
                maxLength: 10000,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('answer_link_field'),
                controller: _linkCtrl,
                decoration: const InputDecoration(
                  labelText: 'Link (opsional)',
                  hintText: 'https://drive.google.com/...',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('submit_button'),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Kumpulkan'),
              ),
            ],
          ),
        ),
      );
    }
  }
  ```

  **`assignment_detail_screen.dart`** — replace `_NoSubmissionBanner` widget body (the static text) with a tappable button:
  ```dart
  // In _DetailContent.build(), replace:
  //   _NoSubmissionBanner()
  // with:
  _SubmitBanner(assignmentId: detail.id)
  ```
  Add `_SubmitBanner` widget at bottom of file:
  ```dart
  class _SubmitBanner extends StatelessWidget {
    const _SubmitBanner({required this.assignmentId});
    final int assignmentId;

    @override
    Widget build(BuildContext context) {
      return FilledButton.icon(
        onPressed: () async {
          final submitted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AssignmentSubmitScreen(assignmentId: assignmentId),
            ),
          );
          // Provider invalidation is handled inside AssignmentSubmitScreen on success.
        },
        icon: const Icon(Icons.upload_outlined),
        label: const Text('Kumpulkan Tugas'),
      );
    }
  }
  ```
  Add import: `import 'assignment_submit_screen.dart';`

- [ ] **Step 4:** Run `flutter test` — all tests green. Run `flutter analyze` — no errors.
- [ ] **Step 5:** Commit `feat(mobile/assignments): submit screen + detail screen integration`

---

### Task 5: Manual curl smoke test + final regression

**Goal:** Confirm end-to-end on local server.

- [ ] **Step 1:** Boot dev server: `php artisan serve` (from `src/`)
- [ ] **Step 2:** Get a student token:
  ```bash
  curl -s -X POST http://localhost:8000/api/v1/auth/login \
    -H 'Content-Type: application/json' \
    -d '{"email":"<student_email>","password":"<password>"}' | jq .
  ```
- [ ] **Step 3:** Happy-path submit:
  ```bash
  curl -s -X POST http://localhost:8000/api/v1/student/assignments/<id>/submit \
    -H 'Authorization: Bearer <token>' \
    -H 'Content-Type: application/json' \
    -d '{"answer_text":"Test answer from curl","answer_link":"https://example.com"}' | jq .
  ```
  Expect: `201` with `data.status == "submitted"`.
- [ ] **Step 4:** Duplicate submit → expect `409`.
- [ ] **Step 5:** Run full Pest suite: `./vendor/bin/pest tests/Feature/Api/V1/Student/` — all green.
- [ ] **Step 6:** Run `flutter test` — all green.
- [ ] **Step 7:** Commit `test: manual smoke test confirmed — assignment submission e2e`

---

## Definition of Done

- [ ] `POST /api/v1/student/assignments/{id}/submit` reachable and documented in this plan
- [ ] Validation tested (422 — missing both fields, invalid URL)
- [ ] Authz tested (401 — no token; 403 — teacher role)
- [ ] 404 tested (wrong class / inactive assignment)
- [ ] 409 tested (duplicate submission)
- [ ] `is_late` flag correct when `due_date` in the past
- [ ] DB row verified in test via `assertDatabaseHas`
- [ ] Mobile: submit screen renders text + link fields + button
- [ ] Mobile: empty submit shows client-side validation snackbar (no network call)
- [ ] Mobile: success pops screen and invalidates detail provider
- [ ] Mobile: error shows failure message from API
- [ ] Pest tests pass: `./vendor/bin/pest tests/Feature/Api/V1/Student/`
- [ ] Flutter tests pass: `flutter test`
- [ ] `flutter analyze` clean
- [ ] Manual curl smoke test confirmed

---

## Risk register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `ValidationFailure` class missing from `core/error/failure.dart` | Medium | Low | Check file before Task 3 Step 3; add if missing (single-line subclass). |
| `ValidationException` not mapped to `ValidationFailure` in repo | Medium | Low | `api_client.dart` already throws `ValidationException` on 422; add catch in `submit()`. |
| DB unique constraint (`oa_submissions_unique`) bubbles up as `500` instead of `409` | Low | Medium | Service checks `exists()` before `create()` → avoids hitting constraint; wrap `create()` in try/catch `QueryException` as belt-and-suspenders. |
| Mobile: `ref.invalidate(assignmentDetailProvider(id))` inside a non-Riverpod widget (the `_SubmitBanner` is a plain `StatelessWidget`) | High | Low | `_SubmitBanner` receives `assignmentId` and the navigation back; invalidation is done inside `AssignmentSubmitScreen` (a `ConsumerStatefulWidget`) — no issue. |
| Assignment `status` is `inactive` but student has a class link | Low | Low | `where('status', 'active')` guard in service returns 404; test covered. |
| Quiz `type` assignments: `answer_text` only — teachers expect per-question answers | Medium | Low | MVP explicitly scoped to free-text answers; plan documents this as future work; no data is corrupted. |
