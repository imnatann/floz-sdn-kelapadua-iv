<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use Illuminate\Http\Request;
use Inertia\Inertia;
use App\Models\User;

class AuditLogController extends Controller
{
    public function index(Request $request)
    {
        $filters = $request->only(['search', 'event', 'date']);
        
        $logs = AuditLog::with('user')
            ->when($request->search, function ($query, $search) {
                $query->where(function ($q) use ($search) {
                    $q->where('event', 'like', "%{$search}%")
                      ->orWhere('auditable_type', 'like', "%{$search}%")
                      ->orWhereHas('user', function ($u) use ($search) {
                          $u->where('name', 'like', "%{$search}%");
                      });
                });
            })
            ->when($request->event, function ($query, $event) {
                if ($event !== 'all') {
                    $query->where('event', $event);
                }
            })
            ->when($request->date, function ($query, $date) {
                $query->whereDate('created_at', $date);
            })
            ->latest()
            ->paginate(20)
            ->withQueryString();

        return Inertia::render('Tenant/AuditLogs/Index', [
            'logs' => $logs,
            'filters' => $filters,
        ]);
    }
}
