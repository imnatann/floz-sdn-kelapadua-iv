<?php

namespace App\Models;

use App\Traits\UsesTenantConnection;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

use App\Traits\Auditable;

class StudentMutation extends Model
{
    use UsesTenantConnection, Auditable;

    protected $fillable = [
        'student_id',
        'type', // promotion, retention, transfer_in, transfer_out, dropout, graduated
        'from_class_id',
        'to_class_id',
        'date',
        'reason',
        'reference_number',
        'notes',
    ];

    protected $casts = [
        'date' => 'date',
    ];

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    public function fromClass(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class, 'from_class_id');
    }

    public function toClass(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class, 'to_class_id');
    }
}
