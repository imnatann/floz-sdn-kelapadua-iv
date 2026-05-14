<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('task class roster lists students who had enrollment in that class+semester even if they have since moved on', function () {
    $admin = User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => false, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => false, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $oldClass = SchoolClass::create(['name' => '1', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    $newClass = SchoolClass::create(['name' => '2', 'grade_level' => 2, 'academic_year_id' => $ay->id, 'status' => 'active']);

    // Student NOW in newClass (moved up), but historically in oldClass
    $student = Student::create(['nis' => '1', 'name' => 'Historic', 'class_id' => $newClass->id, 'status' => 'active']);
    StudentClassEnrollment::create([
        'student_id' => $student->id, 'semester_id' => $sem->id,
        'class_id' => $oldClass->id, 'status' => 'promoted_out',
    ]);

    $response = $this->actingAs($admin)->get("/tasks/class/{$oldClass->id}?semester_id={$sem->id}");
    $response->assertOk();

    expect($response->viewData('page')['props']['studentsCount'])->toBe(1);
});
