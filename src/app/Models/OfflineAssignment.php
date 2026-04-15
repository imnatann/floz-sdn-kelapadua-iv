<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class OfflineAssignment extends Model
{
    use HasFactory, UsesTenantConnection;

    protected $fillable = [
        'teacher_id',
        'subject_id',
        'meeting_id',
        'title',
        'description',
        'due_date',
        'status',
        'type',
        'created_by',
    ];

    protected $casts = [
        'due_date' => 'datetime',
    ];

    public function meeting(): BelongsTo
    {
        return $this->belongsTo(Meeting::class);
    }

    public function teacher(): BelongsTo
    {
        return $this->belongsTo(Teacher::class);
    }

    public function subject(): BelongsTo
    {
        return $this->belongsTo(Subject::class);
    }

    public function classes(): BelongsToMany
    {
        return $this->belongsToMany(SchoolClass::class, 'offline_assignment_classes', 'offline_assignment_id', 'class_id')
                    ->withTimestamps();
    }

    public function files(): HasMany
    {
        return $this->hasMany(OfflineAssignmentFile::class);
    }

    public function submissions(): HasMany
    {
        return $this->hasMany(OfflineAssignmentSubmission::class);
    }

    public function questions(): HasMany
    {
        return $this->hasMany(OfflineAssignmentQuestion::class)->orderBy('sort_order');
    }

    public function isQuiz(): bool
    {
        return $this->type === 'quiz';
    }

    public function isManual(): bool
    {
        return $this->type === 'manual';
    }
}
