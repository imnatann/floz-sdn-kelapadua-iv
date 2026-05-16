<?php

namespace App\Services;

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\StudentMutation;
use App\Models\User;
use App\Models\YearTransitionLog;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class YearTransitionService
{
    /**
     * Promotion destination grade map (SD: grades 1-6).
     * Grade 6 has no next grade — handled separately (graduate).
     */
    private const GRADE_STEP = [1 => 2, 2 => 3, 3 => 4, 4 => 5, 5 => 6];

    /**
     * Compute a stable SHA-256 fingerprint of the full mutation plan.
     *
     * Canonical form: mutations sorted by student_id + summary + source/target AY IDs.
     * Returns a 64-char lowercase hex string.
     */
    public function computePlanHash(array $plan, int $sourceAyId, int $targetAyId): string
    {
        // Sort mutations by student_id for canonical ordering
        $mutations = $plan['mutations'];
        usort($mutations, fn ($a, $b) => $a['student_id'] <=> $b['student_id']);

        $canonical = json_encode([
            'source_ay_id' => $sourceAyId,
            'target_ay_id' => $targetAyId,
            'summary'      => $plan['summary'],
            'mutations'    => $mutations,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

        return hash('sha256', $canonical);
    }

    /**
     * Build full mutation plan without writing to DB.
     *
     * BLOCK-4: Uses composite key (grade_level + section letter) to resolve target class.
     * EDGE: Orphan students (class_id = null) are excluded via the JOIN on classes table.
     */
    public function previewTransition(int $sourceAyId, int $targetAyId, array $overrides): array
    {
        $sourceAy = AcademicYear::findOrFail($sourceAyId);
        $targetAy = AcademicYear::findOrFail($targetAyId);

        // Build new-class list: mirror source classes (not persisted)
        $sourceClasses = SchoolClass::where('academic_year_id', $sourceAyId)->get();
        $newClasses = $sourceClasses->map(fn ($c) => [
            'source_class_id'     => $c->id,
            'name'                => $c->name,
            'grade_level'         => $c->grade_level,
            'homeroom_teacher_id' => null,
        ])->toArray();

        // Active students in source AY (only those WITH a class — no orphans)
        // Orphans (class_id = null) are excluded by the whereIn constraint.
        $students = Student::whereIn('class_id', $sourceClasses->pluck('id'))
            ->where('status', 'active')
            ->with([
                'class',
                'mutations' => fn ($q) => $q->where('type', 'transfer_in'),
            ])
            ->get();

        // Non-active students for exclusion count
        $excludedStudents = Student::whereIn('class_id', $sourceClasses->pluck('id'))
            ->whereIn('status', ['transferred', 'dropout'])
            ->count();

        $mutations = [];
        $summary   = ['promoted' => 0, 'graduated' => 0, 'retained' => 0, 'excluded' => 0];

        foreach ($students as $student) {
            $grade    = $student->class->grade_level;
            $override = $overrides[$student->id] ?? null;
            $action   = $override['action'] ?? ($grade === 6 ? 'graduate' : 'promote');
            $reason   = $override['reason'] ?? null;
            $warnings = [];

            // Flag mid-year transfer-in students
            if ($student->mutations->isNotEmpty()) {
                $warnings[] = 'transfer_in mid-year — konfirmasi manual diperlukan';
            }

            // BLOCK-4: Determine target class name using section-letter matching
            // e.g. "Kelas 4A" → nextGrade=5 → "Kelas 5A" (replace grade digit in class name)
            $toClassName = null;
            if ($action === 'promote') {
                $nextGrade = self::GRADE_STEP[$grade] ?? null;
                if ($nextGrade) {
                    // Replace the grade number in class name with next grade.
                    // e.g. "Kelas 4A" → "Kelas 5A", "Kelas 4B" → "Kelas 5B"
                    // Use (?<![0-9]) and (?![0-9]) to avoid matching sub-numbers,
                    // but allow the digit to be followed by a section letter.
                    $toClassName = preg_replace(
                        '/(?<![0-9])' . preg_quote((string)$grade, '/') . '(?![0-9])/',
                        (string)$nextGrade,
                        $student->class->name
                    );
                }
            } elseif ($action === 'retain') {
                // Same class name (same grade, same section) in new AY
                $toClassName = $student->class->name;
            }
            // graduate / transfer_out / dropout → to_class = null

            $mutations[] = [
                'student_id'       => $student->id,
                'student_name'     => $student->name,
                'nis'              => $student->nis,
                'from_class_id'    => $student->class_id,
                'from_class_name'  => $student->class->name,
                'from_grade_level' => $grade,
                'action'           => $action,
                'to_class_id'      => null, // resolved during execute against newly-created classes
                'to_class_name'    => $toClassName,
                'reason'           => $reason,
                'warnings'         => $warnings,
                'source_ay_id'     => $sourceAyId,
                'target_ay_id'     => $targetAyId,
            ];

            $summary[match ($action) {
                'promote'                  => 'promoted',
                'graduate'                 => 'graduated',
                'retain'                   => 'retained',
                'transfer_out', 'dropout'  => 'excluded',
                default                    => 'excluded',
            }]++;
        }

        $summary['excluded'] += $excludedStudents;

        // Annotate each new class with estimated student count (students being promoted/retained into it)
        $studentCountByTargetName = [];
        foreach ($mutations as $m) {
            if ($m['to_class_name'] !== null) {
                $studentCountByTargetName[$m['to_class_name']] = ($studentCountByTargetName[$m['to_class_name']] ?? 0) + 1;
            }
        }
        $newClasses = array_map(function ($c) use ($studentCountByTargetName) {
            $c['student_count'] = $studentCountByTargetName[$c['name']] ?? 0;
            return $c;
        }, $newClasses);

        $plan = [
            'source_ay'   => $sourceAy->toArray(),
            'target_ay'   => $targetAy->toArray(),
            'new_classes' => $newClasses,
            'mutations'   => $mutations,
            'summary'     => $summary,
        ];

        return $plan;
    }

    /**
     * Execute transition atomically. Returns audit log row.
     *
     * BLOCK-1: Guard against double-execute (target AY already has classes).
     * BLOCK-5: Cache lock prevents concurrent execution.
     * BLOCK-3: previewTransition called INSIDE transaction; lockForUpdate on students.
     *
     * @throws \RuntimeException on any partial failure (triggers rollback)
     */
    public function executeTransition(
        int $sourceAyId,
        int $targetAyId,
        array $overrides,
        User $admin
    ): YearTransitionLog {
        // PREREQ: Source AY Sem 2 must be active (naik kelas only at end of school year)
        $sourceSem2 = \App\Models\Semester::where('academic_year_id', $sourceAyId)
            ->where('semester_number', 2)
            ->where('is_active', true)
            ->first();
        if (! $sourceSem2) {
            throw new \RuntimeException('Kenaikan kelas hanya bisa dieksekusi saat Sem 2 dari tahun ajaran sumber sedang aktif.');
        }

        // BLOCK-5: Acquire advisory lock to prevent concurrent execution
        $lockKey = "year_transition_{$sourceAyId}_{$targetAyId}";
        $lock    = Cache::lock($lockKey, 120);

        if (! $lock->get()) {
            throw new \RuntimeException('Transisi sedang berjalan. Tunggu beberapa detik.');
        }

        try {
            return DB::transaction(function () use ($sourceAyId, $targetAyId, $overrides, $admin) {
                // BLOCK-1: Guard against double-execute
                if (SchoolClass::where('academic_year_id', $targetAyId)->exists()) {
                    throw new \RuntimeException('Target tahun ajaran sudah memiliki kelas. Transisi mungkin sudah dijalankan sebelumnya. Periksa riwayat transisi.');
                }

                // BLOCK-3: Run preview INSIDE transaction for fresh snapshot
                $plan = $this->previewTransition($sourceAyId, $targetAyId, $overrides);

                // BLOCK-3: Lock student rows for duration of transaction (prevent concurrent edits)
                $studentIds = collect($plan['mutations'])->pluck('student_id')->filter()->values();
                if ($studentIds->isNotEmpty()) {
                    Student::whereIn('id', $studentIds)->lockForUpdate()->get();
                }

                // 1. Create new-AY classes
                // Key: source_class_id → new SchoolClass (for mutation routing)
                $classMap = [];
                foreach ($plan['new_classes'] as $classDef) {
                    $newClass = SchoolClass::create([
                        'name'                => $classDef['name'],
                        'grade_level'         => $classDef['grade_level'],
                        'academic_year_id'    => $targetAyId,
                        'homeroom_teacher_id' => null,
                        'max_students'        => 40,
                        'status'              => 'active',
                    ]);
                    $classMap[$classDef['source_class_id']] = $newClass;
                }

                // 2. Apply mutations
                foreach ($plan['mutations'] as $mutation) {
                    $this->applyMutation($mutation, $classMap);
                }

                // 3. Move active academic period to target AY and Semester 1.
                $this->activateTargetAcademicPeriod($targetAyId);

                // 4. Write audit log (WARN-2: store plain arrays, not Eloquent models)
                $log = YearTransitionLog::create([
                    'executed_by'             => $admin->id,
                    'source_academic_year_id' => $sourceAyId,
                    'target_academic_year_id' => $targetAyId,
                    'executed_at'             => now(),
                    'promoted_count'          => $plan['summary']['promoted'],
                    'graduated_count'         => $plan['summary']['graduated'],
                    'retained_count'          => $plan['summary']['retained'],
                    'excluded_count'          => $plan['summary']['excluded'],
                    'plan_snapshot'           => $plan, // already plain arrays (WARN-2 fixed)
                    'ip_address'              => request()->ip(),
                ]);

                return $log;
            });
        } finally {
            $lock->release();
        }
    }

    private function activateTargetAcademicPeriod(int $targetAyId): void
    {
        AcademicYear::query()->update(['is_active' => false]);
        AcademicYear::whereKey($targetAyId)->update(['is_active' => true]);

        $targetSem1 = Semester::where('academic_year_id', $targetAyId)
            ->where('semester_number', 1)
            ->first();

        if ($targetSem1) {
            Semester::query()->update(['is_active' => false]);
            $targetSem1->update(['is_active' => true]);
        }
    }

    /**
     * Apply a single student mutation. Overridable for testing.
     */
    protected function applyMutation(array $mutation, array $classMap): void
    {
        $student = Student::findOrFail($mutation['student_id']);

        match ($mutation['action']) {
            'promote'                 => $this->applyPromotion($student, $mutation, $classMap),
            'graduate'                => $this->applyGraduation($student, $mutation),
            'retain'                  => $this->applyRetention($student, $mutation, $classMap),
            'transfer_out', 'dropout' => $this->applyExit($student, $mutation),
            default                   => null,
        };
    }

    private function applyPromotion(Student $student, array $mutation, array $classMap): void
    {
        $targetGrade = self::GRADE_STEP[$mutation['from_grade_level']] ?? null;
        if (! $targetGrade) {
            throw new \RuntimeException(
                "No grade step for grade {$mutation['from_grade_level']} (student ID: {$student->id})"
            );
        }

        // BLOCK-4: Use composite key — match by to_class_name (already has correct grade digit from preview)
        // e.g. preview set to_class_name="Kelas 5A" for a 4A student → find new class named "Kelas 5A"
        $toClassName = $mutation['to_class_name'];
        $newClass = collect($classMap)->first(
            fn ($c) => $c->grade_level === $targetGrade && $c->name === $toClassName
        );

        // Fallback: if name doesn't match exactly (edge case), find by section letter
        if (! $newClass && $toClassName) {
            // Extract section letter from source class name (e.g. "Kelas 4A" → "A")
            preg_match('/([A-Z])$/', $mutation['from_class_name'], $sectionMatch);
            $section = $sectionMatch[1] ?? null;

            if ($section) {
                $newClass = collect($classMap)->first(
                    fn ($c) => $c->grade_level === $targetGrade && str_ends_with($c->name, $section)
                );
            }
        }

        if (! $newClass) {
            throw new \RuntimeException(
                "Target class not found for promotion: student ID {$student->id}, " .
                "source class '{$mutation['from_class_name']}', target grade {$targetGrade}. " .
                "Expected target class name: '{$toClassName}'."
            );
        }

        $student->update(['class_id' => $newClass->id]);
        StudentMutation::create([
            'student_id'    => $student->id,
            'type'          => 'promotion',
            'from_class_id' => $mutation['from_class_id'],
            'to_class_id'   => $newClass->id,
            'date'          => now()->toDateString(),
            'reason'        => $mutation['reason'],
        ]);
        $this->writeTransitionEnrollment(
            studentId: $student->id,
            sourceAcademicYearId: $mutation['source_ay_id'] ?? null,
            targetAcademicYearId: $mutation['target_ay_id'] ?? null,
            targetClassId: $newClass->id,
            sourceStatus: StudentClassEnrollment::STATUS_PROMOTED_OUT,
        );
    }

    private function applyGraduation(Student $student, array $mutation): void
    {
        // EDGE (BLOCK-2 note): class_id IS nullable per migration check in plan.
        // Students graduating have class_id set to null and status = 'graduated'.
        $student->update(['class_id' => null, 'status' => 'graduated']);
        StudentMutation::create([
            'student_id'    => $student->id,
            'type'          => 'graduated',
            'from_class_id' => $mutation['from_class_id'],
            'to_class_id'   => null,
            'date'          => now()->toDateString(),
            'reason'        => $mutation['reason'],
        ]);
        $this->writeTransitionEnrollment(
            studentId: $student->id,
            sourceAcademicYearId: $mutation['source_ay_id'] ?? null,
            targetAcademicYearId: null,
            targetClassId: null,
            sourceStatus: StudentClassEnrollment::STATUS_GRADUATED,
        );
    }

    private function applyRetention(Student $student, array $mutation, array $classMap): void
    {
        // Same grade in new AY, same section letter
        $toClassName = $mutation['to_class_name']; // same as source class name (preview sets this)
        $newClass    = collect($classMap)->first(
            fn ($c) => $c->grade_level === $mutation['from_grade_level'] && $c->name === $toClassName
        );

        // Fallback by section letter
        if (! $newClass) {
            preg_match('/([A-Z])$/', $mutation['from_class_name'], $sectionMatch);
            $section = $sectionMatch[1] ?? null;
            if ($section) {
                $newClass = collect($classMap)->first(
                    fn ($c) => $c->grade_level === $mutation['from_grade_level'] && str_ends_with($c->name, $section)
                );
            }
        }

        // Last resort: first class of same grade
        if (! $newClass) {
            $newClass = collect($classMap)->first(
                fn ($c) => $c->grade_level === $mutation['from_grade_level']
            );
        }

        if (! $newClass) {
            throw new \RuntimeException(
                "Retention target class not found for grade {$mutation['from_grade_level']} " .
                "(student ID: {$student->id})"
            );
        }

        $student->update(['class_id' => $newClass->id]);
        StudentMutation::create([
            'student_id'    => $student->id,
            'type'          => 'retention',
            'from_class_id' => $mutation['from_class_id'],
            'to_class_id'   => $newClass->id,
            'date'          => now()->toDateString(),
            'reason'        => $mutation['reason'],
        ]);
        $this->writeTransitionEnrollment(
            studentId: $student->id,
            sourceAcademicYearId: $mutation['source_ay_id'] ?? null,
            targetAcademicYearId: $mutation['target_ay_id'] ?? null,
            targetClassId: $newClass->id,
            sourceStatus: StudentClassEnrollment::STATUS_RETAINED_OUT,
        );
    }

    private function applyExit(Student $student, array $mutation): void
    {
        // WARN-6: Attendance rows (class_id FK) are unaffected — they hold their own class_id.
        // Only the student's own class_id is set to null here.
        $newStatus = $mutation['action'] === 'dropout' ? 'dropout' : 'transferred';
        $student->update(['class_id' => null, 'status' => $newStatus]);
        StudentMutation::create([
            'student_id'    => $student->id,
            'type'          => $mutation['action'] === 'dropout' ? 'dropout' : 'transfer_out',
            'from_class_id' => $mutation['from_class_id'],
            'to_class_id'   => null,
            'date'          => now()->toDateString(),
            'reason'        => $mutation['reason'],
        ]);
        $exitStatus = $mutation['action'] === 'dropout'
            ? StudentClassEnrollment::STATUS_DROPPED_OUT
            : StudentClassEnrollment::STATUS_TRANSFERRED_OUT;
        $this->writeTransitionEnrollment(
            studentId: $student->id,
            sourceAcademicYearId: $mutation['source_ay_id'] ?? null,
            targetAcademicYearId: null,
            targetClassId: null,
            sourceStatus: $exitStatus,
        );
    }

    /**
     * After year transition mutation is applied, close the source-AY terminal-semester
     * enrollment and (if applicable) open a new enrollment in target AY Sem Ganjil.
     */
    private function writeTransitionEnrollment(
        int $studentId,
        ?int $sourceAcademicYearId,
        ?int $targetAcademicYearId,
        ?int $targetClassId,
        string $sourceStatus,
    ): void {
        $sync = app(StudentEnrollmentSync::class);

        if ($sourceAcademicYearId) {
            $sync->closeLatestEnrollmentInAcademicYear(
                $studentId,
                $sourceAcademicYearId,
                $sourceStatus,
                'Year transition',
            );
        }

        if ($targetAcademicYearId && $targetClassId) {
            $targetSem1 = Semester::where('academic_year_id', $targetAcademicYearId)
                ->where('semester_number', 1)
                ->first();
            if ($targetSem1) {
                $sync->writeEnrollment(
                    studentId: $studentId,
                    semesterId: $targetSem1->id,
                    classId: $targetClassId,
                    status: StudentClassEnrollment::STATUS_ACTIVE,
                );
            }
        }
    }

    /**
     * Phase 7.1 — not implemented. Placeholder for undo UI.
     */
    public function restoreFromLog(YearTransitionLog $log, User $admin): void
    {
        throw new \RuntimeException(
            'Undo not implemented. Restore manually from plan_snapshot in YearTransitionLog #' . $log->id
        );
    }
}
