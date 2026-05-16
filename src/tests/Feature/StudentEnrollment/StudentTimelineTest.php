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
    $subject = Subject::create(['name' => 'Matematika', 'code' => 'MTK', 'status' => 'active', 'education_level' => 'SD']);

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
});
