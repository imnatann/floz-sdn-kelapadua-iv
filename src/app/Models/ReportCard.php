<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

use App\Traits\Auditable;

class ReportCard extends Model
{
    use HasFactory, UsesTenantConnection, Auditable;

    protected $fillable = [
        'student_id', 'class_id', 'semester_id', 'rank',
        'report_type', 'extracurricular',
        'total_score', 'average_score',
        'attendance_present', 'attendance_sick', 'attendance_permit', 'attendance_absent',
        'achievements', 'notes', 'behavior_notes',
        'homeroom_comment', 'principal_comment',
        'status', 'published_at', 'pdf_url',
    ];

    protected $casts = [
        'total_score'       => 'decimal:2',
        'average_score'     => 'decimal:2',
        'rank'              => 'integer',
        'attendance_present' => 'integer',
        'attendance_sick'    => 'integer',
        'attendance_permit'  => 'integer',
        'attendance_absent'  => 'integer',
        'published_at'      => 'datetime',
        'extracurricular'   => 'array',
    ];

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    public function schoolClass(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class, 'class_id');
    }

    public function semester(): BelongsTo
    {
        return $this->belongsTo(Semester::class);
    }

    public function isDraft(): bool
    {
        return $this->status === 'draft';
    }

    public function isPublished(): bool
    {
        return $this->status === 'published';
    }

    public function getTotalAttendanceAttribute(): int
    {
        return $this->attendance_present + $this->attendance_sick
             + $this->attendance_permit + $this->attendance_absent;
    }
}
