<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Traits\Auditable;

class Grade extends Model
{
    use HasFactory, UsesTenantConnection, Auditable;

    protected $fillable = [
        'student_id', 'subject_id', 'class_id', 'semester_id', 'teacher_id',
        'daily_test_avg', 'mid_test', 'final_test',
        'knowledge_score', 'skill_score',
        'final_score', 'predicate',
        'attitude_score', 'notes',
    ];

    protected $casts = [
        'daily_test_avg'   => 'decimal:2',
        'mid_test'         => 'decimal:2',
        'final_test'       => 'decimal:2',
        'knowledge_score'  => 'decimal:2',
        'skill_score'      => 'decimal:2',
        'final_score'      => 'decimal:2',
    ];

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    public function subject(): BelongsTo
    {
        return $this->belongsTo(Subject::class);
    }

    public function schoolClass(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class, 'class_id');
    }

    public function semester(): BelongsTo
    {
        return $this->belongsTo(Semester::class);
    }

    public function teacher(): BelongsTo
    {
        return $this->belongsTo(Teacher::class);
    }

    /**
     * Check if the grade meets the KKM standard.
     */
    public function meetsKkm(): bool
    {
        if (!$this->final_score || !$this->subject) {
            return false;
        }
        return $this->final_score >= $this->subject->kkm;
    }
}
