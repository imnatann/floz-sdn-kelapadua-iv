<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MeetingMaterial extends Model
{
    use HasFactory, UsesTenantConnection;

    protected $fillable = [
        'meeting_id',
        'title',
        'type',
        'content',
        'file_path',
        'file_name',
        'file_size',
        'url',
        'sort_order',
    ];

    protected $casts = [
        'file_size' => 'integer',
        'sort_order' => 'integer',
    ];

    public function meeting(): BelongsTo
    {
        return $this->belongsTo(Meeting::class);
    }

    public function isFile(): bool
    {
        return $this->type === 'file';
    }

    public function isLink(): bool
    {
        return $this->type === 'link';
    }

    public function isText(): bool
    {
        return $this->type === 'text';
    }
}
