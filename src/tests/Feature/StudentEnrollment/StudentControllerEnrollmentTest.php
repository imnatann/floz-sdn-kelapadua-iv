<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

function makeAdmin(): User {
    return User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);
}

function makeAyWithActiveSem(): array {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    return [$ay, $sem, $class];
}

it('creates an enrollment row when admin creates a student with class_id', function () {
    [, $sem, $class] = makeAyWithActiveSem();
    $admin = makeAdmin();

    $this->actingAs($admin)->post('/students', [
        'nis'      => '001',
        'name'     => 'Nathan',
        'class_id' => $class->id,
    ])->assertRedirect();

    $student = Student::where('nis', '001')->first();
    expect($student)->not->toBeNull();

    $enrollment = StudentClassEnrollment::where('student_id', $student->id)->first();
    expect($enrollment)->not->toBeNull();
    expect($enrollment->semester_id)->toBe($sem->id);
    expect($enrollment->class_id)->toBe($class->id);
    expect($enrollment->status)->toBe('active');
});

it('does not create an enrollment when student has no class_id', function () {
    makeAyWithActiveSem();
    $admin = makeAdmin();

    $this->actingAs($admin)->post('/students', [
        'nis'  => '002',
        'name' => 'Orphan',
    ])->assertRedirect();

    expect(StudentClassEnrollment::count())->toBe(0);
});
