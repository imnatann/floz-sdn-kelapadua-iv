<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

use App\Traits\Auditable;

class TeachingAssignment extends Model
{
    use HasFactory, UsesTenantConnection, Auditable;

    protected $fillable = [
        'teacher_id',
        'subject_id',
        'class_id',
        'academic_year_id',
    ];

    protected static function booted(): void
    {
        static::created(function (TeachingAssignment $ta) {
            Meeting::generateForTeachingAssignment($ta->id);
        });
    }

    public function meetings(): HasMany
    {
        return $this->hasMany(Meeting::class)->orderBy('meeting_number');
    }

    public function teacher(): BelongsTo
    {
        return $this->belongsTo(Teacher::class);
    }

    public function subject(): BelongsTo
    {
        return $this->belongsTo(Subject::class);
    }

    public function schoolClass(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class, 'class_id');
    }

    public function academicYear(): BelongsTo
    {
        return $this->belongsTo(AcademicYear::class);
    }

    public function schedules()
    {
        return $this->hasMany(Schedule::class);
    }
}
