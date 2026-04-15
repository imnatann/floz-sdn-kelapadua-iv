<?php

namespace Database\Factories;

use App\Models\ReportCard;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use Illuminate\Database\Eloquent\Factories\Factory;

class ReportCardFactory extends Factory
{
    protected $model = ReportCard::class;

    public function definition(): array
    {
        return [
            'student_id' => Student::factory(),
            'class_id' => SchoolClass::factory(),
            'semester_id' => Semester::factory(),
            'report_type' => 'final',
            'rank' => null,
            'total_score' => null,
            'average_score' => null,
            'attendance_present' => 0,
            'attendance_sick' => 0,
            'attendance_permit' => 0,
            'attendance_absent' => 0,
            'extracurricular' => null,
            'achievements' => null,
            'notes' => null,
            'behavior_notes' => null,
            'homeroom_comment' => null,
            'principal_comment' => null,
            'status' => 'draft',
            'published_at' => null,
            'pdf_url' => null,
        ];
    }
}
