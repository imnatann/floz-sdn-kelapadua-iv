<?php

namespace App\Traits;

use App\Models\AuditLog;
use Illuminate\Support\Facades\Auth;

trait Auditable
{
    public static function bootAuditable()
    {
        static::created(function ($model) {
            static::audit('created', $model);
        });

        static::updated(function ($model) {
            static::audit('updated', $model);
        });

        static::deleted(function ($model) {
            static::audit('deleted', $model);
        });
    }

    protected static function audit($event, $model)
    {
        // Skip if no user logged in (e.g. seeder or console), unless we want to track system actions too
        // For now, let's track everything, but user_id might be null
        
        $oldValues = null;
        $newValues = null;

        if ($event === 'updated') {
            $oldValues = $model->getOriginal();
            $newValues = $model->getAttributes();
            
            // Remove hidden attributes
            foreach ($model->getHidden() as $hidden) {
                unset($oldValues[$hidden]);
                unset($newValues[$hidden]);
            }
            
            // Only keep changed attributes
            $changes = $model->getChanges();
            $oldValues = array_intersect_key($oldValues, $changes);
            $newValues = array_intersect_key($newValues, $changes);
        } elseif ($event === 'created') {
            $newValues = $model->getAttributes();
             foreach ($model->getHidden() as $hidden) {
                unset($newValues[$hidden]);
            }
        } elseif ($event === 'deleted') {
            $oldValues = $model->getOriginal();
            foreach ($model->getHidden() as $hidden) {
                unset($oldValues[$hidden]);
            }
        }

        AuditLog::create([
            'user_id' => Auth::id(),
            'event' => $event,
            'method' => request()->method(),
            'auditable_type' => get_class($model),
            'auditable_id' => $model->id,
            'old_values' => $oldValues,
            'new_values' => $newValues,
            'url' => request()->fullUrl(),
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
        ]);
    }
}
