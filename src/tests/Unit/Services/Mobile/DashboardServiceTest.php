<?php

use App\Models\Announcement;
use App\Models\Attendance;
use App\Models\Schedule;
use App\Models\Student;
use App\Models\TeachingAssignment;
use App\Models\User;
use App\Services\Mobile\DashboardService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new DashboardService();
});

it('returns student profile with class and homeroom teacher', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    $data = $this->service->forStudent($user);

    expect($data['role'])->toBe('student');
    expect($data['student'])->toMatchArray([
        'id' => $student->id,
        'name' => $student->name,
    ]);
    expect($data['student']['class'])->not->toBeNull();
    expect($data)->toHaveKeys(['stats', 'todays_schedules', 'recent_announcements']);
});

it('calculates attendance percentage from hadir records', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    // 4 hadir + 1 alpha = 80%
    Attendance::factory()->count(4)->create([
        'student_id' => $student->id,
        'class_id' => $student->class_id,
        'status' => 'hadir',
    ]);
    Attendance::factory()->create([
        'student_id' => $student->id,
        'class_id' => $student->class_id,
        'status' => 'alpha',
    ]);

    $data = $this->service->forStudent($user);

    expect($data['stats']['attendance_percentage'])->toBe(80);
});

it('returns attendance_percentage 0 when no records exist', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    $data = $this->service->forStudent($user);

    expect($data['stats']['attendance_percentage'])->toBe(0);
});

it('returns empty todays_schedules when student has no class_id', function () {
    $student = Student::factory()->create(['class_id' => null]);
    $user = User::where('email', $student->email)->first();

    $data = $this->service->forStudent($user);

    expect($data['todays_schedules'])->toBe([]);
});

it('returns at most 5 recent published announcements ordered by newest', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    // Create 7 published + 2 unpublished
    Announcement::factory()->count(7)->create(['is_published' => true]);
    Announcement::factory()->count(2)->create(['is_published' => false]);

    $data = $this->service->forStudent($user);

    expect($data['recent_announcements'])->toHaveCount(5);
});

it('trims announcement content to 120 chars and strips HTML', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    Announcement::factory()->create([
        'is_published' => true,
        'content' => '<p>' . str_repeat('a', 200) . '</p>',
    ]);

    $data = $this->service->forStudent($user);

    $content = $data['recent_announcements'][0]['content'];
    expect(strlen($content))->toBeLessThanOrEqual(124); // 120 + "..."
    expect($content)->not->toContain('<p>');
});
