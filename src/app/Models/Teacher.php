<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use App\Traits\Auditable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Teacher extends Model
{
    use HasFactory, UsesTenantConnection, Auditable;

    protected $fillable = [
        'nip', 'nuptk', 'name', 'gender', 'birth_place', 'birth_date',
        'email', 'phone', 'address', 'is_homeroom', 'photo_url', 'status', 'user_id',
    ];

    protected $casts = [
        'birth_date'  => 'date',
        'is_homeroom' => 'boolean',
    ];

    public function classes(): HasMany
    {
        return $this->hasMany(SchoolClass::class, 'homeroom_teacher_id');
    }

    public function grades(): HasMany
    {
        return $this->hasMany(Grade::class);
    }

    public function user(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(\App\Models\User::class);
    }

    public function subjects(): BelongsToMany
    {
        return $this->belongsToMany(Subject::class, 'teaching_assignments')
            ->withPivot(['class_id', 'academic_year_id'])
            ->withTimestamps();
    }

    public function teachingAssignments(): HasMany
    {
        return $this->hasMany(TeachingAssignment::class);
    }

    public function getFullIdentificationAttribute(): string
    {
        $id = $this->nip ? "NIP: {$this->nip}" : ($this->nuptk ? "NUPTK: {$this->nuptk}" : '');
        return $id ? "{$this->name} ({$id})" : $this->name;
    }
}
