<?php

use App\Models\Announcement;
use App\Models\Student;
use App\Models\User;
use App\Services\Mobile\AnnouncementService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->service = new AnnouncementService();
});

it('list returns published announcements visible to students', function () {
    // visible: target_audience 'all'
    $all = Announcement::factory()->create([
        'is_published'    => true,
        'target_audience' => 'all',
        'title'           => 'For All',
    ]);
    // visible: target_audience 'students'
    $students = Announcement::factory()->create([
        'is_published'    => true,
        'target_audience' => 'students',
        'title'           => 'For Students',
    ]);

    $user = User::factory()->create(['role' => 'student']);

    $result = $this->service->listForStudent($user);

    expect($result)->toHaveCount(2);
    $titles = array_column($result, 'title');
    expect($titles)->toContain('For All');
    expect($titles)->toContain('For Students');
});

it('list excludes unpublished announcements', function () {
    Announcement::factory()->create([
        'is_published'    => false,
        'target_audience' => 'all',
    ]);

    $user = User::factory()->create(['role' => 'student']);
    $result = $this->service->listForStudent($user);

    expect($result)->toBe([]);
});

it('list excludes teacher-only announcements', function () {
    Announcement::factory()->create([
        'is_published'    => true,
        'target_audience' => 'teachers',
        'title'           => 'Teachers Only',
    ]);

    $user = User::factory()->create(['role' => 'student']);
    $result = $this->service->listForStudent($user);

    expect($result)->toBe([]);
});

it('list returns announcements ordered newest first', function () {
    $older = Announcement::factory()->create([
        'is_published'    => true,
        'target_audience' => 'all',
        'created_at'      => now()->subDays(2),
    ]);
    $newer = Announcement::factory()->create([
        'is_published'    => true,
        'target_audience' => 'all',
        'created_at'      => now()->subDay(),
    ]);

    $user = User::factory()->create(['role' => 'student']);
    $result = $this->service->listForStudent($user);

    expect($result)->toHaveCount(2);
    expect($result[0]['id'])->toBe($newer->id);
    expect($result[1]['id'])->toBe($older->id);
});

it('list items have expected keys', function () {
    Announcement::factory()->create([
        'is_published'    => true,
        'target_audience' => 'all',
        'excerpt'         => 'Short excerpt',
        'cover_image_url' => 'https://cdn.example.com/img.jpg',
        'type'            => 'info',
        'is_pinned'       => true,
    ]);

    $user = User::factory()->create(['role' => 'student']);
    $result = $this->service->listForStudent($user);

    expect($result[0])->toHaveKeys(['id', 'title', 'excerpt', 'type', 'is_pinned', 'cover_image_url', 'created_at']);
    expect($result[0]['is_pinned'])->toBeTrue();
    expect($result[0]['cover_image_url'])->toBe('https://cdn.example.com/img.jpg');
});

it('detail returns full content for published student-visible announcement', function () {
    $announcement = Announcement::factory()->create([
        'is_published'    => true,
        'target_audience' => 'all',
        'title'           => 'Detail Title',
        'content'         => 'Full body content here.',
        'excerpt'         => 'Short excerpt.',
        'type'            => 'warning',
    ]);

    $user = User::factory()->create(['role' => 'student']);
    $result = $this->service->detailForStudent($user, $announcement->id);

    expect($result)->not->toBeNull();
    expect($result)->toHaveKeys([
        'id', 'title', 'content', 'excerpt', 'type',
        'is_pinned', 'cover_image_url', 'target_audience', 'created_at', 'updated_at',
    ]);
    expect($result['content'])->toBe('Full body content here.');
    expect($result['title'])->toBe('Detail Title');
});

it('detail returns null for unpublished announcement', function () {
    $announcement = Announcement::factory()->unpublished()->create([
        'target_audience' => 'all',
    ]);

    $user = User::factory()->create(['role' => 'student']);
    $result = $this->service->detailForStudent($user, $announcement->id);

    expect($result)->toBeNull();
});

it('detail returns null for teacher-only announcement', function () {
    $announcement = Announcement::factory()->create([
        'is_published'    => true,
        'target_audience' => 'teachers',
    ]);

    $user = User::factory()->create(['role' => 'student']);
    $result = $this->service->detailForStudent($user, $announcement->id);

    expect($result)->toBeNull();
});

it('detail returns null for nonexistent announcement', function () {
    $user = User::factory()->create(['role' => 'student']);
    $result = $this->service->detailForStudent($user, 99999);

    expect($result)->toBeNull();
});
