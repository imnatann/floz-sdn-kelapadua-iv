<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Traits\UsesTenantConnection;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Task extends Model
{
    use HasFactory, UsesTenantConnection;

    protected $fillable = [
        'class_id', 'subject_id', 'semester_id', 'teacher_id',
        'title', 'description', 'task_date', 'due_date', 'max_score', 'status'
    ];

    protected $casts = [
        'task_date' => 'date',
        'due_date' => 'date',
        'max_score' => 'decimal:2',
    ];

    public function schoolClass(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class, 'class_id');
    }

    public function subject(): BelongsTo
    {
        return $this->belongsTo(Subject::class);
    }

    public function semester(): BelongsTo
    {
        return $this->belongsTo(Semester::class);
    }

    public function teacher(): BelongsTo
    {
        return $this->belongsTo(Teacher::class);
    }

    public function scores(): HasMany
    {
        return $this->hasMany(TaskScore::class);
    }
}
