<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use App\Traits\Auditable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Subject extends Model
{
    use HasFactory, UsesTenantConnection, Auditable;

    protected $fillable = [
        'code', 'name', 'education_level', 'grade_level', 'kkm',
        'category', 'description', 'status',
    ];

    protected $casts = [
        'kkm'         => 'decimal:2',
        'grade_level' => 'integer',
    ];

    public function grades(): HasMany
    {
        return $this->hasMany(Grade::class);
    }

    public function teachers(): BelongsToMany
    {
        return $this->belongsToMany(Teacher::class, 'teaching_assignments')
            ->withPivot(['class_id', 'academic_year_id'])
            ->withTimestamps();
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeForLevel($query, string $level)
    {
        return $query->where('education_level', $level);
    }
}
