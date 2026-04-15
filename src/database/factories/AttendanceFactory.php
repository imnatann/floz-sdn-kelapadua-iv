<?php

namespace Database\Factories;

use App\Models\Attendance;
use App\Models\SchoolClass;
use App\Models\Student;
use Illuminate\Database\Eloquent\Factories\Factory;

class AttendanceFactory extends Factory
{
    protected $model = Attendance::class;

    public function definition(): array
    {
        return [
            'student_id' => Student::factory(),
            'class_id' => SchoolClass::factory(),
            'subject_id' => null,
            'semester_id' => null,
            'recorded_by' => null,
            'date' => now()->toDateString(),
            'meeting_number' => 1,
            'status' => 'hadir',
            'notes' => null,
        ];
    }
}
