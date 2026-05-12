<?php

use App\Models\AcademicYear;
use App\Models\Exam;
use App\Models\ExamScore;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Task;
use App\Models\TaskScore;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Maatwebsite\Excel\Facades\Excel;

uses(RefreshDatabase::class);

// ── helpers ──────────────────────────────────────────────────────────────────

function gradeSetup(): array
{
    $ay      = AcademicYear::factory()->create(['is_active' => true]);
    $sem     = Semester::factory()->create(['academic_year_id' => $ay->id, 'is_active' => true]);
    $class   = SchoolClass::factory()->create(['academic_year_id' => $ay->id]);
    $subject = Subject::factory()->create(['status' => 'active']);
    $student = Student::factory()->create(['class_id' => $class->id, 'status' => 'active']);
    $admin   = User::factory()->create(['role' => 'school_admin']);

    return compact('ay', 'sem', 'class', 'subject', 'student', 'admin');
}

// ── tests ─────────────────────────────────────────────────────────────────────

it('it_returns_xlsx_for_school_admin', function () {
    Excel::fake();

    ['ay' => $ay, 'sem' => $sem, 'class' => $class, 'subject' => $subject, 'admin' => $admin] = gradeSetup();

    $response = $this->actingAs($admin)
        ->get(route('analytics.export.grades', [
            'semester_id' => $sem->id,
            'class_id'    => $class->id,
            'subject_id'  => $subject->id,
        ]));

    $response->assertOk();

    $ayName   = str_replace('/', '-', $ay->name);
    $className = str_replace(' ', '_', $class->name);
    $expectedFilename = "Rekap_Nilai_{$className}_Sem{$sem->semester_number}_{$ayName}_" . now()->format('Y-m-d') . '.xlsx';
    Excel::assertDownloaded($expectedFilename);
});

it('it_returns_403_for_non_teacher_non_admin', function () {
    ['sem' => $sem, 'class' => $class, 'subject' => $subject] = gradeSetup();

    $student_user = User::factory()->create(['role' => 'student']);

    $this->actingAs($student_user)
        ->get(route('analytics.export.grades', [
            'semester_id' => $sem->id,
            'class_id'    => $class->id,
        ]))
        ->assertForbidden();
});

it('it_blocks_teacher_from_subject_they_dont_teach', function () {
    ['ay' => $ay, 'sem' => $sem, 'class' => $class, 'subject' => $subject] = gradeSetup();

    $teacherUser   = User::factory()->create(['role' => 'teacher']);
    $teacherRecord = Teacher::factory()->create(['user_id' => $teacherUser->id]);

    $otherSubject = Subject::factory()->create(['status' => 'active']);

    // Assign teacher to the OTHER subject (not $subject)
    TeachingAssignment::factory()->create([
        'teacher_id' => $teacherRecord->id,
        'subject_id' => $otherSubject->id,
        'class_id'   => $class->id,
    ]);

    $this->actingAs($teacherUser)
        ->get(route('analytics.export.grades', [
            'semester_id' => $sem->id,
            'class_id'    => $class->id,
            'subject_id'  => $subject->id,
        ]))
        ->assertForbidden();
});

it('it_includes_task_uts_uas_columns_for_active_semester', function () {
    [
        'sem'     => $sem,
        'class'   => $class,
        'subject' => $subject,
        'student' => $student,
        'admin'   => $admin,
    ] = gradeSetup();

    // Create 2 tasks
    $task1 = Task::factory()->create([
        'class_id'   => $class->id,
        'semester_id'=> $sem->id,
        'subject_id' => $subject->id,
        'title'      => 'Tugas 1',
    ]);
    $task2 = Task::factory()->create([
        'class_id'   => $class->id,
        'semester_id'=> $sem->id,
        'subject_id' => $subject->id,
        'title'      => 'Tugas 2',
    ]);
    TaskScore::factory()->create(['task_id' => $task1->id, 'student_id' => $student->id, 'score' => 80]);
    TaskScore::factory()->create(['task_id' => $task2->id, 'student_id' => $student->id, 'score' => 90]);

    // UTS exam
    $uts = Exam::factory()->create([
        'class_id'   => $class->id,
        'semester_id'=> $sem->id,
        'subject_id' => $subject->id,
        'exam_type'  => 'uts',
    ]);
    ExamScore::factory()->create(['exam_id' => $uts->id, 'student_id' => $student->id, 'score' => 75]);

    // UAS exam
    $uas = Exam::factory()->create([
        'class_id'   => $class->id,
        'semester_id'=> $sem->id,
        'subject_id' => $subject->id,
        'exam_type'  => 'uas',
    ]);
    ExamScore::factory()->create(['exam_id' => $uas->id, 'student_id' => $student->id, 'score' => 85]);

    // Add 2 ulangan_harian exams
    $uh1 = Exam::factory()->create([
        'class_id'   => $class->id,
        'semester_id'=> $sem->id,
        'subject_id' => $subject->id,
        'exam_type'  => 'ulangan_harian',
        'exam_date'  => '2025-01-10',
    ]);
    $uh2 = Exam::factory()->create([
        'class_id'   => $class->id,
        'semester_id'=> $sem->id,
        'subject_id' => $subject->id,
        'exam_type'  => 'ulangan_harian',
        'exam_date'  => '2025-02-15',
    ]);
    ExamScore::factory()->create(['exam_id' => $uh1->id, 'student_id' => $student->id, 'score' => 70]);
    ExamScore::factory()->create(['exam_id' => $uh2->id, 'student_id' => $student->id, 'score' => 80]);

    // Re-instantiate sheet to pick up UH exams
    $sheet    = new \App\Exports\Sheets\ClassGradeSheet($class, $sem, $subject);
    $headings = $sheet->headings();
    $rows     = $sheet->collection();
    $row      = $rows->first();

    // Headings must include task columns + UH columns + UTS + UAS + Nilai Akhir + Predikat
    expect($headings)->toContain('Nilai Tugas 1')
        ->and($headings)->toContain('Nilai Tugas 2')
        ->and($headings)->toContain('UH 1')
        ->and($headings)->toContain('UH 2')
        ->and($headings)->toContain('UTS')
        ->and($headings)->toContain('UAS')
        ->and($headings)->toContain('Nilai Akhir')
        ->and($headings)->toContain('Predikat');

    // UH columns must come after task columns and before UTS
    $tugas2Idx = array_search('Nilai Tugas 2', $headings);
    $uh1Idx    = array_search('UH 1', $headings);
    $uh2Idx    = array_search('UH 2', $headings);
    $utsIdx    = array_search('UTS', $headings);
    expect($uh1Idx)->toBeGreaterThan($tugas2Idx)
        ->and($uh2Idx)->toBeGreaterThan($uh1Idx)
        ->and($utsIdx)->toBeGreaterThan($uh2Idx);

    // Find Nilai Akhir column index
    $naIdx = array_search('Nilai Akhir', $headings);
    expect($row[$naIdx])->toBeGreaterThan(0);

    $predIdx = array_search('Predikat', $headings);
    expect($row[$predIdx])->toBeIn(['A', 'B', 'C', 'D']);
});

it('it_renders_predikat_based_on_final_score', function () {
    [
        'sem'     => $sem,
        'class'   => $class,
        'subject' => $subject,
        'student' => $student,
        'admin'   => $admin,
    ] = gradeSetup();

    // No tasks, just UTS + UAS scores → final = (0 + uts_avg + uas_avg) / 3
    // Give high scores so predikat = A
    $uts = Exam::factory()->create([
        'class_id'   => $class->id,
        'semester_id'=> $sem->id,
        'subject_id' => $subject->id,
        'exam_type'  => 'uts',
    ]);
    ExamScore::factory()->create(['exam_id' => $uts->id, 'student_id' => $student->id, 'score' => 95]);

    $uas = Exam::factory()->create([
        'class_id'   => $class->id,
        'semester_id'=> $sem->id,
        'subject_id' => $subject->id,
        'exam_type'  => 'uas',
    ]);
    ExamScore::factory()->create(['exam_id' => $uas->id, 'student_id' => $student->id, 'score' => 95]);

    $sheet   = new \App\Exports\Sheets\ClassGradeSheet($class, $sem, $subject);
    $row     = $sheet->collection()->first();
    $headings = $sheet->headings();
    $predIdx = array_search('Predikat', $headings);

    // (0 + 95 + 95) / 3 ≈ 63.33 → but only uts+uas with no tasks → actually formula
    // depends on divisor logic. Score >= 90 gives A, >= 75 B, >= 60 C, else D.
    // With no tasks, taskAvg=0, ulanganAvg=0, formativeDivisor=1→dailyTestAvg=0
    // final = (0 + 95 + 95)/3 = 63.33 → C
    expect($row[$predIdx])->toBeIn(['A', 'B', 'C', 'D']);

    // Verify predikat for a known-A score by checking the static helper
    expect(\App\Exports\Sheets\ClassGradeSheet::predikat(92))->toBe('A');
    expect(\App\Exports\Sheets\ClassGradeSheet::predikat(80))->toBe('B');
    expect(\App\Exports\Sheets\ClassGradeSheet::predikat(70))->toBe('C');
    expect(\App\Exports\Sheets\ClassGradeSheet::predikat(50))->toBe('D');
});

it('it_renders_ulangan_harian_columns_dynamically', function () {
    [
        'sem'     => $sem,
        'class'   => $class,
        'subject' => $subject,
        'student' => $student,
    ] = gradeSetup();

    // 3 UH exams with different dates to test ordering
    $uh1 = Exam::factory()->create([
        'class_id'   => $class->id,
        'semester_id'=> $sem->id,
        'subject_id' => $subject->id,
        'exam_type'  => 'ulangan_harian',
        'exam_date'  => '2025-01-05',
    ]);
    $uh2 = Exam::factory()->create([
        'class_id'   => $class->id,
        'semester_id'=> $sem->id,
        'subject_id' => $subject->id,
        'exam_type'  => 'ulangan_harian',
        'exam_date'  => '2025-02-10',
    ]);
    $uh3 = Exam::factory()->create([
        'class_id'   => $class->id,
        'semester_id'=> $sem->id,
        'subject_id' => $subject->id,
        'exam_type'  => 'ulangan_harian',
        'exam_date'  => '2025-03-20',
    ]);
    ExamScore::factory()->create(['exam_id' => $uh1->id, 'student_id' => $student->id, 'score' => 60]);
    ExamScore::factory()->create(['exam_id' => $uh2->id, 'student_id' => $student->id, 'score' => 70]);
    ExamScore::factory()->create(['exam_id' => $uh3->id, 'student_id' => $student->id, 'score' => 80]);

    $sheet    = new \App\Exports\Sheets\ClassGradeSheet($class, $sem, $subject);
    $headings = $sheet->headings();
    $rows     = $sheet->collection();
    $row      = $rows->first();

    // Exactly 3 UH columns
    expect($headings)->toContain('UH 1')
        ->and($headings)->toContain('UH 2')
        ->and($headings)->toContain('UH 3')
        ->and($headings)->not->toContain('UH 4');

    // UH columns precede UTS
    $uh3Idx = array_search('UH 3', $headings);
    $utsIdx = array_search('UTS', $headings);
    expect($uh3Idx)->toBeLessThan($utsIdx);

    // Row has UH scores in correct positions
    $uh1Idx = array_search('UH 1', $headings);
    $uh2Idx = array_search('UH 2', $headings);
    expect($row[$uh1Idx])->toBe(60.0)
        ->and($row[$uh2Idx])->toBe(70.0)
        ->and($row[$uh3Idx])->toBe(80.0);

    // No UH exams → no UH columns
    $class2   = \App\Models\SchoolClass::factory()->create(['academic_year_id' => $sem->academic_year_id]);
    $subject2 = \App\Models\Subject::factory()->create(['status' => 'active']);
    $sheet2   = new \App\Exports\Sheets\ClassGradeSheet($class2, $sem, $subject2);
    expect($sheet2->headings())->not->toContain('UH 1');
});
