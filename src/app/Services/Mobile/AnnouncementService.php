<?php

namespace App\Services\Mobile;

use App\Models\Announcement;
use App\Models\User;
use Illuminate\Support\Str;

class AnnouncementService
{
    public function listForStudent(User $user): array
    {
        return Announcement::where('is_published', true)
            ->whereIn('target_audience', ['all', 'students'])
            ->latest()
            ->get()
            ->map(fn (Announcement $a) => [
                'id'              => $a->id,
                'title'           => $a->title,
                'excerpt'         => $a->excerpt ?? Str::limit(strip_tags($a->content), 200),
                'type'            => $a->type,
                'is_pinned'       => (bool) $a->is_pinned,
                'cover_image_url' => $a->cover_image_url,
                'created_at'      => $a->created_at->toIso8601String(),
            ])
            ->all();
    }

    public function detailForStudent(User $user, int $id): ?array
    {
        $announcement = Announcement::where('id', $id)
            ->where('is_published', true)
            ->whereIn('target_audience', ['all', 'students'])
            ->first();

        if (! $announcement) {
            return null;
        }

        return [
            'id'              => $announcement->id,
            'title'           => $announcement->title,
            'content'         => $announcement->content,
            'excerpt'         => $announcement->excerpt,
            'type'            => $announcement->type,
            'is_pinned'       => (bool) $announcement->is_pinned,
            'cover_image_url' => $announcement->cover_image_url,
            'target_audience' => $announcement->target_audience,
            'created_at'      => $announcement->created_at->toIso8601String(),
            'updated_at'      => $announcement->updated_at->toIso8601String(),
        ];
    }
}
