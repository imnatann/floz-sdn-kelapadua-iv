# Next Phase Features — FLOZ LMS

Items deferred from keluhan triage (2026-05-09). Not implemented; need design + sprint planning.

---

## #2 & #3 — Ulangan Harian Bisa Lebih dari 1 (UH Multiple)

**Current behaviour:** One Ulangan Harian score averaged into `daily_test_avg` alongside Task scores.
**Requested:** Multiple UH per semester, each tracked by name; separate from Tugas.

**Concrete plan:**
- UH already stored as `exam_type = 'ulangan_harian'` in `exams` table — multiple exams already possible.
- The UI issue: `Exams/ClassIndex.vue` needs a cleaner view separating UH vs UTS/UAS.
- `ReportCardService::calculateSubjectGrade` already averages all UH scores → correct.
- Main gap: teacher UI for creating/listing UH exams is buried in Exams section with no UH-specific flow.
- **Fix:** Add a "Ulangan Harian" shortcut tab in the class course view, pre-filling `exam_type=ulangan_harian`. ~M effort.

---

## #4 — Guru Bisa Lihat Detail Nilai Siswa di Mata Pelajaran Dia

**Current behaviour:** Teacher dashboard shows aggregate stats. No per-student grade drill-down scoped to teacher's subjects.
**Requested:** Teacher sees per-student breakdown (task scores + UH scores + UTS + UAS) for their assigned subjects.

**Concrete plan:**
- Add `TeacherGradeDetailController::show(TeachingAssignment $ta, Student $student)`.
- Policy: teacher must own the TA.
- View: show `task_scores` (by task name), `exam_scores` (by exam name/type), computed `final_score`.
- Route: `GET /teaching-assignments/{ta}/students/{student}/grades`.
- Frontend: link from `Courses/Show.vue` student roster row → new page.
- ~M effort (2-3 hours).

---

## #7 — Input Nilai Guru: Per-Student Detail, Connected to Task Name

**Current behaviour:** `Grades/BatchInput` lets admin bulk-enter `daily_test_avg/mid_test/final_test` but these get overwritten by `ReportCardService::generate()`. Teacher has no meaningful grade input UI.
**Requested:** Per-student editable score list showing each task name and each UH name, editable inline, connected to the actual task/exam records.

**Concrete plan:**
- This requires replacing the batch grade input with a task/exam-based grade entry.
- For tasks: edit `TaskScore` records directly (already exists via `/tasks/{task}/scores`).
- For UH exams: edit `ExamScore` records directly (already exists via `/exams/{exam}/scores`).
- The "per-student view" would aggregate these from the task/exam tables in real time.
- Remove `Grades/BatchInput` from teacher-facing UI (keep for admin emergency overrides).
- ~L effort (major redesign of grade input workflow).

---

## #11 — Mapel-Guru Linkage: Satu Mapel Satu Guru Per Kelas (No Checkbox)

**Current behaviour:** Subjects are school-wide entities. Teacher assignment to class+subject is via `TeachingAssignment` (already 1:1 per class per subject per AY). The UI checkbox mentioned probably refers to a planned but unbuilt "assign subject to class" screen.
**Requested:** From the subject edit page, admin picks one specific teacher per class (not a generic checkbox).

**Concrete plan:**
- This is actually already supported by the data model (`TeachingAssignment` = subject + class + teacher + AY).
- The gap is purely UI: Subject edit page (`Subjects/Form.vue`) has no TA management.
- Option A: Add a "Pengampu per Kelas" section inside Subject edit → embedded TA CRUD.
- Option B: Keep TA management separate but add a deep-link from Subject show to TA filtered by subject.
- Option A is cleaner UX but requires architectural work on the Subject edit page.
- ~L effort (involves schema thinking: Subject vs TA boundary, and whether to allow subject-without-TA).

---

*Last updated: 2026-05-09 by triage agent.*
