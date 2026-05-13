# Phase 7 Codebase Research — School-Year Transition & Student Promotion Flow

**Date:** 2026-05-08
**Branch:** chore/remove-tenant-leftovers

---

## 1. StudentMutation Model

**File:** `src/app/Models/StudentMutation.php`
**Migration:** `2026_02_16_100000_enhance_students_module.php`

### Fields
| Column | Type | Notes |
|--------|------|-------|
| `student_id` | FK → `students` | `cascadeOnDelete` |
| `type` | string | `promotion \| retention \| transfer_in \| transfer_out \| dropout \| graduated` |
| `from_class_id` | FK → `classes` (nullable) | `nullOnDelete` — survives class deletion |
| `to_class_id` | FK → `classes` (nullable) | `nullOnDelete` — survives class deletion |
| `date` | date | cast to `Carbon\Carbon` |
| `reason` | string (nullable) | e.g. "Pindah ikut orang tua" |
| `reference_number` | string (nullable) | SK number |
| `notes` | text (nullable) | |

### Relationships
- `student()` → BelongsTo Student
- `fromClass()` → BelongsTo SchoolClass (`from_class_id`)
- `toClass()` → BelongsTo SchoolClass (`to_class_id`)

### Who creates them today
**Nobody.** No controller, service, or artisan command references `StudentMutation` except the model itself and its migration. The mutation table exists but is **completely unwritten** — Phase 7 must build all write paths from scratch.

---

## 2. Student Lifecycle Fields

**File:** `src/app/Models/Student.php`

### Status enum (string, no DB-level enum)
`active | graduated | transferred | dropout`

### Key columns
| Column | Type | Behavior |
|--------|------|----------|
| `class_id` | FK → `classes` (nullable) | `SET NULL` on class delete — student survives, goes classless |
| `status` | string | manually set; no auto-transition logic exists |
| `email` | string (nullable) | soft-FK to `users.email` — linked via `belongsTo(User, 'email', 'email')` |

### Relationships
- `class()` → BelongsTo SchoolClass
- `grades()` → HasMany Grade
- `reportCards()` → HasMany ReportCard
- `attendances()` → HasMany Attendance
- `mutations()` → HasMany StudentMutation (ordered by date desc)
- `scopeActive()` → `where('status', 'active')`

### Key insight
`class_id` is the single live pointer to a student's current class. Year-over-year, this pointer must be re-aimed at the new-AY class. There is no `academic_year_id` on students — AY is implied through `class → academic_year_id`.

---

## 3. Class Model & Year Scope

**File:** `src/app/Models/SchoolClass.php`
**Migration:** `2024_01_04_000001_create_classes_table.php`

### Key columns
| Column | Notes |
|--------|-------|
| `academic_year_id` | FK → `academic_years`, `CASCADE` delete |
| `grade_level` | integer 1–6 (SD grade) |
| `homeroom_teacher_id` | FK → `teachers`, `SET NULL` on delete |
| `status` | `active` default |

### Classes are year-scoped, NOT long-lived
Each class record belongs to exactly one AY. Seeder confirms: `SchoolClass::firstOrCreate(['name' => ..., 'academic_year_id' => $ay->id], ...)`. At year transition, NEW class records must be created for the new AY — same names/grade_levels, new `academic_year_id`.

### Grade levels in demo data
Kelas 4A (grade 4), Kelas 4B (grade 4), Kelas 5A (grade 5), Kelas 6A (grade 6).
Grade 1–3 absent from demo; full school has grades 1–6.

---

## 4. AY/Semester Active-Flag Consumers

### Exclusive flag enforcement
- `AcademicYearController::activate()` — blanket `UPDATE is_active=false` then sets one true.
- `SemesterController::activate()` — scoped: deactivates only siblings within same AY, then sets one true.

### `is_active=true` readers (Semester)
| File | Count | Purpose |
|------|-------|---------|
| `AttendanceController` | 5 occurrences | attendance index, store, update, recap, summary |
| `GradeController` | 1 | grade input form |
| `TaskController` | 2 | task index + store |
| `ExamController` | 2 | exam index + store |
| `GradingService` (mobile) | 1 | mobile grade submit |
| `RecapService` (mobile) | 1 | mobile recap |
| `AttendanceService` (mobile) | 1 | mobile attendance |

### `is_active=true` readers (AcademicYear)
- `HasAcademicYear` trait (`scopeCurrentAcademicYear`, `getActiveAcademicYear`) — used by `SchoolClass` (has the trait).
- `SchoolClassController`, `TeachingAssignmentController` — pass all AYs to forms with `is_active` flag for UI highlighting.

**Risk:** 13+ code paths hard-assume `Semester::where('is_active', true)->first()`. If no semester is active during transition, ALL those flows silently fail or return null.

---

## 5. Cascade Behaviors (Data-Loss Map)

### Deletion cascades from top to bottom

```
AcademicYear (deleted)
  ├── Semester            → CASCADE delete
  │     ├── Grade         → CASCADE delete  ⚠ PERMANENT DATA LOSS
  │     └── ReportCard    → CASCADE delete  ⚠ PERMANENT DATA LOSS
  └── SchoolClass         → CASCADE delete
        ├── TeachingAssignment → CASCADE delete
        │     ├── Schedule     → CASCADE delete
        │     └── Meeting      → (check Meeting model)
        ├── Grade              → CASCADE delete  ⚠ (double-path via class_id)
        ├── ReportCard         → CASCADE delete  ⚠ (double-path via class_id)
        └── Attendance         → CASCADE delete  ⚠ (added 2026-02-27 via class_id)

Student (deleted)
  ├── Grade              → CASCADE delete
  ├── ReportCard         → CASCADE delete
  ├── Attendance         → CASCADE delete
  └── StudentMutation    → CASCADE delete
```

### Non-cascade behaviors
| FK | On Delete | Implication |
|----|-----------|-------------|
| `students.class_id` → `classes` | SET NULL | Students survive class deletion; they go classless |
| `student_mutations.from_class_id` | SET NULL | Mutation history survives class deletion |
| `student_mutations.to_class_id` | SET NULL | Same |
| `classes.homeroom_teacher_id` | SET NULL | Class survives teacher deletion |

### Critical finding
`attendance.class_id` has `cascadeOnDelete` (added in migration `2026_02_27`). Deleting a class **deletes all its attendance records**. Since classes are year-scoped, if someone deletes an old class record, attendance history for that class-year is gone. Phase 7 must NOT delete old classes — deactivate/archive only.

---

## 6. Existing Promotion/Rollover Code

**Result: None.** Grep across `src/app`, `src/database`, `src/routes` for `promot`, `graduat`, `transition`, `rollover`, `kenaikan`, `kelulusan` found zero business logic. Only occurrences:
- `StudentMutation.php` comment (type list)
- `StudentController.php` API validation enum (status filter only)
- Migration type comment

No artisan command, no service class, no policy or observer handles promotion. **Phase 7 builds this from zero.**

---

## 7. Migration Schema Quick Reference

### `students`
`id, nis (unique), nisn (unique, nullable), nik (unique, nullable), family_card_number, name, gender, birth_place, birth_date, religion, address, parent_name, parent_phone, email, class_id (FK→classes SET NULL), status, photo_url, timestamps`

### `classes`
`id, name, grade_level, academic_year_id (FK→academic_years CASCADE), homeroom_teacher_id (FK→teachers SET NULL), max_students, status, timestamps`

### `student_mutations`
`id, student_id (FK→students CASCADE), type (string), from_class_id (FK→classes SET NULL), to_class_id (FK→classes SET NULL), date, reason, reference_number, notes, timestamps`

### `academic_years`
`id, name, start_date, end_date, is_active (bool, default false), timestamps`

### `semesters`
`id, academic_year_id (FK→academic_years CASCADE), semester_number (1|2), start_date, end_date, is_active (bool, default false), timestamps — UNIQUE(academic_year_id, semester_number)`

### `teaching_assignments`
`id, teacher_id (FK CASCADE), subject_id (FK CASCADE), class_id (FK CASCADE), academic_year_id (FK CASCADE), timestamps — UNIQUE(teacher+subject+class+ay)`

### `schedules`
`uuid id, teaching_assignment_id (FK CASCADE), day_of_week, start_time, end_time, timestamps`

### `grades`
`id, student_id (FK CASCADE), subject_id (FK CASCADE), class_id (FK CASCADE), semester_id (FK CASCADE), teacher_id (FK SET NULL), score fields..., timestamps — UNIQUE(student+subject+semester)`

### `attendance`
`id, student_id (FK CASCADE), date, status, notes, class_id (FK CASCADE), subject_id (FK SET NULL), semester_id (FK CASCADE), recorded_by (FK SET NULL), meeting_number, timestamps — UNIQUE(student+date)`

### `report_cards`
`id, student_id (FK CASCADE), class_id (FK CASCADE), semester_id (FK CASCADE), rank, scores, attendance counts, text fields, status, published_at, pdf_url, timestamps — UNIQUE(student+semester)`

---

## 8. Data Coupling Diagram

```text
AcademicYear (is_active: 1 active at a time)
  │
  ├─[has_many]─> Semester (is_active: 1 active at a time, scoped to AY)
  │                │
  │                ├─[cascade]─> Grade (student+subject+semester unique)
  │                └─[cascade]─> ReportCard (student+semester unique)
  │
  └─[has_many]─> SchoolClass (academic_year_id, grade_level 1-6)
                   │
                   ├─[cascade]─> TeachingAssignment (teacher+subject+class+AY unique)
                   │               └─[cascade]─> Schedule (day+time)
                   │               └─[cascade]─> Meeting → (grades/attendance via meeting)
                   │
                   ├─[cascade]─> Grade (also via semester_id)
                   ├─[cascade]─> Attendance (class_id CASCADE added 2026-02)
                   ├─[cascade]─> ReportCard (also via semester_id)
                   │
                   └─[set_null]─> Student.class_id ← THE PROMOTION POINTER
                                   │
                                   ├─[cascade]─> Grade
                                   ├─[cascade]─> Attendance
                                   ├─[cascade]─> ReportCard
                                   └─[cascade]─> StudentMutation
                                                   ├─ from_class_id (set_null)
                                                   └─ to_class_id   (set_null)
```

**Promotion = re-point `students.class_id` to new-AY class + write StudentMutation record.**

---

## 9. Open Questions for Planner

**Q1. Grade-6 graduation flow:** When a Grade-6 student graduates, `status` → `graduated` and `class_id` → NULL. But their old class (Kelas 6A in old AY) had `grade_level=6`. Does the UI need a separate "graduation ceremony" step distinct from bulk promotion, or is it just `type=graduated` mutation + status change?

**Q2. Retention (tinggal kelas):** A retained student stays at the same grade level. In the new AY they should be assigned to the new-AY class of the SAME grade. The mutation type `retention` is defined but no logic exists. Who decides (admin marks individual students before bulk run)?

**Q3. Class creation strategy for new AY:** Does the admin manually create new-AY classes first, then run promotion? Or does Phase 7 auto-create classes (e.g. copy grade structure from old AY)? Auto-create risks wrong homeroom assignments.

**Q4. TeachingAssignments for new AY:** New classes need TAs re-created. Copy from previous AY (same teacher/subject/class-name mapping) or require manual entry? The TA `booted()` hook auto-generates Meetings on creation — bulk-copying TAs will flood Meeting records.

**Q5. Semester activation during transition:** At year-end, old AY's semester is still `is_active`. Before promotion runs, must the new AY + Semester 1 be activated first? If yes, the 13+ `Semester::where('is_active',true)->first()` callers will immediately start writing to the new semester — is that safe before student `class_id` is re-pointed?

**Q6. Attendance orphan risk:** `attendance.class_id` has CASCADE delete. If an admin deletes an old-AY class (thinking it's stale), all attendance records for that class-year are destroyed. Phase 7 must either (a) add a guard on class deletion when old-AY attendance exists, or (b) document this loudly in UI.

**Q7. Bulk vs. individual promotion UI:** Should Phase 7 deliver a bulk "promote all Grade-N students" wizard, individual per-student promotion, or both?

---

## 10. Recommended Approach Sketch

### The Correct Mental Model
Classes are AY-scoped records — they are not reused across years. Promotion is not about "moving students through the same class"; it is about **re-pointing `students.class_id`** from an old-AY class to a matching new-AY class. Old class records (with their grades, attendance, report cards) remain intact as the historical record. Nothing gets deleted.

### Transition Flow (proposed)
1. **Admin creates new AY** (via existing AY CRUD). Phase 7 adds a "Setup New Year" wizard that auto-creates classes for grades 1–6 in the new AY (copying structure from the previous AY, homeroom TBD).
2. **Admin reviews student disposition** per grade: each student is pre-marked `promote` (default), with admin able to flip individuals to `retention`, `graduated` (grade 6), `transfer_out`, or `dropout`.
3. **Admin confirms and executes** the transition. The system runs in a DB transaction:
   - For each `promote`: find the new-AY class matching `grade_level + 1`, update `students.class_id`, write `StudentMutation(type=promotion, from=old, to=new, date=today)`.
   - For `graduated` (grade 6): set `students.status=graduated`, `class_id=NULL`, write `StudentMutation(type=graduated)`.
   - For `retention`: find new-AY class matching same `grade_level`, update `students.class_id`, write `StudentMutation(type=retention)`.
   - For `dropout`/`transfer_out`: set `students.status` accordingly, `class_id=NULL`, write mutation.
4. **Admin activates new AY** (deactivates old): existing `AcademicYearController::activate` handles the flag swap. New Semester 1 separately activated.
5. **TAs rebuilt manually** (or via a copy-from-prior-AY helper): safest option given the Meeting auto-generation side effect in TA's `booted()` hook. Do NOT bulk-copy TAs without suppressing Meeting generation.

### What Phase 7 MUST NOT Do
- Delete old class records (CASCADE wipes grades, attendance, report cards).
- Delete old AY records (same cascade chain reaches grades and semesters).
- Run promotion outside a DB transaction (partial promotion = corrupted state).
