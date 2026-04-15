<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OfflineAssignmentFile extends Model
{
    use HasFactory, UsesTenantConnection;

    protected $fillable = [
        'offline_assignment_id',
        'file_path',
        'file_name',
        'file_type',
        'file_size',
    ];

    public function assignment(): BelongsTo
    {
        return $this->belongsTo(OfflineAssignment::class, 'offline_assignment_id');
    }
}
