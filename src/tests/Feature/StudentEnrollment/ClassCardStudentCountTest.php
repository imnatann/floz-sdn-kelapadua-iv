<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

function makeClassCardCountContext(): array
{
    $studentUser = User::factory()->student()->create(['email' => 'layen-count@example.test']);
    $admin = User::factory()->schoolAdmin()->create();

    $previousAy = AcademicYear::create([
        'name' => '2026/2027',
        'is_active' => false,
        'start_date' => '2026-07-01',
        'end_date' => '2027-06-30',
    ]);
    $previousSemester1 = Semester::create([
        'academic_year_id' => $previousAy->id,
        'semester_number' => 1,
        'is_active' => false,
        'start_date' => '2026-07-01',
        'end_date' => '2026-12-31',
    ]);
    $previousSemester2 = Semester::create([
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
        'email' => $studentUser->email,
        'class_id' => $currentClass->id,
        'status' => 'active',
    ]);

    foreach ([$previousSemester1, $previousSemester2] as $semester) {
        StudentClassEnrollment::create([
            'student_id' => $student->id,
            'semester_id' => $semester->id,
            'class_id' => $previousClass->id,
            'status' => $semester->id === $previousSemester2->id ? 'promoted_out' : 'active',
        ]);
    }

    StudentClassEnrollment::create([
        'student_id' => $student->id,
        'semester_id' => $currentSemester->id,
        'class_id' => $currentClass->id,
        'status' => 'active',
    ]);

    return compact('admin', 'studentUser', 'previousAy', 'previousClass');
}

it('uses distinct historical enrollment counts on class cards for tasks exams and attendance', function () {
    $ctx = makeClassCardCountContext();

    foreach (['/tasks', '/exams', '/attendance'] as $path) {
        $response = $this->actingAs($ctx['admin'])->get($path . '?academic_year_id=' . $ctx['previousAy']->id);
        $response->assertOk();

        $classRow = collect($response->viewData('page')['props']['classes'])
            ->firstWhere('id', $ctx['previousClass']->id);

        expect($classRow)->not->toBeNull();
        expect($classRow['students_count'])->toBe(1);
    }
});

it('uses the same historical enrollment count for a student viewing their own previous class cards', function () {
    $ctx = makeClassCardCountContext();

    foreach (['/tasks', '/exams', '/attendance'] as $path) {
        $response = $this->actingAs($ctx['studentUser'])->get($path . '?academic_year_id=' . $ctx['previousAy']->id);
        $response->assertOk();

        $classRow = collect($response->viewData('page')['props']['classes'])
            ->firstWhere('id', $ctx['previousClass']->id);

        expect($classRow)->not->toBeNull();
        expect($classRow['students_count'])->toBe(1);
    }
});
