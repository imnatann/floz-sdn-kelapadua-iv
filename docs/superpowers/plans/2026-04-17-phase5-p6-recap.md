# Phase 5 — P6 Recap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable teachers to view attendance and grade summaries per teaching assignment — a read-only recap screen showing per-student attendance counts (hadir/sakit/izin/alpha) and grade breakdowns. This completes the Phase 5 teacher MVP.

**Architecture:** Backend adds 2 read-only endpoints: `GET /teacher/teaching-assignments/{id}/attendance-recap` and `/grade-recap`. Mobile adds `features/teacher/recaps/` with a `RecapScreen` that toggles between attendance and grade views. Rekap tab in TeacherShell wired via the same `ClassesListScreen(onClassTap:)` pattern used for Nilai tab.

**Tech Stack:** Laravel 12, Pest, Flutter 3.11, Riverpod, Dio, mocktail

---

## Key Decisions

1. **Endpoints:** `GET /api/v1/teacher/teaching-assignments/{id}/attendance-recap` + `/grade-recap`. Both `role:teacher`, teacher must own TA.
2. **Attendance recap response:** `{data: {teaching_assignment: {id, subject_name, class_name}, students: [{id, name, nis, hadir, sakit, izin, alpha, total, percentage}]}}` — counts per student across all meetings in active semester.
3. **Grade recap response:** `{data: {teaching_assignment: {id, subject_name, class_name}, students: [{id, name, nis, daily_test_avg, mid_test, final_test, final_score, predicate}]}}` — same as grade-roster but read-only intent.
4. **Mobile screen:** `RecapScreen` with 2-tab toggle (Absensi/Nilai). Each tab shows a student list with summary data. No edit, no submit. Pull to refresh.
5. **Rekap tab wire:** Same `ClassesListScreen(onClassTap:)` pattern → navigate to RecapScreen.
6. **Cache:** No cache (always fresh — recap data changes when attendance/grades are updated).

---

## Tasks

### Task 1: RecapService TDD (attendance + grade recap)

**Files:** `src/app/Services/Mobile/RecapService.php` + `src/tests/Unit/Services/Mobile/RecapServiceTest.php`

Service:
- `attendanceRecap(TeachingAssignment $ta, User $user)` — queries Attendance grouped by student_id for the TA's class + active semester, counts each status type
- `gradeRecap(TeachingAssignment $ta, User $user)` — queries Grade for the TA's subject + class + active semester, returns each student's scores

Test cases (4): attendance recap with mixed statuses + percentage calculation, attendance recap empty, grade recap with scores, grade recap empty.

### Task 2: V1 Controller + Feature Tests + Routes

**Files:** `src/app/Http/Controllers/Api/V1/MobileTeacherRecapController.php` + `src/tests/Feature/Api/V1/Teacher/RecapTest.php`

Controller: `attendanceRecap(Request, int $taId)` + `gradeRecap(Request, int $taId)`. Authz: teacher owns TA.

Feature tests (5): attendance recap happy, grade recap happy, 403 wrong teacher, 403 student role, 401 no token.

Routes inside `role:teacher`: `GET /teacher/teaching-assignments/{ta}/attendance-recap` + `/grade-recap`.

### Task 3: Mobile data layer (domain + DTO + datasource + repo + tests)

Entity: `AttendanceRecap { taInfo, students: [StudentAttendanceRecap] }`, `GradeRecap { taInfo, students: [StudentGradeRecap] }`.

No cache, 4 repo tests (fetch attendance happy/error, fetch grades happy/error).

### Task 4: Providers + RecapScreen + widget test + wire Rekap tab

Providers: `recapRepositoryProvider`, `attendanceRecapProvider.family`, `gradeRecapProvider.family`.

RecapScreen (ConsumerWidget): receives `taId`, `subjectName`, `className`. 2-tab toggle chips (Absensi/Nilai). Each tab shows student list:
- Absensi tab: student name + NIS + H/S/I/A count badges + percentage bar
- Nilai tab: student name + NIS + Harian/UTS/UAS/Final scores + predicate badge

Widget test (3): attendance data shows, grade data shows, error with retry.

Wire Rekap tab: `TeacherShell` index 2 → `ClassesListScreen(onClassTap: → RecapScreen)`.

### Task 5: Integration test + final tag

Run full regression, curl test, tag `p6-recap-complete` + `phase5-complete`.

---

## Notes for executing agent

- **Attendance counting:** `Attendance::where('class_id', $ta->class_id)->where('semester_id', $activeSemester->id)->get()->groupBy('student_id')` → per student, count statuses. Percentage = `hadir / total * 100`.
- **Grade recap is basically the same as grade roster** from P5. Could reuse `GradingService::getRoster()` — BUT creating a separate `RecapService` is cleaner for separation of concerns (recap is read-only, grading is mutative).
- **`ClassesListScreen(onClassTap:)` pattern** already works from P5. Just add it to Rekap tab the same way.
- **This is the LAST phase of Phase 5.** After P6, the entire Phase 5 spec is complete.
- Same safety rules: NEVER migrate. Tests use RefreshDatabase.
