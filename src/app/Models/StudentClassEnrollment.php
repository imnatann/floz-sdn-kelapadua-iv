<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StudentClassEnrollment extends Model
{
    use HasFactory;

    public const STATUS_ACTIVE          = 'active';
    public const STATUS_TRANSFERRED_OUT = 'transferred_out';
    public const STATUS_DROPPED_OUT     = 'dropped_out';
    public const STATUS_GRADUATED       = 'graduated';
    public const STATUS_PROMOTED_OUT    = 'promoted_out';
    public const STATUS_RETAINED_OUT    = 'retained_out';

    protected $fillable = [
        'student_id',
        'semester_id',
        'class_id',
        'status',
        'exit_date',
        'exit_reason',
    ];

    protected $casts = [
        'student_id'  => 'integer',
        'semester_id' => 'integer',
        'class_id'    => 'integer',
        'exit_date'   => 'date',
    ];

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    public function semester(): BelongsTo
    {
        return $this->belongsTo(Semester::class);
    }

    public function schoolClass(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class, 'class_id');
    }

    public function isActive(): bool
    {
        return $this->status === self::STATUS_ACTIVE;
    }
}
