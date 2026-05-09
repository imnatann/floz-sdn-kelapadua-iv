<?php

use App\Models\AcademicYear;
use App\Models\Attendance;
use App\Models\Grade;
use App\Models\ReportCard;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use App\Services\AnalyticsService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

// ── Helpers ───────────────────────────────────────────────────────────────────

function makeAdminUser(): User
{
    return User::factory()->create(['role' => 'school_admin']);
}

function makeTeacherWithHomeroom(SchoolClass $class): array
{
    $teacher = Teacher::factory()->create();
    $user    = User::where('email', $teacher->email)->firstOrFail();
    $class->update(['homeroom_teacher_id' => $teacher->id]);
    return [$user, $teacher];
}

function makeRegularTeacherWithTA(SchoolClass $class, AcademicYear $ay): array
{
    $teacher  = Teacher::factory()->create();
    $user     = User::where('email', $teacher->email)->firstOrFail();
    $subject  = \App\Models\Subject::factory()->create();
    TeachingAssignment::factory()->create([
        'teacher_id'       => $teacher->id,
        'class_id'         => $class->id,
        'subject_id'       => $subject->id,
        'academic_year_id' => $ay->id,
    ]);
    return [$user, $teacher];
}

function makeOrphanTeacherUser(): User
{
    // A user with teacher role but NO Teacher record (null ->teacher)
    return User::factory()->create(['role' => 'teacher']);
}

// ── W1: todaysAttendance ──────────────────────────────────────────────────────

it('todaysAttendance returns all classes when scope is null', function () {
    $classA = SchoolClass::factory()->create();
    $classB = SchoolClass::factory()->create();
    $sem    = Semester::factory()->create(['is_active' => true]);

    foreach ([$classA, $classB] as $class) {
        $student = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);
        Attendance::factory()->create([
            'student_id'  => $student->id,
            'class_id'    => $class->id,
            'semester_id' => $sem->id,
            'date'        => today()->toDateString(),
            'status'      => 'present',
        ]);
    }

    $result = app(AnalyticsService::class)->todaysAttendance(null);
    expect($result['data']['present'])->toBe(2);
});

it('todaysAttendance filters to homeroom class when wali kelas scope given', function () {
    $ay     = AcademicYear::factory()->create(['is_active' => true]);
    $sem    = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $classA = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $classB = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);

    [$user] = makeTeacherWithHomeroom($classA);

    // classA: 2 present, classB: 1 present
    foreach (range(1, 2) as $_) {
        $s = Student::factory()->create(['class_id' => $classA->id, 'status' => 'active']);
        Attendance::factory()->create([
            'student_id'  => $s->id, 'class_id' => $classA->id,
            'semester_id' => $sem->id, 'date' => today()->toDateString(), 'status' => 'present',
        ]);
    }
    $sb = Student::factory()->create(['class_id' => $classB->id, 'status' => 'active']);
    Attendance::factory()->create([
        'student_id'  => $sb->id, 'class_id' => $classB->id,
        'semester_id' => $sem->id, 'date' => today()->toDateString(), 'status' => 'present',
    ]);

    $result = app(AnalyticsService::class)->todaysAttendance($user->fresh());
    expect($result['data']['present'])->toBe(2); // only classA
});

it('todaysAttendance filters to TA classes when regular teacher scope given', function () {
    $ay     = AcademicYear::factory()->create(['is_active' => true]);
    $sem    = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $classA = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $classB = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);

    [$user] = makeRegularTeacherWithTA($classA, $ay);

    // classA: 1 present, classB: 3 present
    $sa = Student::factory()->create(['class_id' => $classA->id, 'status' => 'active']);
    Attendance::factory()->create([
        'student_id'  => $sa->id, 'class_id' => $classA->id,
        'semester_id' => $sem->id, 'date' => today()->toDateString(), 'status' => 'present',
    ]);
    foreach (range(1, 3) as $_) {
        $sb = Student::factory()->create(['class_id' => $classB->id, 'status' => 'active']);
        Attendance::factory()->create([
            'student_id'  => $sb->id, 'class_id' => $classB->id,
            'semester_id' => $sem->id, 'date' => today()->toDateString(), 'status' => 'present',
        ]);
    }

    $result = app(AnalyticsService::class)->todaysAttendance($user->fresh());
    expect($result['data']['present'])->toBe(1); // only classA (TA)
});

it('todaysAttendance returns empty state for teacher with no homeroom and no TAs', function () {
    $orphan = makeOrphanTeacherUser();

    $result = app(AnalyticsService::class)->todaysAttendance($orphan);

    expect($result['data']['present'])->toBe(0)
        ->and($result['meta'])->toHaveKey('note');
});

// ── W2: classesMissingAttendance (admin-only guard) ───────────────────────────

it('classesMissingAttendance with admin scope (null) returns school-wide missing list', function () {
    $ay     = AcademicYear::factory()->create(['is_active' => true]);
    $teacher = Teacher::factory()->create();
    $class  = SchoolClass::factory()->create([
        'academic_year_id'    => $ay->id,
        'homeroom_teacher_id' => $teacher->id,
    ]);

    $result = app(AnalyticsService::class)->classesMissingAttendance(null);

    expect($result)->toHaveKey('data')
        ->and($result['data'])->toBeArray();
});

it('classesMissingAttendance throws AuthorizationException when called with teacher scope', function () {
    $teacher = Teacher::factory()->create();
    $user    = User::where('email', $teacher->email)->firstOrFail();

    expect(fn () => app(AnalyticsService::class)->classesMissingAttendance($user))
        ->toThrow(AuthorizationException::class);
});

// ── W7: teacherWorkload (admin-only guard) ────────────────────────────────────

it('teacherWorkload with admin scope (null) returns all teachers', function () {
    $ay = AcademicYear::factory()->create(['is_active' => true]);

    $result = app(AnalyticsService::class)->teacherWorkload($ay->id, null);

    expect($result)->toHaveKey('data')
        ->and($result['data'])->toBeArray();
});

it('teacherWorkload throws AuthorizationException when called with teacher scope', function () {
    $ay      = AcademicYear::factory()->create(['is_active' => true]);
    $teacher = Teacher::factory()->create();
    $user    = User::where('email', $teacher->email)->firstOrFail();

    expect(fn () => app(AnalyticsService::class)->teacherWorkload($ay->id, $user))
        ->toThrow(AuthorizationException::class);
});

// ── W3: classAvgComparison ────────────────────────────────────────────────────

it('classAvgComparison returns all classes when scope is null', function () {
    $ay     = AcademicYear::factory()->create(['is_active' => true]);
    $sem    = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $classA = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $classB = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);

    foreach ([$classA, $classB] as $class) {
        $student = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);
        ReportCard::factory()->create([
            'student_id'    => $student->id, 'class_id' => $class->id,
            'semester_id'   => $sem->id,     'report_type' => 'final',
            'average_score' => 80,
        ]);
    }

    $result = app(AnalyticsService::class)->classAvgComparison($sem->id, null);
    expect(count($result['data']))->toBe(2);
});

it('classAvgComparison returns only homeroom class for wali kelas', function () {
    $ay     = AcademicYear::factory()->create(['is_active' => true]);
    $sem    = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $classA = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $classB = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);

    [$user] = makeTeacherWithHomeroom($classA);

    foreach ([$classA, $classB] as $class) {
        $student = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);
        ReportCard::factory()->create([
            'student_id'    => $student->id, 'class_id' => $class->id,
            'semester_id'   => $sem->id,     'report_type' => 'final',
            'average_score' => 80,
        ]);
    }

    $result = app(AnalyticsService::class)->classAvgComparison($sem->id, $user->fresh());
    expect(count($result['data']))->toBe(1)
        ->and($result['data'][0]['class_id'])->toBe($classA->id);
});

it('classAvgComparison returns union of TA classes for regular teacher', function () {
    $ay     = AcademicYear::factory()->create(['is_active' => true]);
    $sem    = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $classA = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $classB = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $classC = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);

    [$user] = makeRegularTeacherWithTA($classA, $ay);

    foreach ([$classA, $classB, $classC] as $class) {
        $student = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);
        ReportCard::factory()->create([
            'student_id'    => $student->id, 'class_id' => $class->id,
            'semester_id'   => $sem->id,     'report_type' => 'final',
            'average_score' => 80,
        ]);
    }

    $result = app(AnalyticsService::class)->classAvgComparison($sem->id, $user->fresh());
    expect(count($result['data']))->toBe(1)
        ->and($result['data'][0]['class_id'])->toBe($classA->id);
});

it('classAvgComparison returns empty with note for teacher with zero scope', function () {
    $sem    = Semester::factory()->create(['is_active' => true]);
    $orphan = makeOrphanTeacherUser();

    $result = app(AnalyticsService::class)->classAvgComparison($sem->id, $orphan);

    expect($result['data'])->toBeEmpty()
        ->and($result['meta']['empty_reason'])->toBe('no_assigned_classes');
});

// ── W4: subjectGradeDistribution ─────────────────────────────────────────────

it('subjectGradeDistribution with admin returns full class data', function () {
    $ay      = AcademicYear::factory()->create(['is_active' => true]);
    $sem     = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $class   = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $subject = Subject::factory()->create();
    $student = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);
    Grade::factory()->create([
        'student_id' => $student->id, 'class_id' => $class->id,
        'subject_id' => $subject->id, 'semester_id' => $sem->id, 'predicate' => 'A',
    ]);

    $result = app(AnalyticsService::class)->subjectGradeDistribution($class->id, $sem->id, null);
    expect($result['data'])->not->toBeEmpty();
});

it('subjectGradeDistribution with wali kelas allows their class', function () {
    $ay      = AcademicYear::factory()->create(['is_active' => true]);
    $sem     = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $class   = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $subject = Subject::factory()->create();
    $student = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);

    [$user] = makeTeacherWithHomeroom($class);

    Grade::factory()->create([
        'student_id' => $student->id, 'class_id' => $class->id,
        'subject_id' => $subject->id, 'semester_id' => $sem->id, 'predicate' => 'B',
    ]);

    $result = app(AnalyticsService::class)->subjectGradeDistribution($class->id, $sem->id, $user->fresh());
    expect($result['data'])->not->toBeEmpty();
});

it('subjectGradeDistribution with regular teacher blocks class not in TA', function () {
    $ay      = AcademicYear::factory()->create(['is_active' => true]);
    $sem     = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $classA  = SchoolClass::factory()->create(['academic_year_id' => $ay->id]); // teacher's TA class
    $classB  = SchoolClass::factory()->create(['academic_year_id' => $ay->id]); // foreign class

    [$user] = makeRegularTeacherWithTA($classA, $ay);

    $result = app(AnalyticsService::class)->subjectGradeDistribution($classB->id, $sem->id, $user->fresh());
    expect($result['data'])->toBeEmpty()
        ->and($result['meta']['empty_reason'])->toBe('access_denied');
});

// ── W5: attendanceTrend ───────────────────────────────────────────────────────

it('attendanceTrend with admin returns data for any class', function () {
    $ay    = AcademicYear::factory()->create(['is_active' => true]);
    $sem   = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $class = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);

    $result = app(AnalyticsService::class)->attendanceTrend($class->id, $sem->id, 12, null);
    expect($result)->toHaveKey('data');
});

it('attendanceTrend with wali kelas returns their class trend', function () {
    $ay    = AcademicYear::factory()->create(['is_active' => true]);
    $sem   = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $class = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);

    [$user] = makeTeacherWithHomeroom($class);

    $result = app(AnalyticsService::class)->attendanceTrend($class->id, $sem->id, 12, $user->fresh());
    expect($result)->toHaveKey('data');
});

it('attendanceTrend with regular teacher blocks class not in TA scope', function () {
    $ay     = AcademicYear::factory()->create(['is_active' => true]);
    $sem    = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $classA = SchoolClass::factory()->create(['academic_year_id' => $ay->id]); // teacher's TA
    $classB = SchoolClass::factory()->create(['academic_year_id' => $ay->id]); // foreign

    [$user] = makeRegularTeacherWithTA($classA, $ay);

    $result = app(AnalyticsService::class)->attendanceTrend($classB->id, $sem->id, 12, $user->fresh());
    expect($result['data'])->toBeEmpty()
        ->and($result['meta']['empty_reason'])->toBe('access_denied');
});

// ── W6: atRiskStudents ────────────────────────────────────────────────────────

it('atRiskStudents with admin returns school-wide at-risk list', function () {
    $sem  = Semester::factory()->create(['is_active' => true]);

    $result = app(AnalyticsService::class)->atRiskStudents($sem->id, null, null);
    expect($result)->toHaveKey('data');
});

it('atRiskStudents with wali kelas returns only their class students', function () {
    $ay     = AcademicYear::factory()->create(['is_active' => true]);
    $sem    = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $classA = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $classB = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);

    [$user] = makeTeacherWithHomeroom($classA);

    // Create at-risk students in both classes
    foreach ([$classA, $classB] as $class) {
        $student = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);
        ReportCard::factory()->create([
            'student_id'           => $student->id, 'class_id' => $class->id,
            'semester_id'          => $sem->id,      'report_type' => 'final',
            'average_score'        => 50,
            'attendance_present'   => 5,
            'attendance_sick'      => 1,
            'attendance_permit'    => 1,
            'attendance_absent'    => 10,
        ]);
    }

    $result = app(AnalyticsService::class)->atRiskStudents($sem->id, null, $user->fresh());
    expect(count($result['data']))->toBe(1)
        ->and($result['data'][0]['class_id'])->toBe($classA->id);
});

it('atRiskStudents with regular teacher returns only TA-class students', function () {
    $ay     = AcademicYear::factory()->create(['is_active' => true]);
    $sem    = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $classA = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $classB = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);

    [$user] = makeRegularTeacherWithTA($classA, $ay);

    foreach ([$classA, $classB] as $class) {
        $student = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);
        ReportCard::factory()->create([
            'student_id'           => $student->id, 'class_id' => $class->id,
            'semester_id'          => $sem->id,      'report_type' => 'final',
            'average_score'        => 50,
            'attendance_present'   => 5,
            'attendance_sick'      => 1,
            'attendance_permit'    => 1,
            'attendance_absent'    => 10,
        ]);
    }

    $result = app(AnalyticsService::class)->atRiskStudents($sem->id, null, $user->fresh());
    expect(count($result['data']))->toBe(1)
        ->and($result['data'][0]['class_id'])->toBe($classA->id);
});

it('atRiskStudents with zero-scope teacher returns empty with note', function () {
    $sem    = Semester::factory()->create(['is_active' => true]);
    $orphan = makeOrphanTeacherUser();

    $result = app(AnalyticsService::class)->atRiskStudents($sem->id, null, $orphan);

    expect($result['data'])->toBeEmpty()
        ->and($result['meta']['empty_reason'])->toBe('no_assigned_classes');
});
