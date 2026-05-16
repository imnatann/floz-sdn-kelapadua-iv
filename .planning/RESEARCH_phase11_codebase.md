# Phase 11 Codebase Research — Analytics Dashboard

**Date:** 2026-05-09  
**Scope:** Aggregation surfaces, schema, services, performance

---

## 1. Schema Quick Reference

| Table | Key Columns | Aggregation Role |
|---|---|---|
| `students` | id, class_id, status, gender, birth_date | dimension; filter by status='active' |
| `classes` | id, name, grade_level, academic_year_id, homeroom_teacher_id | dimension; group by grade_level |
| `academic_years` | id, name, is_active, start_date, end_date | top-level time dimension |
| `semesters` | id, academic_year_id, semester_number, is_active | time slice for all fact tables |
| `subjects` | id, name, status | dimension |
| `teachers` | id, name, status | dimension |
| `teaching_assignments` | id, teacher_id, subject_id, class_id, academic_year_id | bridge for attendance/grade joins |
| `attendance` | id, student_id, class_id, subject_id, semester_id, meeting_number, date, status | **primary fact** — status ∈ {present, sick, permit, absent} |
| `grades` | id, student_id, subject_id, class_id, semester_id, daily_test_avg, mid_test, final_test, final_score, predicate | **primary fact** — pre-computed per-subject score |
| `report_cards` | id, student_id, class_id, semester_id, report_type, rank, average_score, total_score, attendance_{present,sick,permit,absent} | **summary fact** — already aggregated; fastest for dashboard widgets |
| `tasks` | id, class_id, subject_id, semester_id, teacher_id, task_date, status | parent of task_scores |
| `task_scores` | id, task_id, student_id, score | formative scores |
| `exams` | id, class_id, subject_id, semester_id, exam_type (ulangan_harian/uts/uas), exam_date | parent of exam_scores |
| `exam_scores` | id, exam_id, student_id, score | summative scores |
| `meetings` | id, teaching_assignment_id, meeting_number (1-16), is_locked | attendance session metadata |

---

## 2. Index Inventory

| Table | Index | Type | Covers |
|---|---|---|---|
| `attendance` | (class_id, semester_id, meeting_number, student_id) | UNIQUE | per-meeting dedup; covers class+semester attendance queries |
| `attendance` | date | INDEX | today-only queries (DashboardController uses this) |
| `grades` | (student_id, subject_id, semester_id) | UNIQUE | per-student-subject lookup |
| `grades` | (class_id, semester_id) | INDEX | class-wide grade scans |
| `report_cards` | (student_id, semester_id) | UNIQUE | one raport per student per semester |
| `report_cards` | (class_id, semester_id) | INDEX | class ranking queries |
| `classes` | (academic_year_id, grade_level) | INDEX | year+grade filters |
| `students` | status | INDEX | active student count |
| `students` | class_id | INDEX | students-per-class count |
| `teaching_assignments` | academic_year_id | INDEX | year-scoped TA lookup |
| `teaching_assignments` | (teacher_id, subject_id, class_id, academic_year_id) | UNIQUE | |
| `schedules` | (teaching_assignment_id, day_of_week) | INDEX | today's schedule |
| `semesters` | (academic_year_id, semester_number) | UNIQUE | |
| `task_scores` | (task_id, student_id) | UNIQUE | |
| `exam_scores` | (exam_id, student_id) | UNIQUE | |

**Gaps — missing indexes for analytics queries:**

| Gap | Impact |
|---|---|
| `attendance(student_id, semester_id)` | Student attendance-% widget does full scan filtered by student+semester; no covering index |
| `grades(semester_id)` — standalone | Semester-wide grade distribution query hits (class_id, semester_id) but not semester-only |
| `task_scores` — no index on student_id | Per-student task performance widget requires join scan |
| `exam_scores` — no index on student_id | Same as above for exam scores |
| `exams(class_id, semester_id, exam_type)` | Frequent filter triple in ReportCardService; no composite index |
| `tasks(class_id, semester_id)` | Same pattern, same gap |

---

## 3. Existing Services (analytics-relevant)

### `ReportCardService`

| Method | What it computes | Reuse for analytics |
|---|---|---|
| `generate(studentId, classId, semesterId, reportType)` | Calculates all subject grades + attendance summary, writes report_card row | Not directly — too write-heavy; read report_cards instead |
| `calculateSubjectGrade(...)` (protected) | Raw SQL AVGs across task_scores + exam_scores, writes grades row | Pattern to clone for analytics queries |
| `calculateRankings(classId, semesterId, reportType)` | Orders report_cards by average_score, sets rank | Reuse: query report_cards ORDER BY average_score |
| `calculateAttendance(studentId, classId, semesterId)` (protected) | Eloquent collection filter on attendance | Reuse logic; for analytics use raw SQL GROUP BY status |
| `publish(ReportCard)` | Sets status=published | Not analytics-relevant |

### `GradeCalculationService`

| Method | What it computes | Reuse |
|---|---|---|
| `calculateSD(daily, mid, final)` | Weighted final score SD formula | Use for display/legend only |
| `calculateSMPSMA(knowledge, skill)` | Average + predicate | Same |
| `determinePredicate(score)` (static) | A/B/C/D from config thresholds | Call directly in analytics for predicate distribution widget |
| `meetsKkm(score, kkm)` | Boolean pass/fail | Use for below-KKM count widget |

### `YearTransitionService`, `PdfGeneratorService`

Not analytics-relevant.

---

## 4. Existing Aggregation Controllers

### `DashboardController::index`

Already produces:

| Widget | Query Pattern | Notes |
|---|---|---|
| total_students | `Student::active()->count()` | Eloquent scope |
| total_teachers | `Teacher::where('status','active')->count()` | |
| total_classes | `SchoolClass::count()` | |
| attendance_present (today) | `Attendance::whereDate('date', today)->where('status','present')->count()` | Uses date index |
| attendance_absent (today) | Same with `!=` present | Catches sick+permit+absent |
| Student: attendance_percentage | Two separate COUNT queries; no single SQL | Inefficient — replace with single GROUP BY |
| Teacher: my_classes_count | pluck+merge+unique in PHP | Inefficient for analytics |

**Conclusion:** DashboardController is role-gated and UI-coupled (Inertia). Analytics dashboard needs a separate `AnalyticsController` or `AnalyticsService` — do not extend DashboardController.

No mobile recap controllers exist (`src/app/Http/Controllers/Mobile/` is absent).

---

## 5. Recommended Query Patterns

| Widget | Approach | Reason |
|---|---|---|
| School-wide counts (students, teachers, classes) | Eloquent `count()` | Simple; already cached in model scopes |
| Today's attendance summary | Raw SQL single GROUP BY | Replace 2 Eloquent queries with 1 |
| Class attendance rate (semester) | Raw SQL GROUP BY status, semester_id | 16 000-row table; GROUP BY is fast with composite index |
| Per-subject grade distribution | Read from `grades` table with Eloquent | Pre-computed; trivial |
| Class ranking | Read `report_cards` ORDER BY average_score | Pre-computed; trivial |
| Grade average per class/semester | Eloquent `avg('final_score')` on grades | Covered by (class_id, semester_id) index |
| Predicate distribution | Raw SQL `SELECT predicate, COUNT(*) FROM grades GROUP BY predicate WHERE class_id=? AND semester_id=?` | |
| Task/exam score trends over time | Raw SQL JOIN tasks/exams + scores GROUP BY task_date | No pre-computed column; raw SQL required |
| Below-KKM student list | Raw SQL with configurable threshold | Use `GradeCalculationService::meetsKkm` threshold from config |
| Excel export of any widget | Clone `StudentsImport` pattern → create `*Export` class implementing `FromCollection` | maatwebsite/excel already wired |

**Rule of thumb:** If the answer is already in `report_cards` or `grades` — use Eloquent. If it requires joining 3+ tables or cross-semester aggregation — use raw SQL with `DB::select()`.

---

## 6. Performance Estimates

| Scenario | Worst-case rows | Expected query time (no index gap) |
|---|---|---|
| `attendance` — 1 year, 200 students, 16 meetings × 10 subjects | 32 000 rows | <20 ms with composite index |
| `grades` — 200 students × 10 subjects × 2 semesters | 4 000 rows | <5 ms |
| `report_cards` — 200 students × 2 semesters × 2 types | 800 rows | <2 ms |
| `task_scores` — 200 students × 20 tasks × 2 semesters | 8 000 rows | 30-80 ms without student_id index |
| `exam_scores` — 200 students × 10 exams × 2 semesters | 4 000 rows | 20-50 ms without student_id index |

**Biggest perf concern:** `task_scores` and `exam_scores` have no student_id index. Per-student task performance queries (JOIN + WHERE student_id) will scan the full table. At 8 000 rows this is tolerable now but degrades if multiple years accumulate. Add indexes in Wave 0 migration.

Single-school scale (200 students) means no caching layer is needed for Phase 11. Direct queries are fine.

---

## 7. Excel Export — Existing Usage

**Pattern found in:** `StudentController::import` + `app/Imports/StudentsImport.php`

```php
// Import side (existing)
Excel::import(new StudentsImport, $request->file('file'));

// Export side (to create) — clone this pattern:
// app/Exports/AttendanceExport.php  implements FromCollection, WithHeadings
return Excel::download(new AttendanceExport($params), 'attendance.xlsx');
```

`maatwebsite/excel` is installed and confirmed working (import path proven). Export classes need to be created — none exist yet. Use `FromCollection` + `WithHeadings` for simple tabular exports. Use `FromQuery` for large datasets to avoid loading all rows into memory.

---

## 8. Missing Indexes (Recommend Add in Phase 11 Wave 0)

```php
// Migration: add_analytics_indexes
Schema::table('attendance', function (Blueprint $table) {
    $table->index(['student_id', 'semester_id'], 'attendance_student_semester_idx');
});
Schema::table('task_scores', function (Blueprint $table) {
    $table->index('student_id', 'task_scores_student_idx');
});
Schema::table('exam_scores', function (Blueprint $table) {
    $table->index('student_id', 'exam_scores_student_idx');
});
Schema::table('exams', function (Blueprint $table) {
    $table->index(['class_id', 'semester_id', 'exam_type'], 'exams_class_semester_type_idx');
});
Schema::table('tasks', function (Blueprint $table) {
    $table->index(['class_id', 'semester_id'], 'tasks_class_semester_idx');
});
```

Total: **5 missing indexes** across 4 tables.

---

## 9. Reusable Helpers

| Component | What to lift into `AnalyticsService` |
|---|---|
| `ReportCardService::calculateAttendance` | Attendance status grouping logic → `AnalyticsService::attendanceSummary($studentId, $classId, $semesterId)` |
| `GradeCalculationService::determinePredicate` | Already static — call directly |
| `DashboardController` student/teacher count queries | Extract to `AnalyticsService::schoolCounts()` |
| `report_cards` rank + average_score columns | Read directly; no re-computation needed |
| `grades.(class_id, semester_id)` index | Best entry point for all class-level grade widgets |
| `ReportCardService::calculateSubjectGrade` raw SQL patterns | Clone DB::table()->join()->where()->avg() pattern for analytics aggregation |
