<?php

namespace App\Models;

use App\Traits\HasAcademicYear;
use App\Traits\UsesTenantConnection;
use App\Traits\Auditable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class SchoolClass extends Model
{
    use HasFactory, UsesTenantConnection, HasAcademicYear, Auditable;

    protected $table = 'classes';

    protected $fillable = [
        'name', 'grade_level', 'academic_year_id', 'homeroom_teacher_id',
        'max_students', 'status',
    ];

    protected $casts = [
        'grade_level'   => 'integer',
        'max_students'  => 'integer',
    ];

    public function academicYear(): BelongsTo
    {
        return $this->belongsTo(AcademicYear::class);
    }

    public function homeroomTeacher(): BelongsTo
    {
        return $this->belongsTo(Teacher::class, 'homeroom_teacher_id');
    }

    public function students(): HasMany
    {
        return $this->hasMany(Student::class, 'class_id');
    }

    public function grades(): HasMany
    {
        return $this->hasMany(Grade::class, 'class_id');
    }

    public function reportCards(): HasMany
    {
        return $this->hasMany(ReportCard::class, 'class_id');
    }

    public function subjects(): BelongsToMany
    {
        return $this->belongsToMany(Subject::class, 'teaching_assignments', 'class_id', 'subject_id')
            ->withPivot(['teacher_id', 'academic_year_id'])
            ->withTimestamps();
    }

    public function teachingAssignments(): HasMany
    {
        return $this->hasMany(TeachingAssignment::class, 'class_id');
    }

    public function getStudentCountAttribute(): int
    {
        return $this->students()->count();
    }
}
