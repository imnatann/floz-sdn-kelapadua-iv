<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Services\EnrollmentCarryOverService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

function makeAyWithTwoSemesters(): array {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem1 = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $sem2 = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 2, 'is_active' => false, 'start_date' => '2026-01-01', 'end_date' => '2026-06-30']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    return [$ay, $sem1, $sem2, $class];
}

it('preview lists active enrollments from previous semester and skips non-active ones', function () {
    [, $sem1, $sem2, $class] = makeAyWithTwoSemesters();

    $stay = Student::create(['nis' => '1', 'name' => 'Stay', 'class_id' => $class->id, 'status' => 'active']);
    $left = Student::create(['nis' => '2', 'name' => 'Left', 'class_id' => $class->id, 'status' => 'active']);

    StudentClassEnrollment::create(['student_id' => $stay->id, 'semester_id' => $sem1->id, 'class_id' => $class->id, 'status' => 'active']);
    StudentClassEnrollment::create(['student_id' => $left->id, 'semester_id' => $sem1->id, 'class_id' => $class->id, 'status' => 'transferred_out', 'exit_date' => '2025-10-01']);

    $svc = app(EnrollmentCarryOverService::class);
    $preview = $svc->preview($sem2->id);

    expect($preview['source_semester_id'])->toBe($sem1->id);
    expect($preview['target_semester_id'])->toBe($sem2->id);
    expect(count($preview['carry_over']))->toBe(1);
    expect($preview['carry_over'][0]['student_id'])->toBe($stay->id);
    expect(count($preview['skipped']))->toBe(1);
    expect($preview['skipped'][0]['student_id'])->toBe($left->id);
    expect($preview['skipped'][0]['reason'])->toContain('transferred_out');
});

it('preview returns empty result when no previous semester exists', function () {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem1 = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => false, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);

    $svc = app(EnrollmentCarryOverService::class);
    $preview = $svc->preview($sem1->id);

    expect($preview['source_semester_id'])->toBeNull();
    expect($preview['carry_over'])->toBe([]);
});

it('execute creates enrollment rows for carry-over students and is idempotent', function () {
    [, $sem1, $sem2, $class] = makeAyWithTwoSemesters();
    $stay = Student::create(['nis' => '1', 'name' => 'Stay', 'class_id' => $class->id, 'status' => 'active']);
    StudentClassEnrollment::create(['student_id' => $stay->id, 'semester_id' => $sem1->id, 'class_id' => $class->id, 'status' => 'active']);

    $svc = app(EnrollmentCarryOverService::class);
    $result = $svc->execute($sem2->id);
    expect($result['carried'])->toBe(1);

    // Idempotent — second run is a no-op
    $result2 = $svc->execute($sem2->id);
    expect($result2['carried'])->toBe(0);

    expect(StudentClassEnrollment::where('semester_id', $sem2->id)->count())->toBe(1);
});

it('execute returns zero when no previous semester exists', function () {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem1 = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => false, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);

    $svc = app(EnrollmentCarryOverService::class);
    $result = $svc->execute($sem1->id);
    expect($result['carried'])->toBe(0);
    expect($result['source_semester_id'])->toBeNull();
});
