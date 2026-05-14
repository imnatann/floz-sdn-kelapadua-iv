<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('backfills enrollments for active students with class_id when active semester exists', function () {
    // Arrange
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    $student = Student::create(['nis' => '001', 'name' => 'A', 'class_id' => $class->id, 'status' => 'active']);

    // Pre-condition
    expect(StudentClassEnrollment::count())->toBe(0);

    // Act
    $migrationFile = base_path('database/migrations/2026_05_14_180001_backfill_student_class_enrollments.php');
    $migration = require $migrationFile;
    $migration->up();

    // Assert
    $enrollment = StudentClassEnrollment::where('student_id', $student->id)->first();
    expect($enrollment)->not->toBeNull();
    expect($enrollment->semester_id)->toBe($sem->id);
    expect($enrollment->class_id)->toBe($class->id);
    expect($enrollment->status)->toBe('active');
});

it('does not duplicate enrollments when backfill runs twice', function () {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    Student::create(['nis' => '001', 'name' => 'A', 'class_id' => $class->id, 'status' => 'active']);

    $migrationFile = base_path('database/migrations/2026_05_14_180001_backfill_student_class_enrollments.php');
    $migration = require $migrationFile;
    $migration->up();
    $migration->up();

    expect(StudentClassEnrollment::count())->toBe(1);
});

it('skips students with null class_id', function () {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    Student::create(['nis' => '001', 'name' => 'Orphan', 'class_id' => null, 'status' => 'active']);

    $migrationFile = base_path('database/migrations/2026_05_14_180001_backfill_student_class_enrollments.php');
    $migration = require $migrationFile;
    $migration->up();

    expect(StudentClassEnrollment::count())->toBe(0);
});

it('skips inactive students', function () {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    Student::create(['nis' => '001', 'name' => 'Graduated', 'class_id' => $class->id, 'status' => 'graduated']);

    $migrationFile = base_path('database/migrations/2026_05_14_180001_backfill_student_class_enrollments.php');
    $migration = require $migrationFile;
    $migration->up();

    expect(StudentClassEnrollment::count())->toBe(0);
});
