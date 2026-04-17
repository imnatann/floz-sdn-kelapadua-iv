<?php

use App\Models\Meeting;
use App\Models\MeetingMaterial;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use App\Services\Mobile\CoursesService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new CoursesService();
});

it('listForStudent returns subjects for student class with meeting + material counts', function () {
    $class = SchoolClass::factory()->create();
    $student = Student::factory()->create(['class_id' => $class->id]);
    $user = User::where('email', $student->email)->first();

    $teacher = Teacher::factory()->create();
    $subject = Subject::factory()->create(['name' => 'Matematika']);
    $ta = TeachingAssignment::factory()
        ->for($teacher)
        ->for($subject)
        ->create(['class_id' => $class->id]);

    // TeachingAssignment::booted() auto-generates 16 meetings; clear them so we
    // can assert against an explicit set.
    Meeting::where('teaching_assignment_id', $ta->id)->delete();

    $meeting1 = Meeting::factory()->create(['teaching_assignment_id' => $ta->id, 'meeting_number' => 1]);
    $meeting2 = Meeting::factory()->create(['teaching_assignment_id' => $ta->id, 'meeting_number' => 2]);
    MeetingMaterial::factory()->create(['meeting_id' => $meeting1->id]);
    MeetingMaterial::factory()->count(2)->create(['meeting_id' => $meeting2->id]);

    $result = $this->service->listForStudent($user);

    expect($result)->toHaveCount(1);
    expect($result[0])->toMatchArray([
        'id' => $ta->id,
        'subject_name' => 'Matematika',
        'teacher_name' => $teacher->name,
        'meeting_count' => 2,
        'material_count' => 3,
    ]);
});

it('listForStudent returns empty array when student has no class', function () {
    $student = Student::factory()->create(['class_id' => null]);
    $user = User::where('email', $student->email)->first();
    expect($this->service->listForStudent($user))->toBe([]);
});

it('meetingsFor returns 16 meetings with material counts', function () {
    $class = SchoolClass::factory()->create();
    $student = Student::factory()->create(['class_id' => $class->id]);
    $user = User::where('email', $student->email)->first();

    $ta = TeachingAssignment::factory()->create(['class_id' => $class->id]);
    // booted() already created the 16 meetings; calling generate again would
    // violate the unique [teaching_assignment_id, meeting_number] index.

    $first = Meeting::where('teaching_assignment_id', $ta->id)->orderBy('meeting_number')->first();
    MeetingMaterial::factory()->count(3)->create(['meeting_id' => $first->id]);

    $result = $this->service->meetingsFor($user, $ta->id);

    expect($result['teaching_assignment'])->toHaveKeys(['id', 'subject_name', 'teacher_name', 'class_name']);
    expect($result['meetings'])->toHaveCount(16);
    expect($result['meetings'][0])->toMatchArray([
        'meeting_number' => 1,
        'material_count' => 3,
        'is_locked' => false,
    ]);
    // UTS (15) and UAS (16) are locked by default per Meeting::generateForTeachingAssignment
    $uts = collect($result['meetings'])->firstWhere('meeting_number', 15);
    expect($uts['is_locked'])->toBeTrue();
});

it('meetingsFor throws AuthorizationException when student class does not match TA class', function () {
    $studentClass = SchoolClass::factory()->create();
    $otherClass = SchoolClass::factory()->create();
    $student = Student::factory()->create(['class_id' => $studentClass->id]);
    $user = User::where('email', $student->email)->first();

    $ta = TeachingAssignment::factory()->create(['class_id' => $otherClass->id]);
    // booted() auto-generated meetings already.

    expect(fn () => $this->service->meetingsFor($user, $ta->id))
        ->toThrow(AuthorizationException::class);
});

it('meetingDetail returns meeting with materials sorted by sort_order', function () {
    $class = SchoolClass::factory()->create();
    $student = Student::factory()->create(['class_id' => $class->id]);
    $user = User::where('email', $student->email)->first();

    $ta = TeachingAssignment::factory()->create(['class_id' => $class->id]);
    // Clear auto-generated meetings so we can create our explicit fixture.
    Meeting::where('teaching_assignment_id', $ta->id)->delete();

    $meeting = Meeting::factory()->create([
        'teaching_assignment_id' => $ta->id,
        'meeting_number' => 1,
        'title' => 'Pertemuan 1',
        'is_locked' => false,
    ]);

    MeetingMaterial::factory()->create([
        'meeting_id' => $meeting->id,
        'title' => 'Slide',
        'type' => 'file',
        'file_path' => 'materials/slide.pdf',
        'file_name' => 'slide.pdf',
        'file_size' => 102400,
        'sort_order' => 2,
    ]);
    MeetingMaterial::factory()->create([
        'meeting_id' => $meeting->id,
        'title' => 'Video YouTube',
        'type' => 'link',
        'url' => 'https://youtube.com/watch?v=xyz',
        'sort_order' => 1,
    ]);

    $result = $this->service->meetingDetail($user, $meeting->id);

    expect($result['meeting'])->toMatchArray([
        'id' => $meeting->id,
        'meeting_number' => 1,
        'title' => 'Pertemuan 1',
        'is_locked' => false,
    ]);
    expect($result['materials'])->toHaveCount(2);
    expect($result['materials'][0]['title'])->toBe('Video YouTube');
    expect($result['materials'][0]['type'])->toBe('link');
    expect($result['materials'][1]['title'])->toBe('Slide');
    expect($result['materials'][1]['file_url'])->toContain('storage/materials/slide.pdf');
});

it('meetingDetail throws AuthorizationException when student class mismatch', function () {
    $studentClass = SchoolClass::factory()->create();
    $otherClass = SchoolClass::factory()->create();
    $student = Student::factory()->create(['class_id' => $studentClass->id]);
    $user = User::where('email', $student->email)->first();

    $ta = TeachingAssignment::factory()->create(['class_id' => $otherClass->id]);
    // Clear auto-generated meetings, then create our test fixture meeting.
    Meeting::where('teaching_assignment_id', $ta->id)->delete();
    $meeting = Meeting::factory()->create(['teaching_assignment_id' => $ta->id, 'meeting_number' => 1]);

    expect(fn () => $this->service->meetingDetail($user, $meeting->id))
        ->toThrow(AuthorizationException::class);
});
