<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\User;
use App\Services\YearTransitionService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('year transition writes promoted students enrollment in target year Sem Ganjil and closes source-year enrollment', function () {
    $admin = User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);

    $sourceAy = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $targetAy = AcademicYear::create(['name' => '2026/2027', 'is_active' => false, 'start_date' => '2026-07-01', 'end_date' => '2027-06-30']);

    $sourceSem2 = Semester::create(['academic_year_id' => $sourceAy->id, 'semester_number' => 2, 'is_active' => true, 'start_date' => '2026-01-01', 'end_date' => '2026-06-30']);
    $targetSem1 = Semester::create(['academic_year_id' => $targetAy->id, 'semester_number' => 1, 'is_active' => false, 'start_date' => '2026-07-01', 'end_date' => '2026-12-31']);

    $class1A = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $sourceAy->id, 'status' => 'active']);
    // Also create target grade class so promotion can find it (mirrors source names in new AY)
    SchoolClass::create(['name' => '2A', 'grade_level' => 2, 'academic_year_id' => $sourceAy->id, 'status' => 'active']);
    $student = Student::create(['nis' => '1', 'name' => 'Nathan', 'class_id' => $class1A->id, 'status' => 'active']);
    StudentClassEnrollment::create(['student_id' => $student->id, 'semester_id' => $sourceSem2->id, 'class_id' => $class1A->id, 'status' => 'active']);

    /** @var YearTransitionService $svc */
    $svc = app(YearTransitionService::class);
    $svc->executeTransition($sourceAy->id, $targetAy->id, [], $admin);

    // Source-year Sem 2 enrollment should be closed as promoted_out
    $sourceEnrollment = StudentClassEnrollment::where('student_id', $student->id)
        ->where('semester_id', $sourceSem2->id)
        ->first();
    expect($sourceEnrollment->status)->toBe('promoted_out');

    // Target-year Sem 1 enrollment should exist as active
    $targetEnrollment = StudentClassEnrollment::where('student_id', $student->id)
        ->where('semester_id', $targetSem1->id)
        ->first();
    expect($targetEnrollment)->not->toBeNull();
    expect($targetEnrollment->status)->toBe('active');
});
