<?php

namespace App\Console\Commands;

use Carbon\Carbon;
use Illuminate\Console\Command;

class LogPrune extends Command
{
    protected $signature = 'log:prune {--days=30 : Delete log files older than N days}';
    protected $description = 'Delete Laravel log files older than --days days from storage/logs';

    public function handle(): int
    {
        $days   = (int) $this->option('days');
        $dir    = storage_path('logs');
        $cutoff = Carbon::now()->subDays($days);
        $deleted = 0;

        foreach (glob("{$dir}/*.log") as $file) {
            if (filemtime($file) < $cutoff->timestamp) {
                unlink($file);
                $deleted++;
                $this->line("Deleted: " . basename($file));
            }
        }

        $this->info("Pruned {$deleted} log file(s) older than {$days} days.");
        return 0;
    }
}
