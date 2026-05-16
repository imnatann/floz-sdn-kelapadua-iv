<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('activating a new semester carries over enrollments from previous semester', function () {
    $admin = User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem1 = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $sem2 = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 2, 'is_active' => false, 'start_date' => '2026-01-01', 'end_date' => '2026-06-30']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    $student = Student::create(['nis' => '1', 'name' => 'Stay', 'class_id' => $class->id, 'status' => 'active']);
    StudentClassEnrollment::create(['student_id' => $student->id, 'semester_id' => $sem1->id, 'class_id' => $class->id, 'status' => 'active']);

    $this->actingAs($admin)->post("/semesters/{$sem2->id}/activate")->assertRedirect();

    $sem2->refresh();
    expect($sem2->is_active)->toBeTrue();

    $newEnrollment = StudentClassEnrollment::where('student_id', $student->id)
        ->where('semester_id', $sem2->id)
        ->first();
    expect($newEnrollment)->not->toBeNull();
    expect($newEnrollment->class_id)->toBe($class->id);
    expect($newEnrollment->status)->toBe('active');
});
