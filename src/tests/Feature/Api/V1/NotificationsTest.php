<?php

use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->student = Student::factory()->create();
    $this->user = User::where('email', $this->student->email)->first();
    $this->user->update(['role' => 'student']);
    $this->token = $this->user->createToken('mobile')->plainTextToken;
});

it('GET /notifications returns paginated list with unread_count', function () {
    $this->user->notifications()->create([
        'id' => Str::uuid()->toString(),
        'type' => 'App\\Notifications\\GradePostedNotification',
        'data' => ['type' => 'grade', 'title' => 'Nilai', 'message' => 'X'],
    ]);

    $this->withHeader('Authorization', "Bearer {$this->token}")
        ->getJson('/api/v1/notifications')
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('meta.unread_count', 1);
});

it('POST /notifications/{id}/read marks as read', function () {
    $id = Str::uuid()->toString();
    $this->user->notifications()->create([
        'id' => $id,
        'type' => 'App\\Notifications\\GradePostedNotification',
        'data' => ['type' => 'grade', 'title' => 'X', 'message' => 'Y'],
    ]);

    $this->withHeader('Authorization', "Bearer {$this->token}")
        ->postJson("/api/v1/notifications/{$id}/read")
        ->assertNoContent();

    expect($this->user->notifications()->find($id)->read_at)->not->toBeNull();
});

it('POST /notifications/read-all marks everything as read and returns count', function () {
    foreach (range(1, 3) as $i) {
        $this->user->notifications()->create([
            'id' => Str::uuid()->toString(),
            'type' => 'App\\Notifications\\GradePostedNotification',
            'data' => ['type' => 'grade', 'title' => 'X', 'message' => "msg {$i}"],
        ]);
    }

    $this->withHeader('Authorization', "Bearer {$this->token}")
        ->postJson('/api/v1/notifications/read-all')
        ->assertOk()
        ->assertJsonPath('data.marked', 3);
});

it('GET /notifications returns 401 without token', function () {
    $this->getJson('/api/v1/notifications')->assertUnauthorized();
});
