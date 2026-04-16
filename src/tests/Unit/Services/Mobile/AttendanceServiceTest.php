<?php

use App\Models\Attendance;
use App\Models\Meeting;
use App\Models\Semester;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use App\Services\Mobile\AttendanceService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new AttendanceService();
    $this->semester = Semester::factory()->create(['is_active' => true]);
});

it('returns roster with students and their attendance status', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->where('meeting_number', 1)->first();

    $s1 = Student::factory()->create(['class_id' => $ta->class_id]);
    $s2 = Student::factory()->create(['class_id' => $ta->class_id]);

    Attendance::factory()->create([
        'student_id' => $s1->id,
        'class_id' => $ta->class_id,
        'semester_id' => $this->semester->id,
        'meeting_number' => $meeting->meeting_number,
        'status' => 'hadir',
    ]);

    $roster = $this->service->getRoster($meeting, $user);

    expect($roster)->toHaveKeys(['meeting', 'class', 'teaching_assignment', 'students']);
    expect($roster['students'])->toHaveCount(2);

    $s1Data = collect($roster['students'])->firstWhere('id', $s1->id);
    $s2Data = collect($roster['students'])->firstWhere('id', $s2->id);

    expect($s1Data['status'])->toBe('hadir');
    expect($s2Data['status'])->toBeNull();
});

it('stores attendance entries using updateOrCreate in transaction', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->where('meeting_number', 1)->first();
    $student = Student::factory()->create(['class_id' => $ta->class_id]);

    $entries = [
        ['student_id' => $student->id, 'status' => 'hadir', 'note' => null],
    ];

    $result = $this->service->store($meeting, $entries, $user);

    expect($result)->toHaveKey('students');
    expect(Attendance::where('student_id', $student->id)->count())->toBe(1);

    $att = Attendance::where('student_id', $student->id)->first();
    expect($att->status)->toBe('hadir');
    expect($att->meeting_number)->toBe($meeting->meeting_number);
    expect($att->class_id)->toBe($ta->class_id);
    expect($att->semester_id)->toBe($this->semester->id);
    expect($att->recorded_by)->toBe($teacher->id);
});

it('updates existing attendance on second submit (updateOrCreate)', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->where('meeting_number', 1)->first();
    $student = Student::factory()->create(['class_id' => $ta->class_id]);

    $this->service->store($meeting, [
        ['student_id' => $student->id, 'status' => 'hadir', 'note' => null],
    ], $user);

    $this->service->store($meeting, [
        ['student_id' => $student->id, 'status' => 'sakit', 'note' => 'Demam'],
    ], $user);

    expect(Attendance::where('student_id', $student->id)->count())->toBe(1);
    $att = Attendance::where('student_id', $student->id)->first();
    expect($att->status)->toBe('sakit');
    expect($att->notes)->toBe('Demam');
});

it('throws exception when no active semester exists', function () {
    Semester::query()->update(['is_active' => false]);

    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->where('meeting_number', 1)->first();

    $this->service->getRoster($meeting, $user);
})->throws(\RuntimeException::class, 'Tidak ada semester aktif');

it('returns students ordered by name', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = $ta->meetings()->where('meeting_number', 1)->first();

    Student::factory()->create(['class_id' => $ta->class_id, 'name' => 'Zahra']);
    Student::factory()->create(['class_id' => $ta->class_id, 'name' => 'Ahmad']);

    $roster = $this->service->getRoster($meeting, $user);

    expect($roster['students'][0]['name'])->toBe('Ahmad');
    expect($roster['students'][1]['name'])->toBe('Zahra');
});
