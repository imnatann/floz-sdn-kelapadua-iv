<?php

use App\Models\ReportCard;
use App\Models\Student;
use App\Models\User;
use App\Services\Mobile\ReportCardService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new ReportCardService();
});

it('returns only published report cards for student', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    // 1 published + 1 draft
    ReportCard::factory()->create([
        'student_id' => $student->id,
        'class_id' => $student->class_id,
        'status' => 'published',
        'published_at' => now(),
        'average_score' => 85,
        'rank' => 3,
    ]);
    ReportCard::factory()->create([
        'student_id' => $student->id,
        'class_id' => $student->class_id,
        'status' => 'draft',
    ]);

    $result = $this->service->listForStudent($user);

    expect($result)->toHaveCount(1);
    expect($result[0])->toHaveKeys(['id', 'semester_name', 'academic_year', 'average_score', 'rank', 'published_at']);
    expect($result[0]['average_score'])->toBe(85.0);
});

it('returns empty list when student has no published report cards', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    $result = $this->service->listForStudent($user);

    expect($result)->toBe([]);
});

it('returns detail for a published report card', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    $rc = ReportCard::factory()->create([
        'student_id' => $student->id,
        'class_id' => $student->class_id,
        'status' => 'published',
        'published_at' => now(),
        'average_score' => 82,
        'total_score' => 820,
        'rank' => 5,
        'attendance_present' => 80,
        'attendance_sick' => 3,
        'attendance_permit' => 2,
        'attendance_absent' => 1,
        'homeroom_comment' => 'Bagus',
        'pdf_url' => 'https://example.com/rapor.pdf',
    ]);

    $result = $this->service->detailForStudent($user, $rc->id);

    expect($result)->not->toBeNull();
    expect($result)->toHaveKeys([
        'id', 'semester_name', 'academic_year', 'class_name',
        'average_score', 'total_score', 'rank',
        'attendance_present', 'attendance_sick', 'attendance_permit', 'attendance_absent',
        'homeroom_comment', 'pdf_url', 'published_at',
    ]);
    expect($result['homeroom_comment'])->toBe('Bagus');
    expect($result['pdf_url'])->toBe('https://example.com/rapor.pdf');
});

it('returns null for detail of unpublished or nonexistent report card', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    $rc = ReportCard::factory()->create([
        'student_id' => $student->id,
        'class_id' => $student->class_id,
        'status' => 'draft',
    ]);

    $result = $this->service->detailForStudent($user, $rc->id);

    expect($result)->toBeNull();
});

it('returns pdf url for published report card', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    $rc = ReportCard::factory()->create([
        'student_id' => $student->id,
        'class_id' => $student->class_id,
        'status' => 'published',
        'published_at' => now(),
        'pdf_url' => 'https://cdn.example.com/report.pdf',
    ]);

    $result = $this->service->pdfUrlForStudent($user, $rc->id);

    expect($result)->toBe('https://cdn.example.com/report.pdf');
});
