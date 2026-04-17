# Phase 5 — P5 Grade Input Batch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable teachers to batch-input student grades (Harian/UTS/UAS) per teaching assignment from their phone — view the grade roster, fill in scores for each student, submit. Backend auto-calculates `final_score` and `predicate`.

**Architecture:** Backend adds 2 endpoints: `GET /teacher/teaching-assignments/{id}/grade-roster` (load current grades) and `POST /teacher/teaching-assignments/{id}/grades` (batch upsert). Mobile adds `features/teacher/grades_input/` with a tab-based `GradeInputScreen` — one tab per score type (Harian/UTS/UAS) — each showing a simple student-list with one number input per row. Submit sends all values at once. `ClassesListScreen` is extended with an `onClassTap` callback so the Nilai tab can navigate to GradeInputScreen instead of ClassDetailScreen.

**Tech Stack:** Laravel 12, Pest, Flutter 3.11, Riverpod, Dio, mocktail

---

## Key Decisions

1. **Endpoints:** `GET /api/v1/teacher/teaching-assignments/{id}/grade-roster` + `POST /api/v1/teacher/teaching-assignments/{id}/grades`. Both `role:teacher` guarded. Teacher must own the TA.
2. **Roster response:** `{data: {teaching_assignment: {id, subject_name, class_name}, students: [{id, name, nis, daily_test_avg, mid_test, final_test, final_score, predicate}]}}`. Null values for unfilled scores.
3. **Submit payload:** `{entries: [{student_id, daily_test_avg, mid_test, final_test}]}`. All score fields nullable (teacher can submit partial — e.g., only Harian filled, UTS/UAS null). Scores 0–100.
4. **Auto-calculation:** Backend computes `final_score = (daily * 0.3) + (mid * 0.3) + (final * 0.4)` ONLY when all 3 are non-null. `predicate`: A≥90, B≥80, C≥70, D<70.
5. **DB operation:** `Grade::updateOrCreate` with key `(student_id, subject_id, semester_id)`. Uses `DB::transaction`.
6. **Mobile UI:** Tab selector (Harian/UTS/UAS) — each tab shows student list with single number input. Bottom sticky bar with summary + save button. Local form state across all 3 tabs, single submit sends everything.
7. **Nilai tab wire:** `ClassesListScreen` gets an optional `onClassTap` callback. Nilai tab uses it to navigate to GradeInputScreen(taId).
8. **Semester:** Uses active semester (same as attendance).

---

## File Structure

### Backend — create
```
src/app/Services/Mobile/GradingService.php
src/app/Http/Controllers/Api/V1/MobileTeacherGradeController.php
src/app/Http/Requests/Api/V1/Grade/StoreGradeRequest.php
src/tests/Unit/Services/Mobile/GradingServiceTest.php
src/tests/Feature/Api/V1/Teacher/GradeInputTest.php
```

### Backend — modify
```
src/routes/api.php
```

### Mobile — create
```
floz_mobile/lib/features/teacher/grades_input/domain/entities/grade_roster.dart
floz_mobile/lib/features/teacher/grades_input/domain/repositories/grade_input_repository.dart
floz_mobile/lib/features/teacher/grades_input/data/models/grade_roster_dto.dart
floz_mobile/lib/features/teacher/grades_input/data/datasources/grade_input_remote_datasource.dart
floz_mobile/lib/features/teacher/grades_input/data/repositories/grade_input_repository_impl.dart
floz_mobile/lib/features/teacher/grades_input/providers/grade_input_providers.dart
floz_mobile/lib/features/teacher/grades_input/presentation/screens/grade_input_screen.dart
floz_mobile/test/features/teacher/grades_input/data/repositories/grade_input_repository_impl_test.dart
floz_mobile/test/features/teacher/grades_input/presentation/screens/grade_input_screen_test.dart
```

### Mobile — modify
```
floz_mobile/lib/core/network/api_endpoints.dart
floz_mobile/lib/features/teacher/classes/presentation/screens/classes_list_screen.dart
floz_mobile/lib/features/teacher/shared/widgets/teacher_shell.dart
```

---

## Tasks

### Task 1: GradingService TDD (test + impl)

Service with `getRoster(TeachingAssignment $ta, User $user)` + `storeGrades(TeachingAssignment $ta, array $entries, User $user)`.

`getRoster`: returns students in the TA's class with their existing grades for the active semester.

`storeGrades`: `updateOrCreate` per student in `DB::transaction`. Auto-calculates `final_score` + `predicate` when all 3 scores are non-null. Sets `teacher_id`, `class_id`, `semester_id` from context.

Test cases (6): roster happy, roster empty class, store creates new grades, store updates existing, auto-calculates final_score+predicate, partial scores (only harian) → final_score=null.

### Task 2: StoreGradeRequest + V1 Controller + Feature Tests + Routes

FormRequest: validates `entries.*.student_id` (required, exists), `entries.*.daily_test_avg` (nullable, numeric, 0-100), `entries.*.mid_test` (nullable, numeric, 0-100), `entries.*.final_test` (nullable, numeric, 0-100).

Controller: `MobileTeacherGradeController` with `roster(Request, int $taId)` + `store(StoreGradeRequest, int $taId)`. Authz: teacher must own the TA.

Feature tests (5): roster GET, store POST, 422 validation (score > 100), 403 wrong teacher, 401 no token.

Routes: inside `role:teacher` block:
```
GET /teacher/teaching-assignments/{ta}/grade-roster
POST /teacher/teaching-assignments/{ta}/grades
```

### Task 3: Mobile data layer (domain + DTO + datasource + repo + test)

Entity: `GradeRoster { taId, subjectName, className, students: [StudentGrade] }`, `StudentGrade { id, name, nis, dailyTestAvg?, midTest?, finalTest?, finalScore?, predicate? }`.

Repo: no cache (always fresh). 4 tests (fetch happy, fetch error, submit happy, submit error).

### Task 4: Mobile providers + GradeInputScreen + widget test

Providers: `gradeInputRepositoryProvider`, `gradeRosterProvider.family<GradeRoster, int>`, `GradeSubmitController`.

GradeInputScreen (ConsumerStatefulWidget):
- Receives `taId`, `subjectName`, `className`
- Loads roster via provider
- 3-tab selector: Harian | UTS | UAS
- Each tab: student list with single number TextFormField (0-100)
- Local state: `Map<int, GradeEntry>` where GradeEntry = {daily, mid, final}
- Pre-fills from existing grades
- Bottom bar: "Simpan Nilai" button
- Submit sends all entries → snackbar success + pop

Widget test (3): shows student list, shows error, submit calls repo.

### Task 5: Wire Nilai tab + ClassesListScreen callback

Modify `ClassesListScreen`: add optional `onClassTap` callback. Default behavior (null): navigate to ClassDetailScreen. When provided: call the callback.

Modify `TeacherShell`: Nilai tab → `ClassesListScreen(onClassTap: (ta) => navigate to GradeInputScreen(taId: ta.id, ...))`.

### Task 6: Integration test + tag `p5-grade-input-complete`

---

## Notes for executing agent

- **Grade unique constraint:** `(student_id, subject_id, semester_id)`. The `updateOrCreate` uses these 3 columns as the find key.
- **final_score formula:** `round((daily_test_avg * 0.3) + (mid_test * 0.3) + (final_test * 0.4), 2)`. Only computed when ALL 3 are non-null. If any is null, set `final_score = null` and `predicate = null`.
- **Predicate:** A ≥ 90, B ≥ 80, C ≥ 70, D < 70.
- **Active semester:** `Semester::where('is_active', true)->first()`. Throw RuntimeException if none.
- **Teacher owns TA:** `$ta->teacher_id === $user->teacher->id`.
- **Score validation:** nullable numeric, min 0, max 100. NOT required — teacher can submit partial data.
- **Same safety rules:** NEVER migrate. Tests use RefreshDatabase.
