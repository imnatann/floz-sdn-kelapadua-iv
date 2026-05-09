<?php

namespace App\Console\Commands;

use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class BackupDatabase extends Command
{
    protected $signature = 'backup:database
                            {--dry-run : Simulate without writing files}
                            {--type=all : daily|weekly|monthly|all}';

    protected $description = 'Dump PostgreSQL database to gzipped backup file with retention pruning';

    // Retention limits
    const KEEP_DAILY   = 7;
    const KEEP_WEEKLY  = 4;
    const KEEP_MONTHLY = 6;

    public function handle(): int
    {
        $dryRun = $this->option('dry-run');
        $type   = $this->option('type');

        $now      = Carbon::now('Asia/Jakarta');
        $filename = $this->buildFilename($type === 'all' ? 'daily' : $type);

        if ($dryRun) {
            $this->info("[DRY-RUN] Would create: backups/daily/{$filename}");
            $this->info("[DRY-RUN] Would prune daily→7, weekly→4, monthly→6");
            return 0;
        }

        // Determine which directories to write based on date
        $targets = $this->resolveTargets($now);

        foreach ($targets as $dir) {
            Storage::disk('local')->makeDirectory("backups/{$dir}");
            $path = "backups/{$dir}/" . $this->buildFilename($dir);
            $fullPath = storage_path("app/{$path}");

            if (!$this->runPgDump($fullPath)) {
                $this->error("pg_dump failed for {$dir} backup.");
                Log::error("BackupDatabase: pg_dump failed", ['path' => $fullPath]);
                return 1;
            }

            $this->info("Backup created: {$path}");
            Log::info("BackupDatabase: created {$path}");
        }

        // Prune after successful write
        $this->pruneDirectory('backups/daily',   self::KEEP_DAILY);
        $this->pruneDirectory('backups/weekly',  self::KEEP_WEEKLY);
        $this->pruneDirectory('backups/monthly', self::KEEP_MONTHLY);

        return 0;
    }

    public function buildFilename(string $type): string
    {
        return 'floz_' . Carbon::now('Asia/Jakarta')->format('Y-m-d_H-i') . '.sql.gz';
    }

    /**
     * Determine which backup directories to write based on current date.
     * - Always: daily
     * - Monday: also weekly
     * - 1st of month: also monthly
     */
    protected function resolveTargets(Carbon $now): array
    {
        $targets = ['daily'];
        if ($now->dayOfWeek === Carbon::MONDAY) {
            $targets[] = 'weekly';
        }
        if ($now->day === 1) {
            $targets[] = 'monthly';
        }
        return $targets;
    }

    /**
     * Shell out to pg_dump. Returns true on success.
     * Protected so tests can mock it.
     */
    protected function runPgDump(string $outputPath): bool
    {
        // Check pg_dump is available
        exec('which pg_dump', $whichOut, $whichExit);
        if ($whichExit !== 0) {
            $this->error('pg_dump not found. Install postgresql-client (apt) or document your image build.');
            return false;
        }

        $host   = config('database.connections.pgsql.host');
        $port   = config('database.connections.pgsql.port', 5432);
        $db     = config('database.connections.pgsql.database');
        $user   = config('database.connections.pgsql.username');
        $pass   = config('database.connections.pgsql.password');

        $cmd = sprintf(
            'PGPASSWORD=%s pg_dump --clean --if-exists -h %s -p %s -U %s %s | gzip > %s',
            escapeshellarg((string) $pass),
            escapeshellarg((string) $host),
            escapeshellarg((string) $port),
            escapeshellarg((string) $user),
            escapeshellarg((string) $db),
            escapeshellarg($outputPath)
        );

        exec($cmd, $output, $exitCode);
        return $exitCode === 0;
    }

    /**
     * Prune oldest files in a storage directory, keeping $keep most recent.
     * Returns count of deleted files.
     */
    public function pruneDirectory(string $storageDir, int $keep): int
    {
        $files = Storage::disk('local')->files($storageDir);
        // Sort ascending (oldest first by filename — filenames are date-stamped)
        sort($files);

        $toDelete = array_slice($files, 0, max(0, count($files) - $keep));
        foreach ($toDelete as $file) {
            Storage::disk('local')->delete($file);
        }

        return count($toDelete);
    }
}
