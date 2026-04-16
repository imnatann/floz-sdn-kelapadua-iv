<?php

use App\Models\Schedule;
use App\Models\Student;
use App\Models\TeachingAssignment;
use App\Models\User;
use App\Services\Mobile\ScheduleService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new ScheduleService();
});

it('returns empty list when student has no class', function () {
    $student = Student::factory()->create(['class_id' => null]);
    $user = User::where('email', $student->email)->first();

    $result = $this->service->forStudent($user);

    expect($result)->toBe([]);
});

it('returns schedules grouped by day_of_week with indonesian day names', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();

    $ta = TeachingAssignment::factory()->create(['class_id' => $student->class_id]);

    // 2 schedules on Monday (day 1), 1 on Wednesday (day 3)
    Schedule::factory()->onDay(1)->at('07:00:00', '08:30:00')->create([
        'teaching_assignment_id' => $ta->id,
    ]);
    Schedule::factory()->onDay(1)->at('08:30:00', '10:00:00')->create([
        'teaching_assignment_id' => $ta->id,
    ]);
    Schedule::factory()->onDay(3)->at('07:00:00', '08:30:00')->create([
        'teaching_assignment_id' => $ta->id,
    ]);

    $result = $this->service->forStudent($user);

    expect($result)->toHaveCount(2);

    expect($result[0]['day'])->toBe(1);
    expect($result[0]['day_name'])->toBe('Senin');
    expect($result[0]['items'])->toHaveCount(2);

    expect($result[1]['day'])->toBe(3);
    expect($result[1]['day_name'])->toBe('Rabu');
    expect($result[1]['items'])->toHaveCount(1);
});

it('sorts items within a day by start_time ascending', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $ta = TeachingAssignment::factory()->create(['class_id' => $student->class_id]);

    Schedule::factory()->onDay(2)->at('10:00:00', '11:30:00')->create([
        'teaching_assignment_id' => $ta->id,
    ]);
    Schedule::factory()->onDay(2)->at('07:00:00', '08:30:00')->create([
        'teaching_assignment_id' => $ta->id,
    ]);

    $result = $this->service->forStudent($user);

    expect($result[0]['items'][0]['start_time'])->toBe('07:00');
    expect($result[0]['items'][1]['start_time'])->toBe('10:00');
});

it('only returns schedules from teaching assignments in the student\'s class', function () {
    $studentA = Student::factory()->create();
    $studentB = Student::factory()->create();
    $userA = User::where('email', $studentA->email)->first();

    $taA = TeachingAssignment::factory()->create(['class_id' => $studentA->class_id]);
    $taB = TeachingAssignment::factory()->create(['class_id' => $studentB->class_id]);

    Schedule::factory()->onDay(1)->create(['teaching_assignment_id' => $taA->id]);
    Schedule::factory()->onDay(1)->create(['teaching_assignment_id' => $taB->id]);

    $result = $this->service->forStudent($userA);

    expect($result)->toHaveCount(1);
    expect($result[0]['items'])->toHaveCount(1);
});

it('includes subject name and teacher name in each item', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $ta = TeachingAssignment::factory()->create(['class_id' => $student->class_id]);

    Schedule::factory()->onDay(1)->create(['teaching_assignment_id' => $ta->id]);

    $result = $this->service->forStudent($user);
    $item = $result[0]['items'][0];

    expect($item)->toHaveKeys(['id', 'start_time', 'end_time', 'subject', 'teacher']);
    expect($item['subject'])->not->toBeEmpty();
    expect($item['teacher'])->not->toBeEmpty();
});
