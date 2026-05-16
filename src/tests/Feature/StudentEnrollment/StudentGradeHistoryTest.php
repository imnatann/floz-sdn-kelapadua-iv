<?php

use App\Models\AcademicYear;
use App\Models\Grade;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\Subject;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

function makeStudentWithTwoYearHistory(): array
{
    $user = User::factory()->student()->create(['email' => 'layen@example.test']);

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

    $subject = Subject::factory()->create(['name' => 'Matematika', 'status' => 'active']);
    $previousGrade = Grade::create([
        'student_id' => $student->id,
        'subject_id' => $subject->id,
        'class_id' => $previousClass->id,
        'semester_id' => $previousSemester->id,
        'final_score' => 88,
        'predicate' => 'A',
    ]);
    $currentGrade = Grade::create([
        'student_id' => $student->id,
        'subject_id' => $subject->id,
        'class_id' => $currentClass->id,
        'semester_id' => $currentSemester->id,
        'final_score' => 91,
        'predicate' => 'A',
    ]);

    return compact(
        'user',
        'student',
        'previousAy',
        'previousSemester',
        'previousClass',
        'previousGrade',
        'currentAy',
        'currentSemester',
        'currentClass',
        'currentGrade',
        'subject'
    );
}

it('lets a student view grades from a previous academic year class after promotion', function () {
    $ctx = makeStudentWithTwoYearHistory();

    $response = $this->actingAs($ctx['user'])->get('/grades?' . http_build_query([
        'academic_year_id' => $ctx['previousAy']->id,
        'class_id' => $ctx['previousClass']->id,
        'semester_id' => $ctx['previousSemester']->id,
    ]));

    $response->assertOk();
    $props = $response->viewData('page')['props'];

    expect(collect($props['academicYears'])->pluck('name')->all())->toContain('2026/2027', '2027/2028');
    expect(collect($props['classes'])->pluck('id')->all())->toContain($ctx['previousClass']->id);
    expect(collect($props['semesters'])->pluck('id')->all())->toContain($ctx['previousSemester']->id);

    $grades = collect($props['grades']);
    expect($grades)->toHaveCount(1);
    expect($grades->first()['class_id'])->toBe($ctx['previousClass']->id);
    expect((float) $grades->first()['final_score'])->toBe(88.0);
});

it('includes class and academic year on the student academic profile history', function () {
    $ctx = makeStudentWithTwoYearHistory();

    $response = $this->actingAs($ctx['user'])->get("/students/{$ctx['student']->id}");

    $response->assertOk();
    $grades = collect($response->viewData('page')['props']['student']['grades']);
    $previousGrade = $grades->firstWhere('id', $ctx['previousGrade']->id);
    $currentGrade = $grades->firstWhere('id', $ctx['currentGrade']->id);

    expect($previousGrade['school_class']['name'])->toBe('Kelas 1');
    expect($previousGrade['semester']['academic_year']['name'])->toBe('2026/2027');
    expect($currentGrade['school_class']['name'])->toBe('Kelas 2');
    expect($currentGrade['semester']['academic_year']['name'])->toBe('2027/2028');
});
