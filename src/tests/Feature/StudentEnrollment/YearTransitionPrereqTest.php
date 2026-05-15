<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\User;
use App\Services\YearTransitionService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('year transition rejects execution when source AY Sem 2 is not active', function () {
    $admin = User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);
    $sourceAy = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $targetAy = AcademicYear::create(['name' => '2026/2027', 'is_active' => false, 'start_date' => '2026-07-01', 'end_date' => '2027-06-30']);

    // Only Sem 1 of source AY exists/active (NOT Sem 2)
    Semester::create(['academic_year_id' => $sourceAy->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    Semester::create(['academic_year_id' => $targetAy->id, 'semester_number' => 1, 'is_active' => false, 'start_date' => '2026-07-01', 'end_date' => '2026-12-31']);

    $class1A = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $sourceAy->id, 'status' => 'active']);
    Student::create(['nis' => '1', 'name' => 'X', 'class_id' => $class1A->id, 'status' => 'active']);

    $svc = app(YearTransitionService::class);

    expect(fn () => $svc->executeTransition($sourceAy->id, $targetAy->id, [], $admin))
        ->toThrow(\RuntimeException::class);
});
