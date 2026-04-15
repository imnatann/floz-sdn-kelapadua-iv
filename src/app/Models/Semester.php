<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Semester extends Model
{
    use HasFactory, UsesTenantConnection;

    protected $fillable = ['academic_year_id', 'semester_number', 'start_date', 'end_date', 'is_active'];

    protected $casts = [
        'start_date'      => 'date',
        'end_date'        => 'date',
        'is_active'       => 'boolean',
        'semester_number' => 'integer',
    ];

    public function academicYear(): BelongsTo
    {
        return $this->belongsTo(AcademicYear::class);
    }

    public function grades(): HasMany
    {
        return $this->hasMany(Grade::class);
    }

    public function reportCards(): HasMany
    {
        return $this->hasMany(ReportCard::class);
    }

    public function label(): string
    {
        return "Semester {$this->semester_number} - {$this->academicYear->name}";
    }
}
