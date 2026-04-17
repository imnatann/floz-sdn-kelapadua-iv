<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Traits\UsesTenantConnection;

class TaskScore extends Model
{
    use HasFactory, UsesTenantConnection;

    protected $fillable = [
        'task_id', 'student_id', 'score', 'notes', 'submission_status'
    ];

    public const STATUS_KUMPUL = 'kumpul';
    public const STATUS_TERLAMBAT = 'terlambat';
    public const STATUS_TIDAK_KUMPUL = 'tidak_kumpul';

    public const STATUSES = [
        self::STATUS_KUMPUL,
        self::STATUS_TERLAMBAT,
        self::STATUS_TIDAK_KUMPUL,
    ];

    protected $casts = [
        'score' => 'decimal:2',
    ];

    public function task(): BelongsTo
    {
        return $this->belongsTo(Task::class);
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }
}
