<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Maatwebsite\Excel\Facades\Excel;
use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\WithHeadings;

uses(RefreshDatabase::class);

class _HistoricalEnrollmentsTestSheet implements FromArray, WithHeadings
{
    public function __construct(public array $rows) {}
    public function array(): array { return $this->rows; }
    public function headings(): array { return ['NIS', 'Tahun Ajaran', 'Semester', 'Kelas', 'Status']; }
}

it('admin can bulk-import historical enrollments from Excel', function () {
    $admin = User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);
    $ay = AcademicYear::create(['name' => '2024/2025', 'is_active' => false, 'start_date' => '2024-07-01', 'end_date' => '2025-06-30']);
    $sem = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => false, 'start_date' => '2024-07-01', 'end_date' => '2024-12-31']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    $student = Student::create(['nis' => '100', 'name' => 'Historic', 'class_id' => null, 'status' => 'active']);

    $sheet = new _HistoricalEnrollmentsTestSheet([
        ['100', '2024/2025', 1, '1A', 'promoted_out'],
    ]);

    Excel::store($sheet, 'test-historical.xlsx', 'local');
    $path = storage_path('app/private/test-historical.xlsx');
    $file = new UploadedFile($path, 'historical.xlsx', null, null, true);

    $this->actingAs($admin)
        ->post('/students/import-historical', ['file' => $file])
        ->assertRedirect();

    $enrollment = StudentClassEnrollment::where('student_id', $student->id)->first();
    expect($enrollment)->not->toBeNull();
    expect($enrollment->semester_id)->toBe($sem->id);
    expect($enrollment->class_id)->toBe($class->id);
    expect($enrollment->status)->toBe('promoted_out');

    @unlink($path);
});
