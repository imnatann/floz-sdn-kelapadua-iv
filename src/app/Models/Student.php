<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use App\Traits\Auditable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Student extends Model
{
    use HasFactory, UsesTenantConnection, Auditable;

    public function user()
    {
        return $this->belongsTo(User::class, 'email', 'email');
    }

    protected $fillable = [
        'nis', 'nisn', 'nik', 'family_card_number', 'name', 'gender', 'birth_place', 'birth_date',
        'religion', 'address', 'parent_name', 'parent_phone', 'email',
        'class_id', 'status', 'photo_url',
    ];

    protected $casts = [
        'birth_date' => 'date',
    ];

    public function class(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class, 'class_id');
    }

    public function grades(): HasMany
    {
        return $this->hasMany(Grade::class);
    }

    public function reportCards(): HasMany
    {
        return $this->hasMany(ReportCard::class);
    }

    public function attendances(): HasMany
    {
        return $this->hasMany(Attendance::class);
    }

    public function mutations(): HasMany
    {
        return $this->hasMany(StudentMutation::class)->orderBy('date', 'desc');
    }


    public function siblings(): HasMany
    {
        // Simple implementation: students with same family_card_number
        // This is a self-referencing relationship based on a shared column, not a direct foreign key.
        // Since Laravel implementation for this might be tricky with hasMany, we use a custom query or defined relationship if family_card_number is used.
        // If family_card_number is null, it shouldn't return anything. 
        // For simplicity, we can use a scope or accessor, but let's try a relationship:
        return $this->hasMany(Student::class, 'family_card_number', 'family_card_number')
                    ->where('id', '!=', $this->id)
                    ->whereNotNull('family_card_number');
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }
}
