# Temporal / Historical Tracking — Design (Phase 1)

**Date:** 2026-05-14
**Status:** Approved (design phase)
**Phase:** 1 of 3

## Problem

Floz LMS currently overwrites `students.class_id` whenever a student is promoted, transferred, or otherwise reassigned. As a result, the system cannot answer questions like:

- "Di tahun ajaran 2025/2026 semester Ganjil, Nathan ada di kelas berapa?"
- "Tampilkan daftar siswa di Kelas 1 saat semester Genap 2025/2026, termasuk yang sudah pindah/lulus."

Tasks/exams/grades/report-cards are already historical (each row carries `class_id` + `semester_id`, and classes are year-bound). The missing piece is an authoritative roster: a record stating which students were enrolled in which class during which semester.

## Goals

- Allow querying "which students were in class X during semester Y?" — including students who later transferred, dropped, or graduated.
- Allow viewing a student's full enrollment timeline across semesters and years.
- Keep existing controllers and authorization logic working with minimal changes by retaining `students.class_id` as a denormalized "current" pointer.
- Reuse existing infrastructure: `student_mutations` (event log), `year_transition_logs`, `YearTransitionService`.

## Non-Goals (deferred to later phases)

- Phase 2: Per-semester schedules (`teaching_assignments` and `schedules` currently year-bound).
- Phase 3: Student timeline drill-down UI (period → tasks/grades/attendance for that period).
- Phase 3: Bulk-import historical enrollments from spreadsheets.
- Phase 3: Mobile API endpoints for historical view.

## User-Facing Decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Granularity | Per semester (each semester has its own roster) |
| Schedule granularity | Per semester (deferred to Phase 2) |
| Enrollment creation workflow | Auto carry-over on semester activation |
| Implementation scope | Phased rollout, Phase 1 = enrollments + student list filter |

## Section 1: Data Model

### New table: `student_class_enrollments`

```
id              bigint PK
student_id      bigint FK students    ON DELETE cascade
semester_id     bigint FK semesters   ON DELETE restrict
class_id        bigint FK classes     ON DELETE restrict
status          varchar(20)
                  enum: 'active'
                      | 'transferred_out'
                      | 'dropped_out'
                      | 'graduated'
                      | 'promoted_out'
                      | 'retained_out'
exit_date       date NULL             (filled when status != 'active')
exit_reason     varchar(255) NULL
created_at      timestamp
updated_at      timestamp

UNIQUE (student_id, semester_id)
INDEX  (semester_id, class_id)        -- roster queries
INDEX  (student_id, semester_id)      -- timeline queries
```

`status` values:
- `active` — enrolled during the semester
- `transferred_out` — left to another school mid-semester
- `dropped_out` — quit without transfer mid-semester
- `graduated` — final-grade exit (set during year transition)
- `promoted_out` — finished the semester and was promoted to a higher grade (set during year transition, captures terminal state of the semester)
- `retained_out` — finished the semester but was held back / not promoted (set during year transition)

### Relationship with existing tables

| Table | Role | Change |
|---|---|---|
| `students.class_id` | Denormalized "current" pointer | Kept; auto-synced from active-semester enrollment. Existing controllers/policies untouched. |
| `student_mutations` | Event log of state changes | Kept; mutations continue to record events. Service layer keeps enrollment in sync when a mutation is recorded. |
| `report_cards`, `grades`, `tasks`, `exams`, `attendance` | Already historical (have `class_id` + `semester_id`) | No change. |
| `classes` | Year-bound (`academic_year_id`) | No change. |
| `semesters` | Have `academic_year_id` + `is_active` flag | No change in Phase 1. |

### Source-of-truth rules

| Question | Source |
|---|---|
| "Which class was student X in during semester Y?" | `student_class_enrollments` |
| "Which class is student X in right now?" | `students.class_id` (cached view of active-semester enrollment) |
| "What changed for student X?" | `student_mutations` |

## Section 2: Workflow

### 2.1 Student created

`StudentController::store` flow (additive):
1. Validate + `Student::create(...)` (existing).
2. If `class_id` is set and an active semester exists → create enrollment:
   `(student_id, active_semester_id, class_id, status='active')`.
3. `students.class_id` already reflects current class; no extra sync needed.

If no active semester exists, skip enrollment creation and surface a UI warning.

### 2.2 Student moved between classes mid-semester

Triggered by `StudentController::update` when `class_id` changes:
1. Create `StudentMutation(type=transfer_in/...,from_class_id, to_class_id, date=today)`.
2. **Overwrite** the current-semester enrollment row: update `class_id` to the new class, keep `status='active'`. Audit trail is preserved by the mutation row.
3. Update `students.class_id`.

The unique constraint `(student_id, semester_id)` is intentionally preserved — only one class per student per semester. Rationale: the mid-semester change is logically a correction; the historical fact ("in semester Y the student was finally in class Z") matches what report cards record.

### 2.3 Student exits (transfer / dropout / graduate)

When admin marks a student as transferred/dropped/graduated mid-semester:
1. Create `StudentMutation` row (event log).
2. Update current-semester enrollment: `status = transferred_out|dropped_out|graduated`, `exit_date = mutation.date`, `exit_reason = mutation.reason`.
3. Keep `students.class_id` as the last class (preserves existing scope/policy behavior in controllers that read `students.class_id`). Set `students.status` to the corresponding existing enum value (`graduated` / `transferred` / `dropout`) — student is excluded from active rosters via this status. The active-status scope on controllers already filters these out.
4. Do **not** carry over this student to the next semester.

### 2.4 Semester activation (carry-over trigger)

Triggered when admin flips `Semester.is_active = true` on a previously inactive semester:
1. Find previous semester within the same `academic_year_id` (`semester_number = current - 1`).
2. For each enrollment in that previous semester with `status = 'active'`:
   - Insert `(student_id, new_semester_id, same_class_id, status='active')` into `student_class_enrollments`.
3. Skip enrollments where status != active (student already exited).
4. Show summary: "X carried over, Y skipped".

Idempotency: re-running the carry-over for the same target semester must not duplicate rows. Achieved by the unique constraint + insert-or-skip behavior.

### 2.5 Year transition

`YearTransitionService::executeTransition` (additive after existing class-id update):

For each `StudentMutation` written by the service:
- `type=promotion` or `type=retention` → create enrollment in **Sem Ganjil of target year** at the destination class, `status='active'`. Also update the **source-year terminal semester's enrollment** → `status='promoted_out'` (or `retained_out`).
- `type=graduated` → update source-year terminal-semester enrollment → `status='graduated'`. No new enrollment in target year.
- `type=transfer_out` / `type=dropout` → similar: terminal-state update on source-year enrollment.

### 2.6 Backfill (one-time migration)

For each existing student with `status='active'` and non-null `class_id`:
- If an active semester exists: insert `(student_id, active_semester_id, class_id, status='active')` if not already present.

Idempotent (re-runnable). Old historical data (pre-feature) is not reconstructed — it doesn't exist in the demo DB yet, and there is no reliable source to rebuild it from for production deployments lacking prior mutations/report-cards.

## Section 3: UI Surfaces

### 3.1 Students/Index.vue — semester filter

Add a **Semester** dropdown beside the existing Tahun Ajaran + Kelas filters.

- Default = active semester
- Behavior when a semester is selected:
  - Query students via `student_class_enrollments` joined to `students`, scoped to the selected semester
  - Show class from `enrollment.class`, not `students.class_id`
  - Show all statuses; render with a badge (Aktif / Pindah / Lulus / Keluar)
  - Show exit date when not active

Column layout:
```
Nama       Kelas      Status                     Periode
Nathan     1          ✓ Aktif                    2025/2026 Ganjil
Andi       2          🚪 Pindah (15/10/2025)     2025/2026 Ganjil
Daniel     1          🎓 Lulus (30/06/2026)      2025/2026 Genap
```

### 3.2 Students/Show.vue — "Riwayat Kelas" section

New section listing all enrollments for the student, sorted DESC by `(academic_year.start_date, semester.semester_number)`:

```
2026/2027 Ganjil   Kelas 2     Aktif
2025/2026 Genap    Kelas 1     Selesai (Naik kelas)
2025/2026 Ganjil   Kelas 1     Selesai
```

Each row is clickable (Phase 3 will expand this into a drill-down view of period-specific tasks/grades/attendance). For Phase 1, clicking just expands inline to show class + homeroom teacher + AY.

### 3.3 Semester activation confirmation

When admin toggles `Semester.is_active` from false → true on a semester that doesn't yet have a roster:
1. Modal preview: "Carry-over X siswa dari [previous semester] ke [target semester]? Y siswa di-skip (sudah keluar/lulus)."
2. "Preview details" button → list of (siswa, kelas) being carried, and list of skipped siswa with reasons.
3. Confirm → atomic transaction:
   - Update `Semester.is_active`
   - Insert enrollments
   - Show success toast with counts
4. Cancel → no DB changes.

### 3.4 Student create form

No visible change. `class_id` dropdown stays. Backend creates enrollment for active semester transparently.

### 3.5 Out of scope (Phase 1)

- Tasks/Exams/Grades/Attendance pages already have semester filters and historical data — no UI change needed.
- Schedule pages — deferred (Phase 2).

## Section 4: Migrations, Edge Cases, Risks

### 4.1 Migration files

```
2026_05_14_180000_create_student_class_enrollments_table.php
  -> Creates table per Section 1 schema
  -> MySQL/MariaDB compatible (cast int, no jsonb, FK columns indexed)

2026_05_14_180001_backfill_student_class_enrollments.php
  -> Inserts enrollments for currently-active students
  -> Idempotent (insertOrIgnore on unique key)
```

### 4.2 Controller / service changes

| File | Change |
|---|---|
| `StudentController::store` | After `Student::create`, write enrollment for active semester (if class_id set). |
| `StudentController::update` | When class_id changes, write `StudentMutation` + overwrite current-semester enrollment. |
| `StudentController::index` | When semester filter active, query via enrollment join. |
| `StudentController::show` | Eager-load enrollments + render Riwayat Kelas section. |
| `SemesterController::update` (or equivalent activation action) | On `is_active=true` change, call `EnrollmentCarryOverService::carryOver(prevSemId, newSemId)`. |
| `YearTransitionService::executeTransition` | After existing student promotion logic, write enrollments to target-year Sem Ganjil + close source-year terminal-semester enrollments. |
| **New**: `app/Services/EnrollmentCarryOverService.php` | `previewCarryOver(int $newSemId)` + `executeCarryOver(int $newSemId)` (atomic, idempotent). |
| **New**: `app/Models/StudentClassEnrollment.php` | Eloquent model with `belongsTo` to Student/Class/Semester. |

### 4.3 Edge cases

| Case | Handling |
|---|---|
| No active semester when creating student | Skip enrollment creation; surface warning toast; `students.class_id` still set so the student is visible in current views. |
| Carry-over with no previous active semester (admin activates Sem Ganjil first time) | No carry-over runs; admin manually assigns enrollments by creating/editing students with `class_id`. |
| Admin re-activates an already-rostered semester | Carry-over is idempotent (`insertOrIgnore`); no duplicates. |
| Student has no `class_id` (orphan) | No enrollment row; doesn't appear in semester-filtered list; appears in "Tanpa Kelas" admin view (current behavior). |
| Race condition (concurrent semester activation + student edit) | Wrap activation in DB transaction with `lockForUpdate` on enrollments — same pattern as `YearTransitionService`. |
| Mid-semester transfer overwrites enrollment | Acceptable trade-off: mutation log preserves the change history. If audit-grade roster history is later required, soft-delete + insert-new can be added in Phase 3 (would require relaxing the unique constraint to `(student_id, semester_id, deleted_at)`). |

### 4.4 Risks

| Risk | Mitigation |
|---|---|
| Backfill duplicates if re-run | Unique constraint + `insertOrIgnore` |
| Existing controllers depending on `students.class_id` for authorization (e.g. `TaskController` student scope) | `students.class_id` is preserved as denormalized "current" — auto-synced. No policy/scope refactor in Phase 1. |
| Production carry-over misfire (wrong semester activated) | Modal confirmation with preview + atomic transaction (rollback on partial failure) + log entry |
| Future Phase 2 schedule migration | Phase 1 does not touch `teaching_assignments` or `schedules`; Phase 2 will add `semester_id` to `teaching_assignments` and backfill from current AY rows. |
| Student list query performance with enrollment join | Composite indexes `(semester_id, class_id)` + `(student_id, semester_id)`; paginated. |

## Section 5: Acceptance Criteria

Phase 1 ships when:

1. Migration creates `student_class_enrollments` and successfully backfills active students in dev + production.
2. `StudentController::store` writes an enrollment when active semester exists.
3. `StudentController::update` updates enrollment + writes mutation when class changes.
4. `StudentController::index` accepts a `semester_id` filter and returns historically-correct roster including non-active statuses.
5. `Students/Show.vue` renders a "Riwayat Kelas" section showing all enrollments.
6. `EnrollmentCarryOverService` exists with preview + execute methods, atomic + idempotent.
7. Admin can activate a semester and see the carry-over confirmation modal; confirming creates correct enrollment rows.
8. `YearTransitionService` writes target-year Sem Ganjil enrollments after executing transition.
9. Existing TaskController/ExamController/etc. continue to work (no broken policy checks).
10. MySQL/MariaDB compatible (no jsonb, FK columns indexed, integers cast).

## References

- `app/Services/YearTransitionService.php` — existing pattern for atomic transitions with audit logs
- `app/Models/StudentMutation.php` — event log already capturing promotion/transfer/dropout
- `database/migrations/2026_05_08_000001_create_year_transition_logs_table.php` — schema pattern for audit-grade tables
- MySQL/MariaDB compatibility notes: see `chore/mysql-compat` commits 0b8db30, 43cb0d3, and Student model cast fix (commit pending)
