<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\Subject;
use App\Models\Task;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

function makeStudentTaskHistoryContext(): array
{
    $user = User::factory()->student()->create(['email' => 'layen-tasks@example.test']);

    $previousAy = AcademicYear::create([
        'name' => '2026/2027',
        'is_active' => false,
        'start_date' => '2026-07-01',
        'end_date' => '2027-06-30',
    ]);
    $previousSemester = Semester::create([
        'academic_year_id' => $previousAy->id,
        'semester_number' => 2,
        'is_active' => false,
        'start_date' => '2027-01-01',
        'end_date' => '2027-06-30',
    ]);
    $previousClass = SchoolClass::create([
        'name' => 'Kelas 1',
        'grade_level' => 1,
        'academic_year_id' => $previousAy->id,
        'status' => 'active',
    ]);

    $currentAy = AcademicYear::create([
        'name' => '2027/2028',
        'is_active' => true,
        'start_date' => '2027-07-01',
        'end_date' => '2028-06-30',
    ]);
    $currentSemester = Semester::create([
        'academic_year_id' => $currentAy->id,
        'semester_number' => 1,
        'is_active' => true,
        'start_date' => '2027-07-01',
        'end_date' => '2027-12-31',
    ]);
    $currentClass = SchoolClass::create([
        'name' => 'Kelas 2',
        'grade_level' => 2,
        'academic_year_id' => $currentAy->id,
        'status' => 'active',
    ]);

    $student = Student::create([
        'nis' => '777',
        'name' => 'Layen',
        'email' => $user->email,
        'class_id' => $currentClass->id,
        'status' => 'active',
    ]);

    StudentClassEnrollment::create([
        'student_id' => $student->id,
        'semester_id' => $previousSemester->id,
        'class_id' => $previousClass->id,
        'status' => 'promoted_out',
    ]);
    StudentClassEnrollment::create([
        'student_id' => $student->id,
        'semester_id' => $currentSemester->id,
        'class_id' => $currentClass->id,
        'status' => 'active',
    ]);

    $subject = Subject::factory()->create(['name' => 'Bahasa Indonesia', 'status' => 'active']);
    $previousTask = Task::create([
        'class_id' => $previousClass->id,
        'subject_id' => $subject->id,
        'semester_id' => $previousSemester->id,
        'title' => 'Tugas Membaca Kelas 1',
        'task_date' => '2027-02-01',
        'due_date' => '2027-02-08',
        'max_score' => 100,
        'status' => 'active',
    ]);
    $currentTask = Task::create([
        'class_id' => $currentClass->id,
        'subject_id' => $subject->id,
        'semester_id' => $currentSemester->id,
        'title' => 'Tugas Membaca Kelas 2',
        'task_date' => '2027-08-01',
        'due_date' => '2027-08-08',
        'max_score' => 100,
        'status' => 'active',
    ]);

    return compact(
        'user',
        'student',
        'previousAy',
        'previousSemester',
        'previousClass',
        'previousTask',
        'currentAy',
        'currentSemester',
        'currentClass',
        'currentTask',
        'subject'
    );
}

it('shows a student historical class on the task index for a previous academic year', function () {
    $ctx = makeStudentTaskHistoryContext();

    $response = $this->actingAs($ctx['user'])->get('/tasks?academic_year_id=' . $ctx['previousAy']->id);

    $response->assertOk();
    $props = $response->viewData('page')['props'];

    expect(collect($props['academicYears'])->pluck('name')->all())->toContain('2026/2027', '2027/2028');
    expect(collect($props['classes'])->pluck('id')->all())->toContain($ctx['previousClass']->id);
    expect(collect($props['classes'])->pluck('id')->all())->not->toContain($ctx['currentClass']->id);
});

it('lets a student open tasks from their previous enrollment class and semester', function () {
    $ctx = makeStudentTaskHistoryContext();

    $response = $this->actingAs($ctx['user'])->get(route('tasks.class', [
        'class' => $ctx['previousClass']->id,
        'semester_id' => $ctx['previousSemester']->id,
    ]));

    $response->assertOk();
    $props = $response->viewData('page')['props'];

    expect(collect($props['semesters'])->pluck('id')->all())->toContain($ctx['previousSemester']->id);
    expect(collect($props['tasks'])->pluck('title')->all())->toContain('Tugas Membaca Kelas 1');
    expect(collect($props['tasks'])->pluck('title')->all())->not->toContain('Tugas Membaca Kelas 2');
});
