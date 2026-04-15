<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class OfflineAssignmentQuestion extends Model
{
    use HasFactory, UsesTenantConnection;

    protected $fillable = [
        'offline_assignment_id',
        'question_text',
        'question_type',
        'options',
        'correct_answer',
        'points',
        'sort_order',
    ];

    protected $casts = [
        'options' => 'array',
        'points' => 'decimal:2',
    ];

    public function assignment(): BelongsTo
    {
        return $this->belongsTo(OfflineAssignment::class, 'offline_assignment_id');
    }

    public function answers(): HasMany
    {
        return $this->hasMany(OfflineAssignmentAnswer::class, 'question_id');
    }
}
