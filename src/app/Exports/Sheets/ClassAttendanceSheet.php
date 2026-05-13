<?php

namespace App\Exports\Sheets;

use App\Models\Attendance;
use App\Models\SchoolClass;
use App\Models\Student;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class ClassAttendanceSheet implements FromCollection, WithHeadings, WithTitle, WithStyles
{
    public function __construct(
        private readonly SchoolClass $class,
        private readonly int $semesterId,
    ) {}

    public function title(): string
    {
        // Excel sheet name max 31 chars
        return substr($this->class->name, 0, 31);
    }

    public function headings(): array
    {
        return ['No', 'NIS', 'Nama Siswa', 'Hadir', 'Sakit', 'Izin', 'Alpha', '% Kehadiran'];
    }

    public function collection(): Collection
    {
        // NOTE: Format must match Dinas template.
        // Request real Dinas sample from school in Phase 11.5 if not yet obtained.
        // Current layout: per-student aggregate (H/S/I/A total per semester).

        $students = Student::where('class_id', $this->class->id)
            ->where('status', 'active')
            ->orderBy('name')
            ->get(['id', 'nis', 'name']);

        return $students->map(function ($student, $idx) {
            $counts = Attendance::where('student_id', $student->id)
                ->where('semester_id', $this->semesterId)
                ->selectRaw('status, COUNT(*) as cnt')
                ->groupBy('status')
                ->pluck('cnt', 'status');

            $h     = (int) ($counts['present'] ?? 0);
            $s     = (int) ($counts['sick']    ?? 0);
            $i     = (int) ($counts['permit']  ?? 0);
            $a     = (int) ($counts['absent']  ?? 0);
            $total = $h + $s + $i + $a;
            $pct   = $total > 0 ? round($h / $total * 100, 1) : 0.0;

            return [$idx + 1, $student->nis, $student->name, $h, $s, $i, $a, "{$pct}%"];
        });
    }

    public function styles(Worksheet $sheet): array
    {
        return [
            1 => ['font' => ['bold' => true]],
        ];
    }
}
