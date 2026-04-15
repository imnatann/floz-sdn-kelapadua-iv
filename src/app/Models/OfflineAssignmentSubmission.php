<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class OfflineAssignmentSubmission extends Model
{
    use HasFactory, UsesTenantConnection;

    protected $fillable = [
        'offline_assignment_id',
        'student_id',
        'submitted_at',
        'grade',
        'correction_note',
        'correction_file',
        'answer_text',
        'answer_link',
    ];

    protected $casts = [
        'submitted_at' => 'datetime',
        'grade' => 'decimal:2',
    ];

    public function assignment(): BelongsTo
    {
        return $this->belongsTo(OfflineAssignment::class, 'offline_assignment_id');
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    public function files(): HasMany
    {
        return $this->hasMany(OfflineSubmissionFile::class, 'submission_id');
    }

    public function answers(): HasMany
    {
        return $this->hasMany(OfflineAssignmentAnswer::class, 'submission_id');
    }
}
