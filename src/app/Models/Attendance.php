<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

use App\Traits\Auditable;

class Attendance extends Model
{
    use HasFactory, UsesTenantConnection, Auditable;

    protected $table = 'attendance';

    protected $fillable = [
        'student_id', 'class_id', 'subject_id', 'semester_id', 'recorded_by',
        'date', 'meeting_number', 'status', 'notes'
    ];

    protected $casts = [
        'date' => 'date',
        'meeting_number' => 'integer',
    ];

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

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

    public function recordedBy(): BelongsTo
    {
        return $this->belongsTo(Teacher::class, 'recorded_by');
    }
}
