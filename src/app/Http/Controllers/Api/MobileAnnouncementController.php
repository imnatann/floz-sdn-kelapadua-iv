<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use Illuminate\Http\Request;

class MobileAnnouncementController extends Controller
{
    /**
     * GET /api/v1/announcements
     * List published announcements.
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 15);

        $announcements = Announcement::where('is_published', true)
            ->latest()
            ->paginate($perPage)
            ->through(fn($a) => [
                'id'         => $a->id,
                'title'      => $a->title,
                'content'    => \Illuminate\Support\Str::limit(strip_tags($a->content), 200),
                'created_at' => $a->created_at->toISOString(),
                'updated_at' => $a->updated_at->toISOString(),
            ]);

        return response()->json($announcements);
    }

    /**
     * GET /api/v1/announcements/{id}
     * Detail of a single announcement.
     */
    public function show(Request $request, $id)
    {
        $announcement = Announcement::where('is_published', true)->findOrFail($id);

        return response()->json([
            'announcement' => [
                'id'         => $announcement->id,
                'title'      => $announcement->title,
                'content'    => $announcement->content,
                'created_at' => $announcement->created_at->toISOString(),
                'updated_at' => $announcement->updated_at->toISOString(),
            ],
        ]);
    }
}
