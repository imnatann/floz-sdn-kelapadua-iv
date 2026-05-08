<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class YearTransitionLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'executed_by', 'source_academic_year_id', 'target_academic_year_id',
        'executed_at', 'promoted_count', 'graduated_count',
        'retained_count', 'excluded_count', 'plan_snapshot', 'ip_address',
    ];

    protected $casts = [
        'executed_at'   => 'datetime',
        'plan_snapshot' => 'array',
    ];

    public function executor(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(User::class, 'executed_by');
    }

    public function sourceAcademicYear(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(AcademicYear::class, 'source_academic_year_id');
    }

    public function targetAcademicYear(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(AcademicYear::class, 'target_academic_year_id');
    }

    public function totalMutations(): int
    {
        return $this->promoted_count + $this->graduated_count + $this->retained_count;
    }
}
