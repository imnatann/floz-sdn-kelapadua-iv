<?php

use App\Models\AcademicYear;
use App\Models\Attendance;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('filters admin dashboard stats by the selected semester', function () {
    $admin = User::factory()->schoolAdmin()->create();

    $academicYear = AcademicYear::create([
        'name' => '2026/2027',
        'start_date' => '2026-07-01',
        'end_date' => '2027-06-30',
        'is_active' => true,
    ]);

    $oldSemester = Semester::create([
        'academic_year_id' => $academicYear->id,
        'semester_number' => 1,
        'start_date' => '2026-07-01',
        'end_date' => '2026-12-31',
        'is_active' => false,
    ]);

    $activeSemester = Semester::create([
        'academic_year_id' => $academicYear->id,
        'semester_number' => 2,
        'start_date' => '2027-01-01',
        'end_date' => '2027-06-30',
        'is_active' => true,
    ]);

    $class = SchoolClass::create([
        'name' => 'Kelas 1',
        'grade_level' => 1,
        'academic_year_id' => $academicYear->id,
        'status' => 'active',
    ]);

    $oldStudent = Student::create([
        'nis' => '1001',
        'name' => 'Siswa Lama',
        'class_id' => $class->id,
        'status' => 'active',
    ]);

    $currentStudent = Student::create([
        'nis' => '1002',
        'name' => 'Siswa Aktif',
        'class_id' => $class->id,
        'status' => 'active',
    ]);

    StudentClassEnrollment::create([
        'student_id' => $oldStudent->id,
        'semester_id' => $oldSemester->id,
        'class_id' => $class->id,
        'status' => StudentClassEnrollment::STATUS_PROMOTED_OUT,
    ]);

    StudentClassEnrollment::create([
        'student_id' => $currentStudent->id,
        'semester_id' => $activeSemester->id,
        'class_id' => $class->id,
        'status' => StudentClassEnrollment::STATUS_ACTIVE,
    ]);

    Attendance::create([
        'student_id' => $oldStudent->id,
        'class_id' => $class->id,
        'semester_id' => $oldSemester->id,
        'date' => '2026-08-01',
        'status' => 'present',
        'meeting_number' => 1,
    ]);

    Attendance::create([
        'student_id' => $currentStudent->id,
        'class_id' => $class->id,
        'semester_id' => $activeSemester->id,
        'date' => '2027-02-01',
        'status' => 'absent',
        'meeting_number' => 1,
    ]);

    $this->actingAs($admin)
        ->get(route('dashboard', [
            'academic_year_id' => $academicYear->id,
            'semester_id' => $oldSemester->id,
        ]))
        ->assertOk()
        ->assertInertia(fn ($page) => $page
            ->component('Dashboard/AdminDashboard')
            ->where('stats.total_students', 1)
            ->where('stats.attendance_present', 1)
            ->where('stats.attendance_absent', 0)
            ->where('filters.academic_year_id', $academicYear->id)
            ->where('filters.semester_id', $oldSemester->id)
            ->has('academicYears', 1)
            ->has('semesters', 2)
        );
});
