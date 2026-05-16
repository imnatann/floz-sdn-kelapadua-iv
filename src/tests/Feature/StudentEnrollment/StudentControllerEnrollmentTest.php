<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

function makeAdmin(): User {
    return User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);
}

function makeAyWithActiveSem(): array {
    $ay = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $sem = Semester::create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $class = SchoolClass::create(['name' => '1A', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    return [$ay, $sem, $class];
}

it('creates an enrollment row when admin creates a student with class_id', function () {
    [, $sem, $class] = makeAyWithActiveSem();
    $admin = makeAdmin();

    $this->actingAs($admin)->post('/students', [
        'nis'      => '001',
        'name'     => 'Nathan',
        'class_id' => $class->id,
    ])->assertRedirect();

    $student = Student::where('nis', '001')->first();
    expect($student)->not->toBeNull();

    $enrollment = StudentClassEnrollment::where('student_id', $student->id)->first();
    expect($enrollment)->not->toBeNull();
    expect($enrollment->semester_id)->toBe($sem->id);
    expect($enrollment->class_id)->toBe($class->id);
    expect($enrollment->status)->toBe('active');
});

it('does not create an enrollment when student has no class_id', function () {
    makeAyWithActiveSem();
    $admin = makeAdmin();

    $this->actingAs($admin)->post('/students', [
        'nis'  => '002',
        'name' => 'Orphan',
    ])->assertRedirect();

    expect(StudentClassEnrollment::count())->toBe(0);
});

it('overwrites enrollment + records mutation when admin changes class_id mid-semester', function () {
    [$ay, $sem, $classA] = makeAyWithActiveSem();
    $classB = SchoolClass::create(['name' => '1B', 'grade_level' => 1, 'academic_year_id' => $ay->id, 'status' => 'active']);
    $admin = makeAdmin();

    $this->actingAs($admin)->post('/students', [
        'nis'      => '003',
        'name'     => 'Andi',
        'class_id' => $classA->id,
    ])->assertRedirect();

    $student = Student::where('nis', '003')->first();

    $this->actingAs($admin)->put("/students/{$student->id}", [
        'nis'      => '003',
        'name'     => 'Andi',
        'class_id' => $classB->id,
        'status'   => 'active',
    ])->assertRedirect();

    $enrollment = StudentClassEnrollment::where('student_id', $student->id)
        ->where('semester_id', $sem->id)
        ->first();
    expect($enrollment->class_id)->toBe($classB->id);
    expect($enrollment->status)->toBe('active');

    $mutation = \App\Models\StudentMutation::where('student_id', $student->id)->first();
    expect($mutation)->not->toBeNull();
    expect($mutation->from_class_id)->toBe($classA->id);
    expect($mutation->to_class_id)->toBe($classB->id);
    expect($mutation->type)->toBe('transfer_in');
});

it('does not write a mutation if class_id is unchanged on update', function () {
    [, , $classA] = makeAyWithActiveSem();
    $admin = makeAdmin();

    $this->actingAs($admin)->post('/students', [
        'nis'      => '004',
        'name'     => 'Layen',
        'class_id' => $classA->id,
    ])->assertRedirect();

    $student = Student::where('nis', '004')->first();

    $this->actingAs($admin)->put("/students/{$student->id}", [
        'nis'      => '004',
        'name'     => 'Layen Updated',
        'class_id' => $classA->id,
        'status'   => 'active',
    ])->assertRedirect();

    expect(\App\Models\StudentMutation::count())->toBe(0);
});

it('filters students by enrollment semester showing historical roster including non-active', function () {
    [, $semGanjil, $classA] = makeAyWithActiveSem();
    $admin = makeAdmin();

    $this->actingAs($admin)->post('/students', ['nis' => '101', 'name' => 'Stayed', 'class_id' => $classA->id]);
    $this->actingAs($admin)->post('/students', ['nis' => '102', 'name' => 'Pindah', 'class_id' => $classA->id]);

    $pindah = Student::where('nis', '102')->first();

    StudentClassEnrollment::where('student_id', $pindah->id)
        ->where('semester_id', $semGanjil->id)
        ->update(['status' => 'transferred_out', 'exit_date' => '2025-10-15']);

    $response = $this->actingAs($admin)->get("/students?semester_id={$semGanjil->id}");
    $response->assertOk();
    $data = $response->viewData('page')['props']['students']['data'];

    $names = collect($data)->pluck('name')->toArray();
    expect($names)->toContain('Stayed');
    expect($names)->toContain('Pindah');

    $pindahRow = collect($data)->firstWhere('name', 'Pindah');
    expect($pindahRow['enrollment_status'])->toBe('transferred_out');
});

it('displays the historical enrollment class for the selected academic year', function () {
    $admin = makeAdmin();

    $previousAy = AcademicYear::create([
        'name' => '2026/2027',
        'is_active' => false,
        'start_date' => '2026-07-01',
        'end_date' => '2027-06-30',
    ]);
    $previousSemester = Semester::create([
        'academic_year_id' => $previousAy->id,
        'semester_number' => 2,
        'is_active' => false,
        'start_date' => '2027-01-01',
        'end_date' => '2027-06-30',
    ]);
    $previousClass = SchoolClass::create([
        'name' => 'Kelas 1',
        'grade_level' => 1,
        'academic_year_id' => $previousAy->id,
        'status' => 'active',
    ]);

    $currentAy = AcademicYear::create([
        'name' => '2027/2028',
        'is_active' => true,
        'start_date' => '2027-07-01',
        'end_date' => '2028-06-30',
    ]);
    $currentSemester = Semester::create([
        'academic_year_id' => $currentAy->id,
        'semester_number' => 1,
        'is_active' => true,
        'start_date' => '2027-07-01',
        'end_date' => '2027-12-31',
    ]);
    $currentClass = SchoolClass::create([
        'name' => 'Kelas 2',
        'grade_level' => 2,
        'academic_year_id' => $currentAy->id,
        'status' => 'active',
    ]);

    $student = Student::create([
        'nis' => '777',
        'name' => 'Layen',
        'class_id' => $currentClass->id,
        'status' => 'active',
    ]);

    StudentClassEnrollment::create([
        'student_id' => $student->id,
        'semester_id' => $previousSemester->id,
        'class_id' => $previousClass->id,
        'status' => 'promoted_out',
        'enrolled_at' => '2026-07-01',
    ]);
    StudentClassEnrollment::create([
        'student_id' => $student->id,
        'semester_id' => $currentSemester->id,
        'class_id' => $currentClass->id,
        'status' => 'active',
        'enrolled_at' => '2027-07-01',
    ]);

    $response = $this->actingAs($admin)->get("/students?academic_year_id={$previousAy->id}");
    $response->assertOk();

    $layenRow = collect($response->viewData('page')['props']['students']['data'])
        ->firstWhere('name', 'Layen');

    expect($layenRow['enrollment_class_id'])->toBe($previousClass->id);
    expect($layenRow['enrollment_class']['name'])->toBe('Kelas 1');
    expect($layenRow['class']['name'])->toBe('Kelas 2');
});
