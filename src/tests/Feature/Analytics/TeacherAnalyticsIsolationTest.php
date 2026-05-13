<?php

use App\Models\AcademicYear;
use App\Models\ReportCard;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

// ── Helpers ───────────────────────────────────────────────────────────────────

function isolationAdmin(): User
{
    return User::factory()->create(['role' => 'school_admin']);
}

function teacherUserWithHomeroom(SchoolClass $class): User
{
    $teacher = Teacher::factory()->create();
    $user    = User::where('email', $teacher->email)->firstOrFail();
    $class->update(['homeroom_teacher_id' => $teacher->id]);
    return $user;
}

function teacherUserWithTA(SchoolClass $class, AcademicYear $ay): User
{
    $teacher = Teacher::factory()->create();
    $user    = User::where('email', $teacher->email)->firstOrFail();
    TeachingAssignment::factory()->create([
        'teacher_id'       => $teacher->id,
        'class_id'         => $class->id,
        'academic_year_id' => $ay->id,
    ]);
    return $user;
}

function seedReportCard(SchoolClass $class, Semester $sem, float $avgScore = 80): void
{
    $student = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);
    ReportCard::factory()->create([
        'student_id'    => $student->id,
        'class_id'      => $class->id,
        'semester_id'   => $sem->id,
        'report_type'   => 'final',
        'average_score' => $avgScore,
    ]);
}

// ── Test 1: Teacher A cannot see Teacher B's data ─────────────────────────────

it('teacher A classAvgComparison does not include teacher B class', function () {
    $ay     = AcademicYear::factory()->create(['is_active' => true]);
    $sem    = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $classA = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $classB = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);

    $teacherA = teacherUserWithHomeroom($classA);
    teacherUserWithHomeroom($classB); // Teacher B assigned to classB

    seedReportCard($classA, $sem, 85);
    seedReportCard($classB, $sem, 90);

    $response = $this->actingAs($teacherA)->get(route('analytics.index'));

    $response->assertOk();
    $response->assertInertia(function ($page) use ($classA, $classB) {
        $data = $page->toArray()['props']['classAvgComparison']['data'] ?? [];
        $classIds = array_column($data, 'class_id');

        expect($classIds)->toContain($classA->id)
            ->and($classIds)->not->toContain($classB->id);
    });
});

// ── Test 2: Wali kelas sees attendance trend but regular teacher does not for unowned class ──

it('wali kelas sees attendance trend but regular teacher does not for unowned class', function () {
    $ay     = AcademicYear::factory()->create(['is_active' => true]);
    $sem    = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $classA = SchoolClass::factory()->create(['academic_year_id' => $ay->id]); // teacher's TA
    $classB = SchoolClass::factory()->create(['academic_year_id' => $ay->id]); // foreign

    $teacher = teacherUserWithTA($classA, $ay);

    // Request attendance trend for classB (foreign — should be denied)
    $response = $this->actingAs($teacher)
        ->getJson(route('analytics.data', ['widget' => 'attendance-trend']) . "?class_id={$classB->id}&semester_id={$sem->id}");

    $response->assertOk(); // Returns 200 with empty/denied data (not 403)
    $data = $response->json('meta.empty_reason');
    expect($data)->toBe('access_denied');
});

// ── Test 3: Teacher with no scope gets 403 ────────────────────────────────────

it('teacher with no homeroom and no TA gets 403 on analytics dashboard', function () {
    // Orphan teacher: role=teacher but no Teacher record, so policy->view() returns false
    $orphan = User::factory()->create(['role' => 'teacher']);
    Semester::factory()->create(['is_active' => true]);

    $this->actingAs($orphan)->get(route('analytics.index'))->assertForbidden();
});

// ── Test 4: Teacher who is BOTH wali kelas AND has TA sees union ──────────────

it('teacher who is wali kelas and has TA in another class sees both classes', function () {
    $ay     = AcademicYear::factory()->create(['is_active' => true]);
    $sem    = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $classA = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $classB = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $classC = SchoolClass::factory()->create(['academic_year_id' => $ay->id]); // neither

    // Create teacher who is wali of classA AND has TA in classB
    $teacher = Teacher::factory()->create();
    $user    = User::where('email', $teacher->email)->firstOrFail();
    $classA->update(['homeroom_teacher_id' => $teacher->id]);
    TeachingAssignment::factory()->create([
        'teacher_id'       => $teacher->id,
        'class_id'         => $classB->id,
        'academic_year_id' => $ay->id,
    ]);

    seedReportCard($classA, $sem, 80);
    seedReportCard($classB, $sem, 75);
    seedReportCard($classC, $sem, 90); // should NOT appear

    $response = $this->actingAs($user)->get(route('analytics.index'));

    $response->assertOk();
    $response->assertInertia(function ($page) use ($classA, $classB, $classC) {
        $data = $page->toArray()['props']['classAvgComparison']['data'] ?? [];
        $classIds = array_column($data, 'class_id');

        expect($classIds)->toContain($classA->id)
            ->and($classIds)->toContain($classB->id)
            ->and($classIds)->not->toContain($classC->id);
    });
});

// ── Test 5: Admin still sees full unfiltered data (regression) ────────────────

it('admin sees school-wide data unchanged', function () {
    $ay     = AcademicYear::factory()->create(['is_active' => true]);
    $sem    = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $classA = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $classB = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $classC = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);

    seedReportCard($classA, $sem, 80);
    seedReportCard($classB, $sem, 75);
    seedReportCard($classC, $sem, 90);

    $admin    = isolationAdmin();
    $response = $this->actingAs($admin)->get(route('analytics.index'));

    $response->assertOk();
    $response->assertInertia(function ($page) use ($classA, $classB, $classC) {
        $data = $page->toArray()['props']['classAvgComparison']['data'] ?? [];
        $classIds = array_column($data, 'class_id');

        expect($classIds)->toContain($classA->id)
            ->and($classIds)->toContain($classB->id)
            ->and($classIds)->toContain($classC->id);
    });
});

// ── Test 6: Teacher blocked from admin-only widget (teacherWorkload) ──────────

it('teacher is blocked from teacher-workload widget endpoint', function () {
    $ay      = AcademicYear::factory()->create(['is_active' => true]);
    $sem     = Semester::factory()->create(['is_active' => true, 'academic_year_id' => $ay->id]);
    $class   = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);

    $teacher = teacherUserWithHomeroom($class);

    $response = $this->actingAs($teacher)
        ->getJson(route('analytics.data', ['widget' => 'teacher-workload']) . "?semester_id={$sem->id}");

    $response->assertForbidden();
});
