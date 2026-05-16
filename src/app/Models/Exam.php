<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Exam extends Model
{
    use HasFactory;

    protected $fillable = [
        'class_id', 'subject_id', 'semester_id', 'teacher_id',
        'title', 'exam_type', 'exam_date', 'max_score', 'status'
    ];

    protected $casts = [
        'exam_date'   => 'date',
        'max_score'   => 'decimal:2',
        'class_id'    => 'integer',
        'subject_id'  => 'integer',
        'semester_id' => 'integer',
        'teacher_id'  => 'integer',
    ];

    public function schoolClass(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class, 'class_id');
    }

    public function subject(): BelongsTo
    {
        return $this->belongsTo(Subject::class);
    }

    public function semester(): BelongsTo
    {
        return $this->belongsTo(Semester::class);
    }

    public function teacher(): BelongsTo
    {
        return $this->belongsTo(Teacher::class);
    }

    public function scores(): HasMany
    {
        return $this->hasMany(ExamScore::class);
    }
}
