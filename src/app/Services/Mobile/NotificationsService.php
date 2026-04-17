<?php

namespace App\Services\Mobile;

use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Notifications\DatabaseNotification;

class NotificationsService
{
    /** @return array{data: array, meta: array} */
    public function listForUser(User $user, int $perPage = 20): array
    {
        $page = $user->notifications()->orderBy('created_at', 'desc')->paginate($perPage);

        $unreadCount = $user->unreadNotifications()->count();

        return [
            'data' => $page->getCollection()->map(fn ($n) => $this->project($n))->all(),
            'meta' => [
                'current_page' => $page->currentPage(),
                'last_page' => $page->lastPage(),
                'total' => $page->total(),
                'per_page' => $page->perPage(),
                'unread_count' => $unreadCount,
            ],
        ];
    }

    public function markAsRead(User $user, string $notificationId): void
    {
        $notification = DatabaseNotification::find($notificationId);

        if (! $notification
            || $notification->notifiable_type !== User::class
            || (int) $notification->notifiable_id !== $user->id) {
            throw new AuthorizationException('Notifikasi tidak ditemukan atau bukan milik Anda.');
        }

        if ($notification->read_at === null) {
            $notification->markAsRead();
        }
    }

    public function markAllAsRead(User $user): int
    {
        return $user->unreadNotifications()->update(['read_at' => now()]);
    }

    /**
     * Project a database notification into mobile-friendly shape.
     * Existing notifications carry: data.type, data.title, data.message, data.link.
     */
    private function project(DatabaseNotification $n): array
    {
        $data = $n->data ?? [];
        $type = $data['type'] ?? 'other';
        [$icon, $action] = $this->mapTypeToIconAndAction($type, $data);

        return [
            'id' => $n->id,
            'type' => $type,
            'title' => $data['title'] ?? 'Notifikasi',
            'body' => $data['message'] ?? '',
            'icon' => $icon,
            'action' => $action,
            'read_at' => $n->read_at?->toIso8601String(),
            'created_at' => $n->created_at->toIso8601String(),
        ];
    }

    /**
     * @return array{0: string, 1: array|null}  [icon_key, action_or_null]
     */
    private function mapTypeToIconAndAction(string $type, array $data): array
    {
        return match ($type) {
            'grade' => ['star', ['screen' => 'grades', 'args' => []]],
            'announcement' => ['campaign', ['screen' => 'announcement_detail', 'args' => array_filter([
                'id' => $data['announcement_id'] ?? null,
            ])]],
            'assignment' => ['assignment', ['screen' => 'assignments', 'args' => []]],
            'student_absent' => ['event_busy', null],
            default => ['bell', null],
        };
    }
}
