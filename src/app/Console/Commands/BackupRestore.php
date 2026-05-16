<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class BackupRestore extends Command
{
    protected $signature = 'backup:restore {file : Path to .sql.gz backup file} {--dry-run}';
    protected $description = 'Restore a PostgreSQL backup from a gzipped dump file';

    public function handle(): int
    {
        $file   = $this->argument('file');
        $dryRun = $this->option('dry-run');

        if (!file_exists($file)) {
            $this->error("File not found: {$file}");
            return 1;
        }

        if (!str_ends_with($file, '.sql.gz')) {
            $this->error("Expected a .sql.gz file.");
            return 1;
        }

        $tmpFile = sys_get_temp_dir() . '/floz_restore_' . time() . '.sql';

        // Decompress
        $decompressCmd = sprintf('gunzip -c %s > %s', escapeshellarg($file), escapeshellarg($tmpFile));
        exec($decompressCmd, $output, $exitCode);
        if ($exitCode !== 0) {
            $this->error("Failed to decompress backup.");
            return 1;
        }

        if ($dryRun) {
            // Validate SQL header
            $header = shell_exec("head -5 " . escapeshellarg($tmpFile));
            $this->info("[DRY-RUN] SQL header:\n{$header}");
            @unlink($tmpFile);
            return 0;
        }

        $host = config('database.connections.pgsql.host');
        $port = config('database.connections.pgsql.port', 5432);
        $db   = config('database.connections.pgsql.database');
        $user = config('database.connections.pgsql.username');
        $pass = config('database.connections.pgsql.password');

        $restoreCmd = sprintf(
            'PGPASSWORD=%s psql -h %s -p %s -U %s %s < %s',
            escapeshellarg((string) $pass),
            escapeshellarg((string) $host),
            escapeshellarg((string) $port),
            escapeshellarg((string) $user),
            escapeshellarg((string) $db),
            escapeshellarg($tmpFile)
        );

        $this->warn("Restoring into database '{$db}' — THIS OVERWRITES EXISTING DATA.");
        if (!$this->confirm('Are you sure?')) {
            $this->info('Aborted.');
            @unlink($tmpFile);
            return 0;
        }

        exec($restoreCmd, $restoreOutput, $restoreExit);
        @unlink($tmpFile);

        if ($restoreExit !== 0) {
            $this->error("psql restore failed. Check output above.");
            return 1;
        }

        $this->info("Restore complete.");
        return 0;
    }
}
