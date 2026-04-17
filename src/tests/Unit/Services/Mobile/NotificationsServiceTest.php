<?php

use App\Models\Student;
use App\Models\User;
use App\Services\Mobile\NotificationsService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new NotificationsService();
});

it('listForUser returns paginated notifications with unread count', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $user->update(['role' => 'student']);

    // Manually insert 3 notifications: 2 unread, 1 read
    $user->notifications()->create([
        'id' => Str::uuid()->toString(),
        'type' => 'App\\Notifications\\GradePostedNotification',
        'data' => ['type' => 'grade', 'title' => 'Nilai Baru', 'message' => 'Matematika: 85'],
        'read_at' => null,
    ]);
    $user->notifications()->create([
        'id' => Str::uuid()->toString(),
        'type' => 'App\\Notifications\\NewAnnouncementNotification',
        'data' => ['type' => 'announcement', 'title' => 'Pengumuman', 'message' => 'Libur besok', 'announcement_id' => 5],
        'read_at' => null,
    ]);
    $user->notifications()->create([
        'id' => Str::uuid()->toString(),
        'type' => 'App\\Notifications\\GradePostedNotification',
        'data' => ['type' => 'grade', 'title' => 'Nilai Baru', 'message' => 'IPA: 90'],
        'read_at' => now(),
    ]);

    $result = $this->service->listForUser($user);

    expect($result['data'])->toHaveCount(3);
    expect($result['meta']['unread_count'])->toBe(2);
    expect($result['meta']['total'])->toBe(3);

    $first = $result['data'][0];
    expect($first)->toHaveKeys(['id', 'type', 'title', 'body', 'icon', 'action', 'read_at', 'created_at']);
});

it('listForUser projects type to icon + action correctly', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $user->update(['role' => 'student']);

    $user->notifications()->create([
        'id' => Str::uuid()->toString(),
        'type' => 'App\\Notifications\\NewAnnouncementNotification',
        'data' => ['type' => 'announcement', 'title' => 'Pengumuman', 'message' => 'X', 'announcement_id' => 7],
    ]);

    $result = $this->service->listForUser($user);
    $n = $result['data'][0];

    expect($n['icon'])->toBe('campaign');
    expect($n['action'])->toBe(['screen' => 'announcement_detail', 'args' => ['id' => 7]]);
});

it('markAsRead marks unread notification', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $user->update(['role' => 'student']);

    $id = Str::uuid()->toString();
    $user->notifications()->create([
        'id' => $id,
        'type' => 'App\\Notifications\\GradePostedNotification',
        'data' => ['type' => 'grade', 'title' => 'X', 'message' => 'Y'],
        'read_at' => null,
    ]);

    $this->service->markAsRead($user, $id);

    expect($user->notifications()->find($id)->read_at)->not->toBeNull();
});

it('markAsRead throws when notification belongs to another user', function () {
    $s1 = Student::factory()->create();
    $u1 = User::where('email', $s1->email)->first();
    $u1->update(['role' => 'student']);
    $s2 = Student::factory()->create();
    $u2 = User::where('email', $s2->email)->first();
    $u2->update(['role' => 'student']);

    $id = Str::uuid()->toString();
    $u2->notifications()->create([
        'id' => $id,
        'type' => 'App\\Notifications\\GradePostedNotification',
        'data' => ['type' => 'grade', 'title' => 'X', 'message' => 'Y'],
    ]);

    expect(fn () => $this->service->markAsRead($u1, $id))
        ->toThrow(AuthorizationException::class);
});

it('markAllAsRead marks all unread for user and returns count', function () {
    $student = Student::factory()->create();
    $user = User::where('email', $student->email)->first();
    $user->update(['role' => 'student']);

    foreach (range(1, 4) as $i) {
        $user->notifications()->create([
            'id' => Str::uuid()->toString(),
            'type' => 'App\\Notifications\\GradePostedNotification',
            'data' => ['type' => 'grade', 'title' => 'X', 'message' => "msg {$i}"],
            'read_at' => $i === 1 ? now() : null,  // 1 already read, 3 unread
        ]);
    }

    $count = $this->service->markAllAsRead($user);

    expect($count)->toBe(3);
    expect($user->unreadNotifications()->count())->toBe(0);
});
