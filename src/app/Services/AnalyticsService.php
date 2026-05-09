<?php

namespace App\Services;

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\TeachingAssignment;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\DB;

class AnalyticsService
{
    public function __construct(
        private readonly GradeCalculationService $gradeCalc,
    ) {}

    // ── Scope Helper ──────────────────────────────────────────────────────────

    /**
     * Returns array of class IDs visible to the given user.
     *
     * - School admin: all class IDs in active AY
     * - Teacher with homeroom and/or TAs: union of those IDs
     * - Teacher with no Teacher record or no assignments: []
     */
    private function visibleClassIds(User $scope): array
    {
        $teacher = $scope->teacher;

        if (! $teacher) {
            return [];
        }

        $homeroom = SchoolClass::where('homeroom_teacher_id', $teacher->id)->pluck('id');
        $taught   = TeachingAssignment::where('teacher_id', $teacher->id)->pluck('class_id');

        return $homeroom->merge($taught)->unique()->values()->all();
    }

    // ── W1: Today's Attendance ────────────────────────────────────────────────

    public function todaysAttendance(?User $scope = null): array
    {
        if ($scope !== null && ! $scope->isSchoolAdmin()) {
            $ids = $this->visibleClassIds($scope);

            if (empty($ids)) {
                return [
                    'data' => [
                        'present'    => 0,
                        'sick'       => 0,
                        'permit'     => 0,
                        'absent'     => 0,
                        'percentage' => 0.0,
                    ],
                    'meta' => [
                        'generated_at' => now()->toIso8601String(),
                        'note'         => 'Tidak ada kelas yang dikelola.',
                        'empty_reason' => 'no_assigned_classes',
                    ],
                ];
            }

            $rows = DB::table('attendance')
                ->whereDate('date', today())
                ->whereIn('class_id', $ids)
                ->selectRaw('status, COUNT(*) as total')
                ->groupBy('status')
                ->pluck('total', 'status');
        } else {
            $rows = DB::table('attendance')
                ->whereDate('date', today())
                ->selectRaw('status, COUNT(*) as total')
                ->groupBy('status')
                ->pluck('total', 'status');
        }

        $present = (int) ($rows['present'] ?? 0);
        $sick    = (int) ($rows['sick']    ?? 0);
        $permit  = (int) ($rows['permit']  ?? 0);
        $absent  = (int) ($rows['absent']  ?? 0);
        $grand   = $present + $sick + $permit + $absent;

        return [
            'data' => [
                'present'    => $present,
                'sick'       => $sick,
                'permit'     => $permit,
                'absent'     => $absent,
                'percentage' => $grand > 0 ? round($present / $grand * 100, 1) : 0.0,
            ],
            'meta' => ['generated_at' => now()->toIso8601String()],
        ];
    }

    // ── W2: Classes Missing Attendance ────────────────────────────────────────

    public function classesMissingAttendance(?User $scope = null): array
    {
        if ($scope !== null && ! $scope->isSchoolAdmin()) {
            throw new AuthorizationException('Widget ini hanya tersedia untuk admin.');
        }

        $activeAyId = AcademicYear::where('is_active', true)->value('id');

        $classesWithAttendance = DB::table('attendance')
            ->whereDate('date', today())
            ->distinct()
            ->pluck('class_id');

        $missing = SchoolClass::with('homeroomTeacher:id,name')
            ->where('academic_year_id', $activeAyId)
            ->whereNotIn('id', $classesWithAttendance)
            ->get(['id', 'name', 'homeroom_teacher_id']);

        return [
            'data' => $missing->map(fn ($c) => [
                'class_id'         => $c->id,
                'class_name'       => $c->name,
                'homeroom_teacher' => $c->homeroomTeacher?->name ?? '–',
            ])->all(),
            'meta' => [
                'generated_at' => now()->toIso8601String(),
                'date'         => today()->toDateString(),
            ],
        ];
    }

    // ── W3: Class Average Comparison ──────────────────────────────────────────

    public function classAvgComparison(int $semesterId, ?User $scope = null): array
    {
        if ($scope !== null && ! $scope->isSchoolAdmin()) {
            $ids = $this->visibleClassIds($scope);

            if (empty($ids)) {
                return [
                    'data' => [],
                    'meta' => [
                        'semester_id'  => $semesterId,
                        'generated_at' => now()->toIso8601String(),
                        'note'         => 'Tidak ada kelas yang diampu.',
                        'empty_reason' => 'no_assigned_classes',
                    ],
                ];
            }
        }

        $query = DB::table('report_cards')
            ->join('classes', 'report_cards.class_id', '=', 'classes.id')
            ->where('report_cards.semester_id', $semesterId)
            ->where('report_cards.report_type', 'final')
            ->selectRaw('report_cards.class_id, classes.name as class_name, ROUND(AVG(report_cards.average_score)::numeric, 2) as avg')
            ->groupBy('report_cards.class_id', 'classes.name')
            ->orderByDesc('avg');

        if (isset($ids)) {
            $query->whereIn('report_cards.class_id', $ids);
        }

        $rows = $query->get();

        // WARN-1: empty state with meta note
        if ($rows->isEmpty()) {
            return [
                'data' => [],
                'meta' => [
                    'semester_id'  => $semesterId,
                    'generated_at' => now()->toIso8601String(),
                    'note'         => 'Belum ada rapor yang dipublikasikan untuk semester ini.',
                    'empty_reason' => 'no_published_report_cards',
                ],
            ];
        }

        return [
            'data' => $rows->map(fn ($r) => [
                'class_id'   => $r->class_id,
                'class_name' => $r->class_name,
                'avg'        => (float) $r->avg,
            ])->all(),
            'meta' => [
                'semester_id'  => $semesterId,
                'generated_at' => now()->toIso8601String(),
            ],
        ];
    }

    // ── W4: Subject Grade Distribution ───────────────────────────────────────

    public function subjectGradeDistribution(int $classId, int $semesterId, ?User $scope = null): array
    {
        if ($scope !== null && ! $scope->isSchoolAdmin()) {
            $ids = $this->visibleClassIds($scope);

            if (! in_array($classId, $ids, true)) {
                return [
                    'data' => [],
                    'meta' => [
                        'class_id'     => $classId,
                        'semester_id'  => $semesterId,
                        'generated_at' => now()->toIso8601String(),
                        'note'         => 'Anda tidak memiliki akses ke kelas ini.',
                        'empty_reason' => 'access_denied',
                    ],
                ];
            }
        }

        $rows = DB::table('grades')
            ->join('subjects', 'grades.subject_id', '=', 'subjects.id')
            ->where('grades.class_id', $classId)
            ->where('grades.semester_id', $semesterId)
            ->selectRaw('grades.subject_id, subjects.name as subject_name, grades.predicate, COUNT(*) as cnt')
            ->groupBy('grades.subject_id', 'subjects.name', 'grades.predicate')
            ->get();

        $grouped = $rows->groupBy('subject_id')->map(function ($items, $subjId) {
            $counts = ['A' => 0, 'B' => 0, 'C' => 0, 'D' => 0];
            foreach ($items as $item) {
                if (isset($counts[$item->predicate])) {
                    $counts[$item->predicate] = (int) $item->cnt;
                }
            }
            return [
                'subject_id'   => $subjId,
                'subject_name' => $items->first()->subject_name,
                'counts'       => $counts,
            ];
        })->values()->all();

        return [
            'data' => $grouped,
            'meta' => [
                'class_id'     => $classId,
                'semester_id'  => $semesterId,
                'generated_at' => now()->toIso8601String(),
            ],
        ];
    }

    // ── W5: Attendance Trend ──────────────────────────────────────────────────

    public function attendanceTrend(int $classId, int $semesterId, int $weeks = 12, ?User $scope = null): array
    {
        if ($scope !== null && ! $scope->isSchoolAdmin()) {
            $ids = $this->visibleClassIds($scope);

            if (! in_array($classId, $ids, true)) {
                return [
                    'data' => [],
                    'meta' => [
                        'class_id'     => $classId,
                        'semester_id'  => $semesterId,
                        'weeks'        => $weeks,
                        'note'         => 'Anda tidak memiliki akses ke kelas ini.',
                        'empty_reason' => 'access_denied',
                    ],
                ];
            }
        }

        $since = now()->subWeeks($weeks)->startOfWeek();

        // BLOCK-1 fix: explicit pgsql branch (PLAN_CHECK requirement)
        $conn = DB::connection()->getDriverName();
        $weekExpr = match ($conn) {
            'sqlite'           => "strftime('%Y-%W', \"date\")",
            'pgsql'            => "TO_CHAR(date, 'IYYY-IW')",
            'mysql', 'mariadb' => "DATE_FORMAT(date, '%Y-%u')",
            default            => throw new \RuntimeException("Unsupported DB driver: {$conn}"),
        };

        $rows = DB::table('attendance')
            ->where('class_id', $classId)
            ->where('semester_id', $semesterId)
            ->where('date', '>=', $since->toDateString())
            ->selectRaw("{$weekExpr} as week_key, status, COUNT(*) as cnt")
            ->groupByRaw("{$weekExpr}, status")
            ->orderBy('week_key')
            ->get();

        $byWeek = $rows->groupBy('week_key');
        $data   = $byWeek->map(function ($items, $week) {
            $present = $items->where('status', 'present')->sum('cnt');
            $total   = $items->sum('cnt');
            return [
                'week'       => $week,
                'present'    => (int) $present,
                'total'      => (int) $total,
                'percentage' => $total > 0 ? round($present / $total * 100, 1) : 0.0,
            ];
        })->values()->all();

        return [
            'data' => $data,
            'meta' => [
                'class_id'    => $classId,
                'semester_id' => $semesterId,
                'weeks'       => $weeks,
            ],
        ];
    }

    // ── W6: At-Risk Students ──────────────────────────────────────────────────

    public function atRiskStudents(int $semesterId, ?float $kktp = null, ?User $scope = null): array
    {
        if ($scope !== null && ! $scope->isSchoolAdmin()) {
            $ids = $this->visibleClassIds($scope);

            if (empty($ids)) {
                return [
                    'data' => [],
                    'meta' => [
                        'semester_id'          => $semesterId,
                        'kktp'                 => $kktp ?? (float) config('floz.analytics.at_risk_grade_kktp', 70),
                        'attendance_threshold' => (float) config('floz.analytics.at_risk_attendance_threshold', 0.85) * 100,
                        'note'                 => 'Tidak ada kelas yang diampu.',
                        'empty_reason'         => 'no_assigned_classes',
                    ],
                ];
            }
        }

        // WARN-2: read from config (PLAN_CHECK requirement)
        $kktp                ??= (float) config('floz.analytics.at_risk_grade_kktp', 70);
        $attendanceThreshold   = (float) config('floz.analytics.at_risk_attendance_threshold', 0.85);

        $query = DB::table('report_cards')
            ->join('students', 'report_cards.student_id', '=', 'students.id')
            ->join('classes',  'report_cards.class_id',   '=', 'classes.id')
            ->where('report_cards.semester_id', $semesterId)
            ->where('report_cards.report_type', 'final')
            ->where('students.status', 'active')
            ->where('report_cards.average_score', '<', $kktp)
            ->selectRaw('
                report_cards.student_id,
                students.name as student_name,
                report_cards.class_id,
                classes.name as class_name,
                report_cards.average_score,
                report_cards.attendance_present,
                report_cards.attendance_sick,
                report_cards.attendance_permit,
                report_cards.attendance_absent
            ');

        if (isset($ids)) {
            $query->whereIn('report_cards.class_id', $ids);
        }

        $rows = $query->get();

        // WARN-1: empty state with meta note
        if ($rows->isEmpty()) {
            return [
                'data' => [],
                'meta' => [
                    'semester_id'          => $semesterId,
                    'kktp'                 => $kktp,
                    'attendance_threshold' => $attendanceThreshold * 100,
                    'note'                 => 'Belum ada rapor yang dipublikasikan untuk semester ini.',
                    'empty_reason'         => 'no_published_report_cards',
                ],
            ];
        }

        $data = $rows->filter(function ($r) use ($attendanceThreshold) {
            $total = $r->attendance_present + $r->attendance_sick
                   + $r->attendance_permit + $r->attendance_absent;
            if ($total === 0) {
                return false;
            }
            return ($r->attendance_present / $total) < $attendanceThreshold;
        })->map(function ($r) {
            $total = $r->attendance_present + $r->attendance_sick
                   + $r->attendance_permit + $r->attendance_absent;
            return [
                'student_id'   => $r->student_id,
                'student_name' => $r->student_name,
                'class_id'     => $r->class_id,
                'class_name'   => $r->class_name,
                'avg_score'    => (float) $r->average_score,
                'attendance_%' => $total > 0
                    ? round($r->attendance_present / $total * 100, 1)
                    : 0.0,
            ];
        })->values()->all();

        return [
            'data' => $data,
            'meta' => [
                'semester_id'          => $semesterId,
                'kktp'                 => $kktp,
                'attendance_threshold' => $attendanceThreshold * 100,
            ],
        ];
    }

    // ── W7: Teacher Workload ──────────────────────────────────────────────────

    public function teacherWorkload(int $academicYearId, ?User $scope = null): array
    {
        if ($scope !== null && ! $scope->isSchoolAdmin()) {
            throw new AuthorizationException('Widget ini hanya tersedia untuk admin.');
        }

        $rows = DB::table('teaching_assignments as ta')
            ->join('teachers', 'ta.teacher_id', '=', 'teachers.id')
            ->leftJoin('schedules', 'schedules.teaching_assignment_id', '=', 'ta.id')
            ->where('ta.academic_year_id', $academicYearId)
            ->selectRaw('ta.teacher_id, teachers.name as teacher_name, COUNT(DISTINCT ta.id) as ta_count, COUNT(schedules.id) as weekly_sessions')
            ->groupBy('ta.teacher_id', 'teachers.name')
            ->orderBy('teachers.name')
            ->get();

        return [
            'data' => $rows->map(fn ($r) => [
                'teacher_id'      => $r->teacher_id,
                'teacher_name'    => $r->teacher_name,
                'ta_count'        => (int) $r->ta_count,
                'weekly_sessions' => (int) $r->weekly_sessions,
            ])->all(),
            'meta' => [
                'academic_year_id' => $academicYearId,
                'generated_at'     => now()->toIso8601String(),
            ],
        ];
    }
}
