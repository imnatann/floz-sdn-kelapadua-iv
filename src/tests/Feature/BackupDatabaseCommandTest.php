<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class BackupDatabaseCommandTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
    }

    /** @test */
    public function it_exits_zero_on_dry_run(): void
    {
        // Dry-run never calls pg_dump — just verifies command is registered and exits 0
        $this->artisan('backup:database --dry-run')
            ->expectsOutputToContain('[DRY-RUN]')
            ->assertExitCode(0);
    }

    /** @test */
    public function dry_run_does_not_write_any_files(): void
    {
        $this->artisan('backup:database --dry-run')
            ->assertExitCode(0);

        Storage::disk('local')->assertMissing('backups/daily');
    }

    /** @test */
    public function backup_filename_matches_expected_pattern(): void
    {
        $command = new \App\Console\Commands\BackupDatabase();
        $filename = $command->buildFilename('daily');

        $this->assertMatchesRegularExpression(
            '/^floz_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}\.sql\.gz$/',
            $filename
        );
    }

    /** @test */
    public function retention_keeps_at_most_7_daily_files(): void
    {
        // Seed 10 fake daily backup files (oldest first)
        Storage::disk('local')->makeDirectory('backups/daily');
        for ($i = 10; $i >= 1; $i--) {
            $date = now()->subDays($i)->format('Y-m-d_H-i');
            Storage::disk('local')->put("backups/daily/floz_{$date}.sql.gz", 'fake');
        }

        $command = new \App\Console\Commands\BackupDatabase();
        $deleted = $command->pruneDirectory('backups/daily', 7);

        $this->assertEquals(3, $deleted); // 10 - 7 = 3 pruned
        $this->assertCount(7, Storage::disk('local')->files('backups/daily'));
    }

    /** @test */
    public function retention_keeps_at_most_4_weekly_files(): void
    {
        Storage::disk('local')->makeDirectory('backups/weekly');
        for ($i = 6; $i >= 1; $i--) {
            $date = now()->subWeeks($i)->format('Y-m-d_H-i');
            Storage::disk('local')->put("backups/weekly/floz_{$date}.sql.gz", 'fake');
        }

        $command = new \App\Console\Commands\BackupDatabase();
        $deleted = $command->pruneDirectory('backups/weekly', 4);

        $this->assertEquals(2, $deleted);
        $this->assertCount(4, Storage::disk('local')->files('backups/weekly'));
    }
}
