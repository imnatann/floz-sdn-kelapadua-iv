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
        'task_id', 'student_id', 'score', 'notes'
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
