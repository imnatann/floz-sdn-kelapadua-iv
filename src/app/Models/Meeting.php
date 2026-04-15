<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Meeting extends Model
{
    use HasFactory, UsesTenantConnection;

    protected $fillable = [
        'teaching_assignment_id',
        'meeting_number',
        'title',
        'description',
        'is_locked',
    ];

    protected $casts = [
        'is_locked' => 'boolean',
        'meeting_number' => 'integer',
    ];

    public function teachingAssignment(): BelongsTo
    {
        return $this->belongsTo(TeachingAssignment::class);
    }

    public function materials(): HasMany
    {
        return $this->hasMany(MeetingMaterial::class)->orderBy('sort_order');
    }

    public function assignments(): HasMany
    {
        return $this->hasMany(OfflineAssignment::class);
    }

    /**
     * Check if this meeting is an exam (UTS or UAS)
     */
    public function isExam(): bool
    {
        return $this->meeting_number > 14;
    }

    /**
     * Check if this is UTS (Ujian Tengah Semester)
     */
    public function isUts(): bool
    {
        return $this->meeting_number === 15;
    }

    /**
     * Check if this is UAS (Ujian Akhir Semester)
     */
    public function isUas(): bool
    {
        return $this->meeting_number === 16;
    }

    /**
     * Generate default meetings for a teaching assignment
     */
    public static function generateForTeachingAssignment(int $teachingAssignmentId): void
    {
        $meetings = [];
        for ($i = 1; $i <= 14; $i++) {
            $meetings[] = [
                'teaching_assignment_id' => $teachingAssignmentId,
                'meeting_number' => $i,
                'title' => "Pertemuan {$i}",
                'is_locked' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ];
        }
        // UTS
        $meetings[] = [
            'teaching_assignment_id' => $teachingAssignmentId,
            'meeting_number' => 15,
            'title' => 'Ujian Tengah Semester',
            'is_locked' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ];
        // UAS
        $meetings[] = [
            'teaching_assignment_id' => $teachingAssignmentId,
            'meeting_number' => 16,
            'title' => 'Ujian Akhir Semester',
            'is_locked' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ];

        static::insert($meetings);
    }
}
