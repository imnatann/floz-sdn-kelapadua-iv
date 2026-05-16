<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\StudentMutation;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('admin can mark a student as exit mid-semester (transferred/dropout/graduated)', function () {
    $admin = User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    $student = Student::create(['nis' => '1', 'name' => 'Exit', 'class_id' => $class->id, 'status' => 'active']);
    StudentClassEnrollment::create(['student_id' => $student->id, 'semester_id' => $sem->id, 'class_id' => $class->id, 'status' => 'active']);

    $this->actingAs($admin)->post("/students/{$student->id}/exit", [
        'status'    => 'transferred_out',
        'exit_date' => '2025-10-15',
        'reason'    => 'Pindah ke luar kota',
    ])->assertRedirect();

    expect(Student::find($student->id)->status)->toBe('transferred');

    $enrollment = StudentClassEnrollment::where('student_id', $student->id)->where('semester_id', $sem->id)->first();
    expect($enrollment->status)->toBe('transferred_out');
    expect($enrollment->exit_date->toDateString())->toBe('2025-10-15');

    $mutation = StudentMutation::where('student_id', $student->id)->first();
    expect($mutation)->not->toBeNull();
    expect($mutation->type)->toBe('transfer_out');
});
