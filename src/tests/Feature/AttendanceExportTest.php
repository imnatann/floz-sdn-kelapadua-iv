<?php

use App\Exports\Sheets\ClassAttendanceSheet;
use App\Models\AcademicYear;
use App\Models\Attendance;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Maatwebsite\Excel\Facades\Excel;

uses(RefreshDatabase::class);

it('export attendance returns an xlsx download for admin', function () {
    Excel::fake();

    $ay    = AcademicYear::factory()->create(['is_active' => true]);
    $sem   = Semester::factory()->create(['academic_year_id' => $ay->id, 'is_active' => true]);
    $admin = User::factory()->create(['role' => 'school_admin']);

    $response = $this->actingAs($admin)
        ->get(route('analytics.export.attendance', ['semester_id' => $sem->id]));

    $response->assertOk();

    // Excel::fake() v3 stores downloads keyed by filename; check at least one Rekap_Absensi file was downloaded
    $filename = "Rekap_Absensi_Sekolah_{$sem->academicYear->name}_Sem{$sem->semester_number}_" . now()->format('Ymd') . '.xlsx';
    Excel::assertDownloaded($filename);
});

it('export attendance is forbidden for teacher', function () {
    $ay      = AcademicYear::factory()->create(['is_active' => true]);
    $sem     = Semester::factory()->create(['academic_year_id' => $ay->id, 'is_active' => true]);
    $teacher = User::factory()->create(['role' => 'teacher']);

    $this->actingAs($teacher)
        ->get(route('analytics.export.attendance', ['semester_id' => $sem->id]))
        ->assertForbidden();
});

it('ClassAttendanceSheet produces correct H/S/I/A row for a student', function () {
    $ay      = AcademicYear::factory()->create(['is_active' => true]);
    $sem     = Semester::factory()->create(['academic_year_id' => $ay->id, 'is_active' => true]);
    $class   = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $student = Student::factory()->create([
        'class_id' => $class->id,
        'status'   => 'active',
        'nis'      => '12345',
    ]);

    // 10 present records (different meeting numbers to avoid unique constraint)
    foreach (range(1, 10) as $n) {
        Attendance::factory()->create([
            'student_id'     => $student->id,
            'class_id'       => $class->id,
            'semester_id'    => $sem->id,
            'status'         => 'present',
            'meeting_number' => $n,
        ]);
    }

    // 2 absent records
    Attendance::factory()->create([
        'student_id'     => $student->id,
        'class_id'       => $class->id,
        'semester_id'    => $sem->id,
        'status'         => 'absent',
        'meeting_number' => 11,
    ]);
    Attendance::factory()->create([
        'student_id'     => $student->id,
        'class_id'       => $class->id,
        'semester_id'    => $sem->id,
        'status'         => 'absent',
        'meeting_number' => 12,
    ]);

    $sheet = new ClassAttendanceSheet($class, $sem->id);
    $row   = $sheet->collection()->first();

    expect($row[3])->toBe(10)        // Hadir
        ->and($row[6])->toBe(2)      // Alpha
        ->and($row[7])->toBe('83.3%'); // % Kehadiran (10/12 = 83.3)
});
