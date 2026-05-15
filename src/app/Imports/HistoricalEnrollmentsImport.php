<?php

namespace App\Imports;

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use Maatwebsite\Excel\Concerns\Importable;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;

class HistoricalEnrollmentsImport implements ToCollection, WithHeadingRow
{
    use Importable;

    public array $errors = [];
    public int $imported = 0;

    public function collection($rows)
    {
        $allowedStatuses = ['active', 'promoted_out', 'retained_out', 'transferred_out', 'dropped_out', 'graduated'];

        foreach ($rows as $i => $row) {
            $rowNum = $i + 2;
            $nis    = (string) ($row['nis'] ?? '');
            $ayName = (string) ($row['tahun_ajaran'] ?? '');
            $semNum = (int) ($row['semester'] ?? 0);
            $clsName = (string) ($row['kelas'] ?? '');
            $status = (string) ($row['status'] ?? 'active');

            if (! $nis || ! $ayName || ! $semNum || ! $clsName) {
                $this->errors[] = "Baris $rowNum: kolom NIS / Tahun Ajaran / Semester / Kelas tidak boleh kosong.";
                continue;
            }
            if (! in_array($status, $allowedStatuses)) {
                $this->errors[] = "Baris $rowNum: status '$status' tidak valid.";
                continue;
            }

            $student = Student::where('nis', $nis)->first();
            if (! $student) {
                $this->errors[] = "Baris $rowNum: siswa dengan NIS '$nis' tidak ditemukan.";
                continue;
            }

            $ay = AcademicYear::where('name', $ayName)->first();
            if (! $ay) {
                $this->errors[] = "Baris $rowNum: Tahun Ajaran '$ayName' tidak ditemukan.";
                continue;
            }

            $sem = Semester::where('academic_year_id', $ay->id)->where('semester_number', $semNum)->first();
            if (! $sem) {
                $this->errors[] = "Baris $rowNum: Semester $semNum di TA '$ayName' tidak ditemukan.";
                continue;
            }

            $class = SchoolClass::where('academic_year_id', $ay->id)->where('name', $clsName)->first();
            if (! $class) {
                $this->errors[] = "Baris $rowNum: Kelas '$clsName' di TA '$ayName' tidak ditemukan.";
                continue;
            }

            StudentClassEnrollment::updateOrCreate(
                ['student_id' => $student->id, 'semester_id' => $sem->id],
                ['class_id' => $class->id, 'status' => $status],
            );
            $this->imported++;
        }
    }
}
