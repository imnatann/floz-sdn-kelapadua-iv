<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OfflineSubmissionFile extends Model
{
    use HasFactory, UsesTenantConnection;

    protected $fillable = [
        'submission_id',
        'file_path',
        'file_name',
        'file_type',
        'file_size',
    ];

    public function submission(): BelongsTo
    {
        return $this->belongsTo(OfflineAssignmentSubmission::class, 'submission_id');
    }
}
