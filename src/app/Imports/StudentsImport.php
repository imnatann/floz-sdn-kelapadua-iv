<?php

namespace App\Imports;

use App\Models\Student;
use App\Models\SchoolClass; // Ensure this model exists and is correct namespace
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;
use Illuminate\Validation\Rule;

class StudentsImport implements ToModel, WithHeadingRow, WithValidation
{
    /** 
     * Cache classes to avoid repeated queries 
     */
    protected $classes;

    public function __construct()
    {
        $this->classes = SchoolClass::pluck('id', 'name')->all();
    }

    /**
    * @param array $row
    *
    * @return \Illuminate\Database\Eloquent\Model|null
    */
    public function model(array $row)
    {
        // Find class ID by name (case-insensitive search potential, but array lookup is strict)
        // Adjust if needed. For now, strict match.
        $className = $row['kelas'] ?? null;
        $classId = $this->classes[$className] ?? null;

        return new Student([
            'nis'          => $row['nis'],
            'nisn'         => $row['nisn'] ?? null,
            'name'         => $row['nama_lengkap'],
            'gender'       => strtolower($row['jenis_kelamin']) === 'l' ? 'male' : 'female',
            'birth_place'  => $row['tempat_lahir'] ?? null,
            // Assuming Excel date is handled correctly or format YYYY-MM-DD
            'birth_date'   => isset($row['tanggal_lahir']) ? \PhpOffice\PhpSpreadsheet\Shared\Date::excelToDateTimeObject($row['tanggal_lahir']) : null,
            'religion'     => $row['agama'] ?? null,
            'address'      => $row['alamat'] ?? null,
            'parent_name'  => $row['nama_orang_tua'] ?? null,
            'parent_phone' => $row['no_hp_orang_tua'] ?? null,
            'status'       => 'active',
            'class_id'     => $classId,
        ]);
    }

    public function rules(): array
    {
        return [
            'nis' => [
                'required',
                'string',
                'max:20',
                Rule::unique('tenant.students', 'nis') // Check uniqueness in tenant db
            ],
            'nama_lengkap' => 'required|string|max:255',
            'jenis_kelamin' => 'required|in:L,P,l,p,Male,Female,male,female',
            'kelas' => 'nullable|string|exists:tenant.classes,name',
        ];
    }

    public function customValidationMessages()
    {
        return [
            'nis.unique' => 'NIS :input sudah terdaftar.',
            'kelas.exists' => 'Kelas :input tidak ditemukan.',
        ];
    }
}
