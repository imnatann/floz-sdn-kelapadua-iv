<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Services\EnrollmentCarryOverService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('execute honors per-student overrides for keluar/lulus during carry-over', function () {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem1 = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $sem2 = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 2, 'is_active' => false, 'start_date' => '2026-01-01', 'end_date' => '2026-06-30']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);

    $stay = Student::create(['nis' => '1', 'name' => 'Stay', 'class_id' => $class->id, 'status' => 'active']);
    $leave = Student::create(['nis' => '2', 'name' => 'Leave', 'class_id' => $class->id, 'status' => 'active']);
    StudentClassEnrollment::create(['student_id' => $stay->id, 'semester_id' => $sem1->id, 'class_id' => $class->id, 'status' => 'active']);
    StudentClassEnrollment::create(['student_id' => $leave->id, 'semester_id' => $sem1->id, 'class_id' => $class->id, 'status' => 'active']);

    $svc = app(EnrollmentCarryOverService::class);
    $result = $svc->execute($sem2->id, [
        $leave->id => 'transferred_out',
    ]);

    expect($result['carried'])->toBe(1);
    expect(StudentClassEnrollment::where('student_id', $stay->id)->where('semester_id', $sem2->id)->where('status', 'active')->exists())->toBeTrue();
    expect(StudentClassEnrollment::where('student_id', $leave->id)->where('semester_id', $sem1->id)->value('status'))->toBe('transferred_out');
    expect(StudentClassEnrollment::where('student_id', $leave->id)->where('semester_id', $sem2->id)->exists())->toBeFalse();
    expect(Student::find($leave->id)->status)->toBe('transferred');
});
