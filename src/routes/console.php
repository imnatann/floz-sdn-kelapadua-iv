<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Backup: daily at 02:00 Asia/Jakarta (UTC+7 = 19:00 UTC previous day)
Schedule::command('backup:database')
    ->dailyAt('02:00')
    ->timezone('Asia/Jakarta')
    ->withoutOverlapping()
    ->runInBackground()
    ->onFailure(function () {
        \Illuminate\Support\Facades\Log::error('Scheduled backup:database FAILED');
    });

// Log pruning: weekly on Sundays at 03:00, delete logs older than 30 days
Schedule::command('log:prune --days=30')
    ->weekly()
    ->sundays()
    ->at('03:00')
    ->timezone('Asia/Jakarta');
