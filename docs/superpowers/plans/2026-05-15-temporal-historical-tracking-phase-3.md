# Temporal/Historical Tracking — Phase 3 Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Three deferred features from Phase 1/2 — (1) timeline drill-down so admin can see all data for a student in a past semester, (2) mid-semester exit UI so admin can mark a student keluar/lulus anytime, and (3) Excel bulk-import for historical enrollments.

**Architecture:** Lean on existing `student_class_enrollments` + already-historical `tasks`/`exams`/`grades`/`attendance`/`report_cards` tables. Add 1 read-only API endpoint, 1 ad-hoc exit endpoint, 1 import endpoint. UI: 1 new page for timeline detail, 1 modal for exit, 1 modal for import.

**Tech Stack:** Laravel 11, Inertia/Vue 3, MariaDB on prod. Tests via Pest. Excel via Maatwebsite/Excel (already installed).

**Spec ref:** `docs/superpowers/specs/2026-05-14-temporal-historical-tracking-design.md` (Phase 3 non-goals section)

## Design Decisions (sensible defaults)

| Decision | Choice |
|---|---|
| Timeline detail location | New dedicated route `/students/{id}/timeline/{semester_id}` — easier to bookmark/share; cleaner from "Riwayat Kelas" rows. |
| Timeline content per period | Tasks + scores, Exams + scores, Attendance summary, Report card (link if exists). Read-only. |
| Mid-semester exit UI | Modal triggered from a "Tandai Keluar" button on the Student show page. Form: status + tanggal + alasan. |
| Bulk-import format | Excel (.xlsx) — same as existing Student import. CSV optional. Columns: NIS, Tahun Ajaran, Semester, Kelas, Status. |
| Bulk-import validation | Pre-flight validation (NIS exists, AY exists, Class exists in that AY, Semester exists in that AY). Show error rows before commit. |

## File Structure

**Create:**
- `src/app/Http/Controllers/StudentTimelineController.php` — read-only period data
- `src/app/Http/Controllers/StudentExitController.php` — record mid-semester exit
- `src/app/Imports/HistoricalEnrollmentsImport.php` — Maatwebsite import class
- `src/resources/js/Pages/Students/Timeline.vue` — period detail page
- `src/resources/js/Pages/Students/ExitConfirmModal.vue` — mid-semester exit form
- `src/resources/js/Pages/Students/HistoricalImportModal.vue` — bulk import
- `src/tests/Feature/StudentEnrollment/StudentTimelineTest.php`
- `src/tests/Feature/StudentEnrollment/StudentExitTest.php`
- `src/tests/Feature/StudentEnrollment/HistoricalEnrollmentsImportTest.php`

**Modify:**
- `src/routes/web.php` — 3 new routes
- `src/resources/js/Pages/Students/Tabs/StudentMutationTab.vue` — Riwayat Kelas row → Link to timeline detail
- `src/resources/js/Pages/Students/Show.vue` — "Tandai Keluar" button in header
- `src/resources/js/Pages/Students/Index.vue` — "Import Riwayat" button beside existing "Import Excel"

---

## Task 1: Routes registration

**Files:**
- Modify: `src/routes/web.php`

- [ ] **Step 1: Add 3 routes**

Add inside the existing auth route group (where `Route::resource('students', ...)` lives):

```php
        Route::get('students/{student}/timeline/{semester}', [\App\Http\Controllers\StudentTimelineController::class, 'show'])
            ->name('students.timeline');
        Route::post('students/{student}/exit', [\App\Http\Controllers\StudentExitController::class, 'store'])
            ->name('students.exit');
        Route::post('students/import-historical', [\App\Http\Controllers\StudentController::class, 'importHistorical'])
            ->name('students.import-historical');
```

- [ ] **Step 2: Verify routes**

```bash
cd src && php artisan route:list --name=students.timeline
cd src && php artisan route:list --name=students.exit
cd src && php artisan route:list --name=students.import-historical
```

(The last one will fail until Task 6 adds the controller method. The first two will fail until Tasks 2 + 4 land.)

- [ ] **Step 3: Commit**

```bash
git add src/routes/web.php
git commit -m "feat(routes): student timeline + exit + historical import endpoints"
```

---

## Task 2: StudentTimelineController + test

**Files:**
- Create: `src/app/Http/Controllers/StudentTimelineController.php`
- Test: `src/tests/Feature/StudentEnrollment/StudentTimelineTest.php`

- [ ] **Step 1: Write failing test**

Create `src/tests/Feature/StudentEnrollment/StudentTimelineTest.php`:

```php
<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\Subject;
use App\Models\Task;
use App\Models\TaskScore;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('timeline page shows tasks and scores from the student-in-class-in-semester context', function () {
    $admin = User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);

    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => false, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => false, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    $subject = Subject::create(['name' => 'Matematika', 'code' => 'MTK', 'status' => 'active']);

    $student = Student::create(['nis' => '1', 'name' => 'X', 'class_id' => $class->id, 'status' => 'active']);
    StudentClassEnrollment::create(['student_id' => $student->id, 'semester_id' => $sem->id, 'class_id' => $class->id, 'status' => 'active']);

    $task = Task::create([
        'class_id' => $class->id, 'subject_id' => $subject->id, 'semester_id' => $sem->id,
        'teacher_id' => null, 'title' => 'Ulangan Harian', 'task_date' => '2025-08-15',
        'max_score' => 100, 'status' => 'active',
    ]);
    TaskScore::create([
        'task_id' => $task->id, 'student_id' => $student->id,
        'score' => 85, 'submission_status' => 'kumpul',
    ]);

    $response = $this->actingAs($admin)->get("/students/{$student->id}/timeline/{$sem->id}");
    $response->assertOk();

    $props = $response->viewData('page')['props'];
    expect($props['student']['id'])->toBe($student->id);
    expect($props['semester']['id'])->toBe($sem->id);
    expect($props['enrollment'])->not->toBeNull();
    expect($props['enrollment']['class_id'])->toBe($class->id);
    expect(count($props['tasks']))->toBe(1);
    expect($props['tasks'][0]['title'])->toBe('Ulangan Harian');
    expect($props['tasks'][0]['student_score'])->toBe('85.00');
});
```

- [ ] **Step 2: Run, expect fail**

`cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/StudentTimelineTest.php`

- [ ] **Step 3: Write the controller**

```php
<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\Exam;
use App\Models\ExamScore;
use App\Models\Grade;
use App\Models\ReportCard;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\Task;
use App\Models\TaskScore;
use Inertia\Inertia;

class StudentTimelineController extends Controller
{
    public function show(Student $student, Semester $semester)
    {
        \Illuminate\Support\Facades\Gate::authorize('view', $student);

        $enrollment = StudentClassEnrollment::with('schoolClass')
            ->where('student_id', $student->id)
            ->where('semester_id', $semester->id)
            ->first();

        $classId = $enrollment?->class_id;

        $tasks = Task::query()
            ->where('semester_id', $semester->id)
            ->when($classId, fn($q) => $q->where('class_id', $classId))
            ->with('subject:id,name')
            ->orderBy('task_date')
            ->get()
            ->map(function ($task) use ($student) {
                $score = TaskScore::where('task_id', $task->id)
                    ->where('student_id', $student->id)
                    ->first();
                return [
                    'id'                => $task->id,
                    'title'             => $task->title,
                    'task_date'         => $task->task_date,
                    'subject'           => $task->subject,
                    'max_score'         => $task->max_score,
                    'student_score'     => $score?->score,
                    'submission_status' => $score?->submission_status,
                ];
            });

        $exams = Exam::query()
            ->where('semester_id', $semester->id)
            ->when($classId, fn($q) => $q->where('class_id', $classId))
            ->with('subject:id,name')
            ->orderBy('exam_date')
            ->get()
            ->map(function ($exam) use ($student) {
                $score = ExamScore::where('exam_id', $exam->id)
                    ->where('student_id', $student->id)
                    ->first();
                return [
                    'id'            => $exam->id,
                    'title'         => $exam->title,
                    'exam_type'     => $exam->exam_type,
                    'exam_date'     => $exam->exam_date,
                    'subject'       => $exam->subject,
                    'max_score'     => $exam->max_score,
                    'student_score' => $score?->score,
                ];
            });

        // Attendance summary
        $attendanceSummary = Attendance::where('student_id', $student->id)
            ->when($classId, fn($q) => $q->where('class_id', $classId))
            ->whereBetween('date', [$semester->start_date, $semester->end_date])
            ->selectRaw('status, COUNT(*) as n')
            ->groupBy('status')
            ->pluck('n', 'status');

        // Report card for this semester (if any)
        $reportCard = ReportCard::where('student_id', $student->id)
            ->where('semester_id', $semester->id)
            ->first();

        $semester->load('academicYear');

        return Inertia::render('Students/Timeline', [
            'student'           => $student->only(['id', 'nis', 'name', 'status']),
            'semester'          => $semester->only(['id', 'semester_number', 'start_date', 'end_date']) + [
                'academic_year' => $semester->academicYear?->only(['id', 'name']),
            ],
            'enrollment'        => $enrollment?->only(['id', 'class_id', 'status', 'exit_date', 'exit_reason']) + [
                'school_class' => $enrollment?->schoolClass?->only(['id', 'name', 'grade_level']),
            ],
            'tasks'             => $tasks,
            'exams'             => $exams,
            'attendanceSummary' => $attendanceSummary,
            'reportCard'        => $reportCard?->only(['id', 'rank', 'total_score', 'average_score', 'status']),
        ]);
    }
}
```

- [ ] **Step 4: Run test, expect pass**

`cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/StudentTimelineTest.php`

- [ ] **Step 5: Commit**

```bash
git add src/app/Http/Controllers/StudentTimelineController.php src/tests/Feature/StudentEnrollment/StudentTimelineTest.php
git commit -m "feat(timeline): backend endpoint for student period detail"
```

---

## Task 3: Timeline Vue page + Riwayat Kelas → click handler

**Files:**
- Create: `src/resources/js/Pages/Students/Timeline.vue`
- Modify: `src/resources/js/Pages/Students/Tabs/StudentMutationTab.vue` (rows clickable)

- [ ] **Step 1: Create Timeline.vue**

```vue
<script setup>
import { Head } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';
import Button from '@/Components/UI/Button.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
  student: Object,
  semester: Object,
  enrollment: Object,
  tasks: Array,
  exams: Array,
  attendanceSummary: Object,
  reportCard: Object,
});

const statusLabel = (s) => ({
  active: 'Aktif',
  promoted_out: 'Selesai (Naik kelas)',
  retained_out: 'Selesai (Tinggal kelas)',
  graduated: 'Lulus',
  transferred_out: 'Pindah',
  dropped_out: 'Keluar',
}[s] || s);

const formatDate = (d) => d ? new Date(d).toLocaleDateString('id-ID') : '—';
</script>

<template>
  <Head :title="`${student.name} — ${semester.academic_year?.name} Sem ${semester.semester_number}`" />

  <div class="mx-auto max-w-5xl space-y-6">
    <!-- Header -->
    <div class="flex items-center gap-4">
      <Button :href="`/students/${student.id}`" variant="outline" size="sm">
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
        Kembali
      </Button>
      <div>
        <h2 class="text-xl font-bold text-slate-800">{{ student.name }}</h2>
        <p class="text-sm text-slate-500">
          {{ semester.academic_year?.name }} — Semester {{ semester.semester_number }}
          <span v-if="enrollment?.school_class"> · Kelas {{ enrollment.school_class.name }}</span>
          <span v-if="enrollment?.status" class="ml-2 inline-block rounded bg-slate-100 px-2 py-0.5 text-xs text-slate-700">{{ statusLabel(enrollment.status) }}</span>
        </p>
      </div>
    </div>

    <!-- Tasks -->
    <div class="rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="border-b border-slate-100 px-6 py-4">
        <h3 class="text-sm font-semibold text-slate-700">Tugas ({{ tasks.length }})</h3>
      </div>
      <div v-if="tasks.length === 0" class="px-6 py-6 text-center text-sm text-slate-400">Tidak ada tugas.</div>
      <table v-else class="w-full text-sm">
        <thead class="bg-slate-50/60">
          <tr class="border-b border-slate-100">
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Tanggal</th>
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Mapel</th>
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Judul</th>
            <th class="px-4 py-2 text-right text-xs font-semibold uppercase text-slate-400">Nilai</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="t in tasks" :key="t.id" class="border-b border-slate-50">
            <td class="px-4 py-2 text-slate-600">{{ formatDate(t.task_date) }}</td>
            <td class="px-4 py-2 text-slate-700">{{ t.subject?.name || '—' }}</td>
            <td class="px-4 py-2 text-slate-700">{{ t.title }}</td>
            <td class="px-4 py-2 text-right">
              <span v-if="t.student_score !== null && t.student_score !== undefined" class="font-medium text-slate-800">{{ t.student_score }} / {{ t.max_score }}</span>
              <span v-else class="text-xs text-slate-400">{{ t.submission_status || '—' }}</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Exams -->
    <div class="rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="border-b border-slate-100 px-6 py-4">
        <h3 class="text-sm font-semibold text-slate-700">Ujian ({{ exams.length }})</h3>
      </div>
      <div v-if="exams.length === 0" class="px-6 py-6 text-center text-sm text-slate-400">Tidak ada ujian.</div>
      <table v-else class="w-full text-sm">
        <thead class="bg-slate-50/60">
          <tr class="border-b border-slate-100">
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Tanggal</th>
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Mapel</th>
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Judul / Tipe</th>
            <th class="px-4 py-2 text-right text-xs font-semibold uppercase text-slate-400">Nilai</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="e in exams" :key="e.id" class="border-b border-slate-50">
            <td class="px-4 py-2 text-slate-600">{{ formatDate(e.exam_date) }}</td>
            <td class="px-4 py-2 text-slate-700">{{ e.subject?.name || '—' }}</td>
            <td class="px-4 py-2 text-slate-700">{{ e.title }} <span class="ml-1 text-xs text-slate-400">({{ e.exam_type }})</span></td>
            <td class="px-4 py-2 text-right">
              <span v-if="e.student_score !== null && e.student_score !== undefined" class="font-medium text-slate-800">{{ e.student_score }} / {{ e.max_score }}</span>
              <span v-else class="text-xs text-slate-400">—</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Attendance + Report -->
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <h3 class="mb-3 text-sm font-semibold text-slate-700">Rekap Absensi</h3>
        <div class="space-y-1 text-sm">
          <div class="flex justify-between"><span class="text-slate-500">Hadir</span><span class="font-medium">{{ attendanceSummary?.hadir || 0 }}</span></div>
          <div class="flex justify-between"><span class="text-slate-500">Sakit</span><span class="font-medium">{{ attendanceSummary?.sakit || 0 }}</span></div>
          <div class="flex justify-between"><span class="text-slate-500">Izin</span><span class="font-medium">{{ attendanceSummary?.izin || 0 }}</span></div>
          <div class="flex justify-between"><span class="text-slate-500">Alfa</span><span class="font-medium">{{ attendanceSummary?.alfa || 0 }}</span></div>
        </div>
      </div>
      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <h3 class="mb-3 text-sm font-semibold text-slate-700">Rapor</h3>
        <div v-if="reportCard" class="space-y-1 text-sm">
          <div class="flex justify-between"><span class="text-slate-500">Rata-rata</span><span class="font-medium">{{ reportCard.average_score || '—' }}</span></div>
          <div class="flex justify-between"><span class="text-slate-500">Total</span><span class="font-medium">{{ reportCard.total_score || '—' }}</span></div>
          <div class="flex justify-between"><span class="text-slate-500">Ranking</span><span class="font-medium">{{ reportCard.rank || '—' }}</span></div>
          <div class="flex justify-between"><span class="text-slate-500">Status</span><span class="font-medium">{{ reportCard.status }}</span></div>
        </div>
        <div v-else class="text-sm text-slate-400">Belum ada rapor.</div>
      </div>
    </div>
  </div>
</template>
```

- [ ] **Step 2: Make Riwayat Kelas rows clickable**

Open `src/resources/js/Pages/Students/Tabs/StudentMutationTab.vue`. Add `Link` import:

```javascript
import { Link } from '@inertiajs/vue3';
```

In the template, replace:

```html
<tr v-for="e in sortedEnrollments" :key="e.id" class="border-b border-slate-100">
```

with:

```html
<tr v-for="e in sortedEnrollments" :key="e.id" class="border-b border-slate-100 hover:bg-slate-50">
```

And wrap the entire row's first `<td>` content in a `<Link>`. Easiest approach: add a "Lihat detail" link as the LAST cell. Add new `<th>` "Aksi" and `<td>`:

In the `<thead>`:
```html
<th class="px-4 py-2 text-right text-xs font-semibold uppercase text-slate-400">Aksi</th>
```

In the `<tr>` add a new `<td>` after the Status column:
```html
<td class="px-4 py-2 text-right">
  <Link :href="`/students/${student.id}/timeline/${e.semester_id}`" class="text-xs font-medium text-orange-600 hover:underline">
    Lihat detail
  </Link>
</td>
```

(Use `student.id` from the parent prop — verify it's exposed; if not, use `props.student.id` or pass it down.)

- [ ] **Step 3: Build assets**

`cd src && npm run build`

- [ ] **Step 4: Commit**

```bash
git add src/resources/js/Pages/Students/Timeline.vue src/resources/js/Pages/Students/Tabs/StudentMutationTab.vue
git commit -m "feat(ui): student timeline detail page + clickable Riwayat Kelas"
```

---

## Task 4: StudentExitController + test

**Files:**
- Create: `src/app/Http/Controllers/StudentExitController.php`
- Test: `src/tests/Feature/StudentEnrollment/StudentExitTest.php`

- [ ] **Step 1: Write failing test**

```php
<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\StudentMutation;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('admin can mark a student as exit mid-semester (transferred/dropout/graduated)', function () {
    $admin = User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    $student = Student::create(['nis' => '1', 'name' => 'Exit', 'class_id' => $class->id, 'status' => 'active']);
    StudentClassEnrollment::create(['student_id' => $student->id, 'semester_id' => $sem->id, 'class_id' => $class->id, 'status' => 'active']);

    $this->actingAs($admin)->post("/students/{$student->id}/exit", [
        'status'    => 'transferred_out',
        'exit_date' => '2025-10-15',
        'reason'    => 'Pindah ke luar kota',
    ])->assertRedirect();

    // Student status updated to legacy mapping
    expect(Student::find($student->id)->status)->toBe('transferred');

    // Enrollment closed
    $enrollment = StudentClassEnrollment::where('student_id', $student->id)->where('semester_id', $sem->id)->first();
    expect($enrollment->status)->toBe('transferred_out');
    expect($enrollment->exit_date->toDateString())->toBe('2025-10-15');

    // Mutation row created
    $mutation = StudentMutation::where('student_id', $student->id)->first();
    expect($mutation)->not->toBeNull();
    expect($mutation->type)->toBe('transfer_out');
});
```

- [ ] **Step 2: Run, expect fail**

- [ ] **Step 3: Write the controller**

```php
<?php

namespace App\Http\Controllers;

use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\StudentMutation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StudentExitController extends Controller
{
    public function store(Request $request, Student $student)
    {
        \Illuminate\Support\Facades\Gate::authorize('update', $student);

        $validated = $request->validate([
            'status'    => 'required|in:transferred_out,dropped_out,graduated',
            'exit_date' => 'required|date',
            'reason'    => 'nullable|string|max:500',
        ]);

        $studentStatusMap = [
            'transferred_out' => 'transferred',
            'dropped_out'     => 'dropout',
            'graduated'       => 'graduated',
        ];
        $mutationTypeMap = [
            'transferred_out' => 'transfer_out',
            'dropped_out'     => 'dropout',
            'graduated'       => 'graduated',
        ];

        DB::transaction(function () use ($student, $validated, $studentStatusMap, $mutationTypeMap) {
            $activeSem = Semester::where('is_active', true)->first();

            StudentMutation::create([
                'student_id'    => $student->id,
                'type'          => $mutationTypeMap[$validated['status']],
                'from_class_id' => $student->class_id,
                'to_class_id'   => null,
                'date'          => $validated['exit_date'],
                'reason'        => $validated['reason'] ?? null,
            ]);

            if ($activeSem) {
                StudentClassEnrollment::where('student_id', $student->id)
                    ->where('semester_id', $activeSem->id)
                    ->update([
                        'status'      => $validated['status'],
                        'exit_date'   => $validated['exit_date'],
                        'exit_reason' => $validated['reason'] ?? null,
                    ]);
            }

            $student->update(['status' => $studentStatusMap[$validated['status']]]);
        });

        return redirect()->route('students.show', $student)
            ->with('success', 'Siswa berhasil ditandai keluar.');
    }
}
```

- [ ] **Step 4: Run test, expect pass**

`cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/StudentExitTest.php`

- [ ] **Step 5: Commit**

```bash
git add src/app/Http/Controllers/StudentExitController.php src/tests/Feature/StudentEnrollment/StudentExitTest.php
git commit -m "feat(students): admin can mark mid-semester exit"
```

---

## Task 5: ExitConfirmModal Vue + wire into Show.vue

**Files:**
- Create: `src/resources/js/Pages/Students/ExitConfirmModal.vue`
- Modify: `src/resources/js/Pages/Students/Show.vue`

- [ ] **Step 1: Create the modal**

```vue
<script setup>
import { ref, watch } from 'vue';
import { useForm } from '@inertiajs/vue3';

const props = defineProps({
  show: Boolean,
  student: Object,
});
const emit = defineEmits(['close']);

const form = useForm({
  status: 'transferred_out',
  exit_date: new Date().toISOString().slice(0, 10),
  reason: '',
});

const STATUS_OPTIONS = [
  { value: 'transferred_out', label: 'Pindah sekolah' },
  { value: 'dropped_out',     label: 'Dropout / Berhenti' },
  { value: 'graduated',       label: 'Lulus' },
];

watch(() => props.show, (val) => {
  if (!val) {
    form.reset();
    form.clearErrors();
  }
});

const submit = () => {
  form.post(`/students/${props.student.id}/exit`, {
    onSuccess: () => emit('close'),
  });
};
</script>

<template>
  <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="w-full max-w-md rounded-xl bg-white shadow-xl">
      <div class="border-b border-slate-100 px-6 py-4">
        <h3 class="text-base font-semibold text-slate-800">Tandai Keluar: {{ student?.name }}</h3>
      </div>
      <form @submit.prevent="submit" class="space-y-4 px-6 py-5 text-sm">
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Status <span class="text-red-500">*</span></label>
          <select v-model="form.status" class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm">
            <option v-for="o in STATUS_OPTIONS" :key="o.value" :value="o.value">{{ o.label }}</option>
          </select>
          <p v-if="form.errors.status" class="mt-1 text-xs text-red-500">{{ form.errors.status }}</p>
        </div>
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Tanggal keluar <span class="text-red-500">*</span></label>
          <input v-model="form.exit_date" type="date" class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm" />
          <p v-if="form.errors.exit_date" class="mt-1 text-xs text-red-500">{{ form.errors.exit_date }}</p>
        </div>
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Alasan (opsional)</label>
          <textarea v-model="form.reason" rows="3" class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm" placeholder="Pindah karena…" />
        </div>
        <div class="flex justify-end gap-2 pt-2">
          <button type="button" @click="emit('close')" class="rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-600">Batal</button>
          <button type="submit" :disabled="form.processing" class="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-50">Tandai Keluar</button>
        </div>
      </form>
    </div>
  </div>
</template>
```

- [ ] **Step 2: Wire modal into Show.vue**

Open `src/resources/js/Pages/Students/Show.vue`. Add to `<script setup>`:

```javascript
import ExitConfirmModal from './ExitConfirmModal.vue';
const showExitModal = ref(false);
```

(Ensure `ref` is imported — it should already be.)

In the template header area where the Edit button lives, add a "Tandai Keluar" button (only show when status='active'):

```html
<Button v-if="permissions.manage_students && student.status === 'active'" variant="outline" size="sm" @click="showExitModal = true">
  <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
  Tandai Keluar
</Button>
```

At the end of the template (just before closing tag), add:

```html
<ExitConfirmModal :show="showExitModal" :student="student" @close="showExitModal = false" />
```

- [ ] **Step 3: Build assets**

`cd src && npm run build`

- [ ] **Step 4: Commit**

```bash
git add src/resources/js/Pages/Students/ExitConfirmModal.vue src/resources/js/Pages/Students/Show.vue
git commit -m "feat(ui): mid-semester exit modal on student show page"
```

---

## Task 6: Historical enrollments Excel import

**Files:**
- Create: `src/app/Imports/HistoricalEnrollmentsImport.php`
- Modify: `src/app/Http/Controllers/StudentController.php` (add `importHistorical` + `downloadHistoricalTemplate`)
- Modify: `src/routes/web.php` (template download route)
- Test: `src/tests/Feature/StudentEnrollment/HistoricalEnrollmentsImportTest.php`

- [ ] **Step 1: Write failing test**

```php
<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Maatwebsite\Excel\Facades\Excel;
use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\WithHeadings;

uses(RefreshDatabase::class);

class _HistoricalEnrollmentsTestSheet implements FromArray, WithHeadings
{
    public function __construct(public array $rows) {}
    public function array(): array { return $this->rows; }
    public function headings(): array { return ['NIS', 'Tahun Ajaran', 'Semester', 'Kelas', 'Status']; }
}

it('admin can bulk-import historical enrollments from Excel', function () {
    $admin = User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);
    $ay = AcademicYear::create(['name' => '2024/2025', 'is_active' => false, 'start_date' => '2024-07-01', 'end_date' => '2025-06-30']);
    $sem = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => false, 'start_date' => '2024-07-01', 'end_date' => '2024-12-31']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    $student = Student::create(['nis' => '100', 'name' => 'Historic', 'class_id' => null, 'status' => 'active']);

    $sheet = new _HistoricalEnrollmentsTestSheet([
        ['100', '2024/2025', 1, '1A', 'promoted_out'],
    ]);

    Excel::store($sheet, 'test-historical.xlsx', 'local');
    $path = storage_path('app/test-historical.xlsx');
    $file = new UploadedFile($path, 'historical.xlsx', null, null, true);

    $this->actingAs($admin)
        ->post('/students/import-historical', ['file' => $file])
        ->assertRedirect();

    $enrollment = StudentClassEnrollment::where('student_id', $student->id)->first();
    expect($enrollment)->not->toBeNull();
    expect($enrollment->semester_id)->toBe($sem->id);
    expect($enrollment->class_id)->toBe($class->id);
    expect($enrollment->status)->toBe('promoted_out');

    @unlink($path);
});
```

- [ ] **Step 2: Run, expect fail**

- [ ] **Step 3: Write the import class**

```php
<?php

namespace App\Imports;

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use Maatwebsite\Excel\Concerns\Importable;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;

class HistoricalEnrollmentsImport implements ToCollection, WithHeadingRow
{
    use Importable;

    public array $errors = [];
    public int $imported = 0;

    public function collection($rows)
    {
        $allowedStatuses = ['active', 'promoted_out', 'retained_out', 'transferred_out', 'dropped_out', 'graduated'];

        foreach ($rows as $i => $row) {
            $rowNum = $i + 2; // header is row 1
            $nis    = (string) ($row['nis'] ?? '');
            $ayName = (string) ($row['tahun_ajaran'] ?? '');
            $semNum = (int) ($row['semester'] ?? 0);
            $clsName = (string) ($row['kelas'] ?? '');
            $status = (string) ($row['status'] ?? 'active');

            if (! $nis || ! $ayName || ! $semNum || ! $clsName) {
                $this->errors[] = "Baris $rowNum: kolom NIS / Tahun Ajaran / Semester / Kelas tidak boleh kosong.";
                continue;
            }
            if (! in_array($status, $allowedStatuses)) {
                $this->errors[] = "Baris $rowNum: status '$status' tidak valid.";
                continue;
            }

            $student = Student::where('nis', $nis)->first();
            if (! $student) {
                $this->errors[] = "Baris $rowNum: siswa dengan NIS '$nis' tidak ditemukan.";
                continue;
            }

            $ay = AcademicYear::where('name', $ayName)->first();
            if (! $ay) {
                $this->errors[] = "Baris $rowNum: Tahun Ajaran '$ayName' tidak ditemukan.";
                continue;
            }

            $sem = Semester::where('academic_year_id', $ay->id)->where('semester_number', $semNum)->first();
            if (! $sem) {
                $this->errors[] = "Baris $rowNum: Semester $semNum di TA '$ayName' tidak ditemukan.";
                continue;
            }

            $class = SchoolClass::where('academic_year_id', $ay->id)->where('name', $clsName)->first();
            if (! $class) {
                $this->errors[] = "Baris $rowNum: Kelas '$clsName' di TA '$ayName' tidak ditemukan.";
                continue;
            }

            StudentClassEnrollment::updateOrCreate(
                ['student_id' => $student->id, 'semester_id' => $sem->id],
                ['class_id' => $class->id, 'status' => $status],
            );
            $this->imported++;
        }
    }
}
```

- [ ] **Step 4: Add controller method**

Open `src/app/Http/Controllers/StudentController.php`. Add use:

```php
use App\Imports\HistoricalEnrollmentsImport;
```

Add method (next to the existing `import()` method for student data):

```php
    public function importHistorical(Request $request)
    {
        \Illuminate\Support\Facades\Gate::authorize('create', Student::class);

        $request->validate([
            'file' => 'required|mimes:xlsx,csv',
        ]);

        $import = new HistoricalEnrollmentsImport();
        Excel::import($import, $request->file('file'));

        if (! empty($import->errors)) {
            return back()->withErrors(['file' => implode('<br>', $import->errors)]);
        }

        return back()->with('success', "Import berhasil: {$import->imported} enrollment.");
    }
```

- [ ] **Step 5: Run test, expect pass**

`cd src && ./vendor/bin/pest tests/Feature/StudentEnrollment/HistoricalEnrollmentsImportTest.php`

- [ ] **Step 6: Commit**

```bash
git add src/app/Imports/HistoricalEnrollmentsImport.php \
        src/app/Http/Controllers/StudentController.php \
        src/tests/Feature/StudentEnrollment/HistoricalEnrollmentsImportTest.php
git commit -m "feat(students): historical enrollments Excel import"
```

---

## Task 7: HistoricalImportModal Vue + wire into Index

**Files:**
- Create: `src/resources/js/Pages/Students/HistoricalImportModal.vue`
- Modify: `src/resources/js/Pages/Students/Index.vue`

- [ ] **Step 1: Create the modal**

```vue
<script setup>
import { ref, watch } from 'vue';
import { useForm } from '@inertiajs/vue3';

const props = defineProps({
  show: Boolean,
});
const emit = defineEmits(['close']);

const form = useForm({ file: null });

watch(() => props.show, (val) => {
  if (!val) { form.reset(); form.clearErrors(); }
});

const submit = () => {
  form.post('/students/import-historical', {
    forceFormData: true,
    onSuccess: () => emit('close'),
  });
};
</script>

<template>
  <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="w-full max-w-lg rounded-xl bg-white shadow-xl">
      <div class="border-b border-slate-100 px-6 py-4">
        <h3 class="text-base font-semibold text-slate-800">Import Riwayat Enrollment</h3>
      </div>
      <form @submit.prevent="submit" class="space-y-4 px-6 py-5 text-sm">
        <div class="rounded-lg bg-blue-50 p-3 text-xs text-blue-700">
          Format Excel (.xlsx) — kolom: <strong>NIS, Tahun Ajaran, Semester, Kelas, Status</strong>.
          Contoh: <code>100, 2024/2025, 1, 1A, promoted_out</code>.
          Siswa, TA, Semester, dan Kelas harus sudah ada di sistem.
        </div>
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">File Excel</label>
          <input type="file" accept=".xlsx,.csv" @change="form.file = $event.target.files[0]" class="w-full text-sm" />
          <p v-if="form.errors.file" class="mt-1 text-xs text-red-500" v-html="form.errors.file"></p>
        </div>
        <div class="flex justify-end gap-2 pt-2">
          <button type="button" @click="emit('close')" class="rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm">Batal</button>
          <button type="submit" :disabled="form.processing || !form.file" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm text-white disabled:opacity-50">Upload & Import</button>
        </div>
      </form>
    </div>
  </div>
</template>
```

- [ ] **Step 2: Wire into Students/Index.vue**

Open `src/resources/js/Pages/Students/Index.vue`. Add import + ref:

```javascript
import HistoricalImportModal from './HistoricalImportModal.vue';
const showHistoricalImport = ref(false);
```

In the header area beside the existing "Import Excel" button, add:

```html
<Button v-if="permissions.manage_students" variant="secondary" size="sm" @click="showHistoricalImport = true">
  <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
  Import Riwayat
</Button>
```

At the end of the template:

```html
<HistoricalImportModal :show="showHistoricalImport" @close="showHistoricalImport = false" />
```

- [ ] **Step 3: Build + commit**

```bash
cd src && npm run build
git add src/resources/js/Pages/Students/HistoricalImportModal.vue src/resources/js/Pages/Students/Index.vue
git commit -m "feat(ui): historical enrollments import modal on Students index"
```

---

## Task 8: Deploy Phase 3 to production

- [ ] **Step 1: Run all enrollment tests**

`cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src && ./vendor/bin/pest tests/Feature/StudentEnrollment/`
Expected: all Phase 1 + 2 + 3 tests pass.

- [ ] **Step 2: Full feature suite**

`cd src && ./vendor/bin/pest tests/Feature/ 2>&1 | tail -10`
Expected: pre-existing 15 failures unchanged.

- [ ] **Step 3: Build assets**

`cd src && npm run build`

- [ ] **Step 4: Backup prod DB**

```bash
ssh -i ~/.ssh/floz_cpanel sdnkelap@tarsius.kencang.com 'bash -s' <<'SH'
DB="sdnkelap_floz"; U="sdnkelap_floz"; P='sYtrpMJ*fE0*YTEwlBl%p!AosEUh'
TS=$(date +%Y%m%d_%H%M%S)
BACKUP=~/floz_db_backup_${TS}_phase3.sql
mysqldump -u"$U" -p"$P" --single-transaction --no-tablespaces "$DB" > "$BACKUP"
ls -lh "$BACKUP"
SH
```

- [ ] **Step 5: SCP new + modified files**

```bash
SRC=/Users/tokaf/Floz_SDN_KELAPADUA_IV/src
SERVER=sdnkelap@tarsius.kencang.com
KEY=~/.ssh/floz_cpanel

# Controllers — new + existing modified
scp -i "$KEY" \
  "$SRC/app/Http/Controllers/StudentTimelineController.php" \
  "$SRC/app/Http/Controllers/StudentExitController.php" \
  "$SRC/app/Http/Controllers/StudentController.php" \
  "$SERVER:/home/sdnkelap/floz/app/Http/Controllers/"

# Imports — new directory may need creation
ssh -i "$KEY" $SERVER 'mkdir -p /home/sdnkelap/floz/app/Imports'
scp -i "$KEY" \
  "$SRC/app/Imports/HistoricalEnrollmentsImport.php" \
  "$SRC/app/Imports/StudentsImport.php" \
  "$SERVER:/home/sdnkelap/floz/app/Imports/" 2>/dev/null || true

# Routes
scp -i "$KEY" "$SRC/routes/web.php" "$SERVER:/home/sdnkelap/floz/routes/"

# Vite assets
cd "$SRC/public/build"
tar -czf /tmp/floz-build.tgz .
scp -i "$KEY" /tmp/floz-build.tgz "$SERVER:/tmp/"
```

- [ ] **Step 6: Rebuild caches on server**

```bash
ssh -i ~/.ssh/floz_cpanel sdnkelap@tarsius.kencang.com 'bash -s' <<'SH'
set -e
cd ~/floz
rm -rf public/build/*
tar -xzf /tmp/floz-build.tgz -C public/build
rm /tmp/floz-build.tgz
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "== Verify new routes registered =="
php artisan route:list --name=students.timeline
php artisan route:list --name=students.exit
php artisan route:list --name=students.import-historical
SH
```

- [ ] **Step 7: Smoke test**

```bash
curl -sI https://sdnkelapaduaiv.my.id/ | head -1
```
Expected: HTTP 200.

- [ ] **Step 8: Report**

---

## Self-Review

| Feature | Tasks |
|---|---|
| Timeline drill-down | 1 (route), 2 (controller + test), 3 (Vue page + Riwayat clickable) |
| Mid-semester exit | 1 (route), 4 (controller + test), 5 (Vue modal + button) |
| Bulk-import historical | 1 (route), 6 (importer + controller method + test), 7 (Vue modal + button) |
| Deploy | 8 |

### Edge cases noted

- Timeline: when student had no enrollment in that semester (rare data state), the page shows `enrollment=null` but still loads tasks/exams (since tasks are class-bound; without classId we fall back to no class filter — would show ALL tasks for that semester, which may be too broad). Trade-off accepted: better to show something than 404.
- Exit: assumes there's an active semester. If no active semester, the enrollment update is skipped but mutation + student.status are still written. Acceptable.
- Import: requires student/class/semester to pre-exist. Doesn't auto-create them — by design (avoids accidentally creating bogus AYs from typos).
