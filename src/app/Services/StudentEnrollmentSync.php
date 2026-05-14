<?php

namespace App\Services;

use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use Illuminate\Support\Facades\DB;

/**
 * Single-responsibility helper that keeps student_class_enrollments rows
 * consistent with student CRUD and year transitions.
 *
 * All methods are idempotent and safe to call inside a parent transaction.
 */
class StudentEnrollmentSync
{
    /**
     * Ensure an active enrollment row exists for (student, active-semester, class).
     * If a row already exists, its class_id is overwritten to match `$classId`.
     * If no active semester exists OR `$classId` is null, no-op.
     *
     * Used by: StudentController::store, StudentController::update.
     */
    public function syncCurrent(Student $student, ?int $classId): void
    {
        if ($classId === null) {
            return;
        }
        $sem = Semester::where('is_active', true)->first();
        if (! $sem) {
            return;
        }

        StudentClassEnrollment::updateOrCreate(
            ['student_id' => $student->id, 'semester_id' => $sem->id],
            ['class_id' => $classId, 'status' => StudentClassEnrollment::STATUS_ACTIVE, 'exit_date' => null, 'exit_reason' => null],
        );
    }

    /**
     * Write an enrollment for a specific (student, semester, class).
     * Used by YearTransitionService when promoting/retaining into target year Sem Ganjil.
     */
    public function writeEnrollment(int $studentId, int $semesterId, int $classId, string $status = StudentClassEnrollment::STATUS_ACTIVE): StudentClassEnrollment
    {
        return StudentClassEnrollment::updateOrCreate(
            ['student_id' => $studentId, 'semester_id' => $semesterId],
            ['class_id' => $classId, 'status' => $status, 'exit_date' => null, 'exit_reason' => null],
        );
    }

    /**
     * Mark the latest enrollment for a student in a given AY as a terminal status
     * (promoted_out / retained_out / graduated / transferred_out / dropped_out).
     * Used by YearTransitionService to close out the source-year enrollment.
     */
    public function closeLatestEnrollmentInAcademicYear(int $studentId, int $academicYearId, string $status, ?string $reason = null): void
    {
        $semesterIds = Semester::where('academic_year_id', $academicYearId)->pluck('id');
        $latest = StudentClassEnrollment::where('student_id', $studentId)
            ->whereIn('semester_id', $semesterIds)
            ->orderByDesc('semester_id')
            ->first();

        if ($latest) {
            $latest->update([
                'status'      => $status,
                'exit_date'   => now()->toDateString(),
                'exit_reason' => $reason,
            ]);
        }
    }
}
