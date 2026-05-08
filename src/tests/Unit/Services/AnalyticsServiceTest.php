<?php

use App\Models\AcademicYear;
use App\Models\Attendance;
use App\Models\Grade;
use App\Models\ReportCard;
use App\Models\Schedule;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Services\AnalyticsService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

// ── todaysAttendance ─────────────────────────────────────────────────────────

it('todaysAttendance returns school-wide H/S/I/A counts for today', function () {
    $class    = SchoolClass::factory()->create();
    $sem      = Semester::factory()->create(['is_active' => true]);
    $students = Student::factory()->count(3)->create(['class_id' => $class->id, 'status' => 'active']);

    $statuses = ['present', 'sick', 'absent'];
    foreach ($students as $i => $s) {
        Attendance::factory()->create([
            'student_id'  => $s->id,
            'class_id'    => $class->id,
            'semester_id' => $sem->id,
            'date'        => today()->toDateString(),
            'status'      => $statuses[$i],
        ]);
    }

    $result = app(AnalyticsService::class)->todaysAttendance();

    expect($result['data']['present'])->toBe(1)
        ->and($result['data']['sick'])->toBe(1)
        ->and($result['data']['absent'])->toBe(1)
        ->and($result['data']['permit'])->toBe(0)
        ->and($result['data']['percentage'])->toBe(33.3) // 1/3 = 33.3
        ->and($result['meta'])->toHaveKey('generated_at');
});

// ── classesMissingAttendance ──────────────────────────────────────────────────

it('classesMissingAttendance returns classes with no attendance record today', function () {
    $ay      = AcademicYear::factory()->create(['is_active' => true]);
    $teacher = Teacher::factory()->create();
    $classA  = SchoolClass::factory()->create(['academic_year_id' => $ay->id, 'homeroom_teacher_id' => $teacher->id]);
    $classB  = SchoolClass::factory()->create(['academic_year_id' => $ay->id, 'homeroom_teacher_id' => $teacher->id]);
    $student = Student::factory()->create(['class_id' => $classA->id, 'status' => 'active']);

    // classA has attendance today; classB does not
    Attendance::factory()->create([
        'class_id'   => $classA->id,
        'student_id' => $student->id,
        'date'       => today()->toDateString(),
    ]);

    $result = app(AnalyticsService::class)->classesMissingAttendance();

    $missingIds = collect($result['data'])->pluck('class_id');
    expect($missingIds)->toContain($classB->id)
        ->and($missingIds)->not->toContain($classA->id);
});

// ── classAvgComparison ────────────────────────────────────────────────────────

it('classAvgComparison returns average_score per class for the semester', function () {
    $sem    = Semester::factory()->create();
    $classA = SchoolClass::factory()->create();
    $classB = SchoolClass::factory()->create();
    $sA     = Student::factory()->create(['class_id' => $classA->id]);
    $sB     = Student::factory()->create(['class_id' => $classB->id]);

    ReportCard::factory()->create([
        'student_id'    => $sA->id,
        'class_id'      => $classA->id,
        'semester_id'   => $sem->id,
        'report_type'   => 'final',
        'average_score' => 85.0,
    ]);
    ReportCard::factory()->create([
        'student_id'    => $sB->id,
        'class_id'      => $classB->id,
        'semester_id'   => $sem->id,
        'report_type'   => 'final',
        'average_score' => 72.0,
    ]);

    $result = app(AnalyticsService::class)->classAvgComparison($sem->id);

    $byClass = collect($result['data'])->keyBy('class_id');
    expect($byClass[$classA->id]['avg'])->toBe(85.0)
        ->and($byClass[$classB->id]['avg'])->toBe(72.0);
});

it('classAvgComparison returns empty data with meta note when no report_cards exist', function () {
    $sem    = Semester::factory()->create();
    $result = app(AnalyticsService::class)->classAvgComparison($sem->id);

    expect($result['data'])->toBeEmpty()
        ->and($result['meta']['note'])->not->toBeNull()
        ->and($result['meta']['empty_reason'])->toBe('no_published_report_cards');
});

// ── subjectGradeDistribution ──────────────────────────────────────────────────

it('subjectGradeDistribution returns A/B/C/D counts per subject for the class', function () {
    $class    = SchoolClass::factory()->create();
    $sem      = Semester::factory()->create();
    $subj     = Subject::factory()->create(['status' => 'active']);
    $students = Student::factory()->count(4)->create(['class_id' => $class->id]);

    $predicates = ['A', 'B', 'C', 'D'];
    foreach ($students as $i => $s) {
        Grade::factory()->create([
            'student_id'  => $s->id,
            'class_id'    => $class->id,
            'semester_id' => $sem->id,
            'subject_id'  => $subj->id,
            'predicate'   => $predicates[$i],
        ]);
    }

    $result = app(AnalyticsService::class)->subjectGradeDistribution($class->id, $sem->id);

    $row = collect($result['data'])->firstWhere('subject_id', $subj->id);
    expect($row['counts']['A'])->toBe(1)
        ->and($row['counts']['D'])->toBe(1);
});

// ── attendanceTrend ───────────────────────────────────────────────────────────

it('attendanceTrend returns weekly present-% for last N weeks for a class', function () {
    $class = SchoolClass::factory()->create();
    $sem   = Semester::factory()->create(['is_active' => true]);
    $s     = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);

    // 2 records this week: 1 present, 1 absent
    Attendance::factory()->create([
        'class_id'   => $class->id,
        'student_id' => $s->id,
        'semester_id' => $sem->id,
        'date'       => now()->startOfWeek()->toDateString(),
        'status'     => 'present',
    ]);
    Attendance::factory()->create([
        'class_id'   => $class->id,
        'student_id' => $s->id,
        'semester_id' => $sem->id,
        'date'       => now()->startOfWeek()->addDay()->toDateString(),
        'status'     => 'absent',
    ]);

    $result = app(AnalyticsService::class)->attendanceTrend($class->id, $sem->id, 4);

    $thisWeek = collect($result['data'])->last();
    expect($thisWeek['percentage'])->toBe(50.0);
});

it('attendanceTrend returns empty data when class has no attendance in range', function () {
    $class  = SchoolClass::factory()->create();
    $sem    = Semester::factory()->create(['is_active' => true]);
    $result = app(AnalyticsService::class)->attendanceTrend($class->id, $sem->id, 4);

    expect($result['data'])->toBeEmpty();
});

// ── atRiskStudents ────────────────────────────────────────────────────────────

it('atRiskStudents returns students below KKTP and below 85% attendance', function () {
    config(['floz.analytics.at_risk_grade_kktp' => 70]);
    $sem   = Semester::factory()->create(['is_active' => true]);
    $class = SchoolClass::factory()->create();

    $atRisk = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);
    $safe   = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);

    // at-risk: avg_score < 70 AND attendance < 85%
    ReportCard::factory()->create([
        'student_id'          => $atRisk->id,
        'class_id'            => $class->id,
        'semester_id'         => $sem->id,
        'report_type'         => 'final',
        'average_score'       => 60.0,
        'attendance_present'  => 10,
        'attendance_sick'     => 0,
        'attendance_permit'   => 0,
        'attendance_absent'   => 5,
    ]);
    // safe: avg_score >= 70
    ReportCard::factory()->create([
        'student_id'          => $safe->id,
        'class_id'            => $class->id,
        'semester_id'         => $sem->id,
        'report_type'         => 'final',
        'average_score'       => 80.0,
        'attendance_present'  => 14,
        'attendance_sick'     => 0,
        'attendance_permit'   => 0,
        'attendance_absent'   => 1,
    ]);

    $result = app(AnalyticsService::class)->atRiskStudents($sem->id);

    $ids = collect($result['data'])->pluck('student_id');
    expect($ids)->toContain($atRisk->id)
        ->and($ids)->not->toContain($safe->id);
});

it('atRiskStudents returns empty data with meta note when no report_cards exist', function () {
    $sem    = Semester::factory()->create(['is_active' => true]);
    $result = app(AnalyticsService::class)->atRiskStudents($sem->id);

    expect($result['data'])->toBeEmpty()
        ->and($result['meta']['note'])->not->toBeNull()
        ->and($result['meta']['empty_reason'])->toBe('no_published_report_cards');
});

// ── teacherWorkload ───────────────────────────────────────────────────────────

it('teacherWorkload returns teacher name, TA count, and weekly sessions', function () {
    $ay      = AcademicYear::factory()->create(['is_active' => true]);
    $teacher = Teacher::factory()->create();
    $class   = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $subj    = Subject::factory()->create();

    TeachingAssignment::factory()->create([
        'teacher_id'       => $teacher->id,
        'class_id'         => $class->id,
        'subject_id'       => $subj->id,
        'academic_year_id' => $ay->id,
    ]);

    $ta = TeachingAssignment::where('teacher_id', $teacher->id)->first();
    Schedule::factory()->count(2)->create(['teaching_assignment_id' => $ta->id]);

    $result = app(AnalyticsService::class)->teacherWorkload($ay->id);

    $row = collect($result['data'])->firstWhere('teacher_id', $teacher->id);
    expect($row['ta_count'])->toBe(1)
        ->and($row['weekly_sessions'])->toBe(2);
});
