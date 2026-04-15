<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OfflineAssignmentAnswer extends Model
{
    use HasFactory, UsesTenantConnection;

    protected $fillable = [
        'submission_id',
        'question_id',
        'answer',
        'is_correct',
        'points_earned',
    ];

    protected $casts = [
        'is_correct' => 'boolean',
        'points_earned' => 'decimal:2',
    ];

    public function submission(): BelongsTo
    {
        return $this->belongsTo(OfflineAssignmentSubmission::class, 'submission_id');
    }

    public function question(): BelongsTo
    {
        return $this->belongsTo(OfflineAssignmentQuestion::class, 'question_id');
    }
}
