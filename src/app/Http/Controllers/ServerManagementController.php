<?php

namespace App\Http\Controllers;

use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Inertia\Inertia;
use Inertia\Response;
use Throwable;

class ServerManagementController extends Controller
{
    public function index(): Response
    {
        $database = $this->databaseStats();
        $cache = $this->cacheStats();
        $queue = $this->queueStats();
        $partition = $this->partitionStats(base_path());
        $php = $this->phpProcessStats();
        $logs = $this->logStats();

        $services = [
            $database['health'],
            $cache['health'],
            $queue['health'],
            $partition['health'],
            $logs,
        ];

        $summaryStatus = collect($services)->contains(fn ($service) => $service['status'] === 'error')
            ? 'error'
            : (collect($services)->contains(fn ($service) => $service['status'] === 'warning') ? 'warning' : 'ok');

        return Inertia::render('ServerManagement/Index', [
            'summary' => [
                'status' => $summaryStatus,
                'generated_at' => Carbon::now('Asia/Jakarta')->format('d M Y H:i:s'),
                'hostname' => gethostname() ?: 'Unknown host',
                'environment' => app()->environment(),
                'scope' => 'Partisi project di shared cPanel',
            ],
            'resources' => [
                'partition' => $partition,
                'php' => $php,
            ],
            'database' => $database['data'],
            'cache' => $cache['data'],
            'queue' => $queue['data'],
            'runtime' => $this->runtimeStats(),
            'directories' => $this->directoryStats(),
            'services' => $services,
        ]);
    }

    private function phpProcessStats(): array
    {
        $usage = memory_get_usage(true);
        $peak = memory_get_peak_usage(true);

        return [
            'memory_usage_bytes' => $usage,
            'memory_peak_bytes' => $peak,
            'memory_usage' => $this->formatBytes($usage),
            'memory_peak' => $this->formatBytes($peak),
            'memory_limit' => ini_get('memory_limit') ?: 'Unknown',
            'upload_limit' => ini_get('upload_max_filesize') ?: 'Unknown',
            'post_limit' => ini_get('post_max_size') ?: 'Unknown',
        ];
    }

    private function partitionStats(string $path): array
    {
        $total = @disk_total_space($path);
        $free = @disk_free_space($path);
        $used = ($total && $free !== false) ? $total - $free : null;
        $usedPercent = ($total && $used !== null) ? round(($used / $total) * 100, 1) : null;

        $status = match (true) {
            $usedPercent === null => 'warning',
            $usedPercent >= 90 => 'error',
            $usedPercent >= 75 => 'warning',
            default => 'ok',
        };

        return [
            'path' => $path,
            'total_bytes' => $total ?: null,
            'free_bytes' => $free !== false ? $free : null,
            'used_bytes' => $used,
            'used_percent' => $usedPercent,
            'total' => $total ? $this->formatBytes($total) : 'Tidak tersedia',
            'free' => $free !== false ? $this->formatBytes($free) : 'Tidak tersedia',
            'used' => $used !== null ? $this->formatBytes($used) : 'Tidak tersedia',
            'health' => [
                'name' => 'Partisi project',
                'status' => $status,
                'value' => $usedPercent !== null ? $usedPercent.'% terpakai' : 'Tidak tersedia',
                'detail' => $usedPercent !== null
                    ? 'Dibaca dari filesystem tempat '.base_path().' berada. Sisa '.$this->formatBytes((float) $free)
                    : 'Server tidak memberi data partisi project.',
            ],
        ];
    }

    private function databaseStats(): array
    {
        $startedAt = microtime(true);
        $connection = DB::connection();
        $driver = $connection->getDriverName();
        $databaseName = (string) config("database.connections.{$connection->getName()}.database", 'default');

        try {
            $connection->select('select 1');
            $latency = round((microtime(true) - $startedAt) * 1000, 1);
            $size = $this->databaseSize($driver, $databaseName);

            return [
                'data' => [
                    'status' => 'ok',
                    'driver' => $driver,
                    'database' => basename($databaseName),
                    'latency_ms' => $latency,
                    'size_bytes' => $size,
                    'size' => $size !== null ? $this->formatBytes($size) : 'Tidak tersedia',
                ],
                'health' => [
                    'name' => 'Database',
                    'status' => 'ok',
                    'value' => $latency.' ms',
                    'detail' => strtoupper($driver).' tersambung.',
                ],
            ];
        } catch (Throwable $exception) {
            return [
                'data' => [
                    'status' => 'error',
                    'driver' => $driver,
                    'database' => basename($databaseName),
                    'latency_ms' => null,
                    'size_bytes' => null,
                    'size' => 'Tidak tersedia',
                ],
                'health' => [
                    'name' => 'Database',
                    'status' => 'error',
                    'value' => 'Gagal',
                    'detail' => $exception->getMessage(),
                ],
            ];
        }
    }

    private function databaseSize(string $driver, string $databaseName): ?float
    {
        try {
            return match ($driver) {
                'pgsql' => (float) DB::selectOne('select pg_database_size(current_database()) as size')->size,
                'mysql', 'mariadb' => (float) DB::selectOne(
                    'select coalesce(sum(data_length + index_length), 0) as size from information_schema.tables where table_schema = database()'
                )->size,
                'sqlite' => is_file($databaseName) ? (float) filesize($databaseName) : null,
                default => null,
            };
        } catch (Throwable) {
            return null;
        }
    }

    private function cacheStats(): array
    {
        $driver = config('cache.default', 'file');

        try {
            Cache::put('server_management_probe', 'ok', now()->addMinute());

            return [
                'data' => [
                    'status' => 'ok',
                    'driver' => $driver,
                ],
                'health' => [
                    'name' => 'Cache',
                    'status' => 'ok',
                    'value' => strtoupper((string) $driver),
                    'detail' => 'Cache bisa ditulis.',
                ],
            ];
        } catch (Throwable $exception) {
            return [
                'data' => [
                    'status' => 'warning',
                    'driver' => $driver,
                ],
                'health' => [
                    'name' => 'Cache',
                    'status' => 'warning',
                    'value' => strtoupper((string) $driver),
                    'detail' => $exception->getMessage(),
                ],
            ];
        }
    }

    private function queueStats(): array
    {
        $connection = config('queue.default', 'sync');
        $failedJobs = null;
        $status = 'ok';
        $detail = 'Tidak ada failed job terbaru.';

        try {
            if (Schema::hasTable('failed_jobs')) {
                $failedJobs = DB::table('failed_jobs')
                    ->where('failed_at', '>=', now()->subHours(24))
                    ->count();

                if ($failedJobs > 0) {
                    $status = $failedJobs > 10 ? 'error' : 'warning';
                    $detail = $failedJobs.' failed job dalam 24 jam terakhir.';
                }
            }
        } catch (Throwable $exception) {
            $status = 'warning';
            $detail = $exception->getMessage();
        }

        return [
            'data' => [
                'status' => $status,
                'connection' => $connection,
                'failed_jobs_24h' => $failedJobs,
            ],
            'health' => [
                'name' => 'Queue',
                'status' => $status,
                'value' => strtoupper((string) $connection),
                'detail' => $detail,
            ],
        ];
    }

    private function logStats(): array
    {
        $path = storage_path('logs/laravel.log');
        $exists = is_file($path);
        $size = $exists ? filesize($path) : 0;
        $status = $size > 100 * 1024 * 1024 ? 'warning' : 'ok';

        return [
            'name' => 'Log aplikasi',
            'status' => $status,
            'value' => $exists ? $this->formatBytes((float) $size) : 'Belum ada log',
            'detail' => $exists
                ? 'Update terakhir '.Carbon::createFromTimestamp(filemtime($path), 'Asia/Jakarta')->format('d M Y H:i')
                : 'File log belum dibuat.',
        ];
    }

    private function runtimeStats(): array
    {
        return [
            ['label' => 'PHP', 'value' => PHP_VERSION],
            ['label' => 'Laravel', 'value' => app()->version()],
            ['label' => 'Environment', 'value' => app()->environment()],
            ['label' => 'Debug', 'value' => config('app.debug') ? 'Aktif' : 'Nonaktif'],
            ['label' => 'Timezone', 'value' => config('app.timezone')],
            ['label' => 'Server', 'value' => request()->server('SERVER_SOFTWARE', 'Tidak tersedia')],
            ['label' => 'Upload limit', 'value' => ini_get('upload_max_filesize') ?: 'Tidak tersedia'],
            ['label' => 'Post limit', 'value' => ini_get('post_max_size') ?: 'Tidak tersedia'],
        ];
    }

    private function directoryStats(): array
    {
        $directories = [
            ['label' => 'Storage app', 'path' => storage_path('app')],
            ['label' => 'Log aplikasi', 'path' => storage_path('logs')],
            ['label' => 'Build assets', 'path' => public_path('build')],
            ['label' => 'Bootstrap cache', 'path' => base_path('bootstrap/cache')],
        ];

        return collect($directories)
            ->map(function (array $directory) {
                $size = $this->directorySize($directory['path']);

                return [
                    ...$directory,
                    'size_bytes' => $size,
                    'size' => $size !== null ? $this->formatBytes($size) : 'Tidak tersedia',
                    'writable' => is_writable($directory['path']),
                ];
            })
            ->all();
    }

    private function directorySize(string $path): ?float
    {
        if (! is_dir($path)) {
            return null;
        }

        $size = 0.0;

        try {
            $iterator = new \RecursiveIteratorIterator(
                new \RecursiveDirectoryIterator($path, \FilesystemIterator::SKIP_DOTS)
            );

            foreach ($iterator as $file) {
                if ($file->isFile()) {
                    $size += $file->getSize();
                }
            }

            return $size;
        } catch (Throwable) {
            return null;
        }
    }

    private function formatBytes(float $bytes): string
    {
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        $value = max(0, $bytes);
        $unit = 0;

        while ($value >= 1024 && $unit < count($units) - 1) {
            $value /= 1024;
            $unit++;
        }

        return ($unit === 0 ? number_format($value, 0) : number_format($value, 1)).' '.$units[$unit];
    }
}
