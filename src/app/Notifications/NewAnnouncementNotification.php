<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\BroadcastMessage;
use Illuminate\Notifications\Notification;

use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;

class NewAnnouncementNotification extends Notification implements ShouldBroadcastNow
{
    // use Queueable;

    public $announcement;

    /**
     * Create a new notification instance.
     */
    public function __construct($announcement)
    {
        $this->announcement = $announcement;
    }

    /**
     * Get the notification's delivery channels.
     *
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return ['database'];
    }

    /**
     * Get the array representation of the notification.
     *
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        return [
            'type'    => 'announcement',
            'title'   => 'Pengumuman Baru',
            'message' => $this->announcement->title,
            'link'    => route('tenant.announcements.show', $this->announcement->id), // Assuming show route exists
        ];
    }

    /**
     * Get the broadcastable representation of the notification.
     */
    public function toBroadcast(object $notifiable): BroadcastMessage
    {
        return new BroadcastMessage([
            'id'      => $this->id,
            'type'    => 'announcement',
            'title'   => 'Pengumuman Baru',
            'message' => $this->announcement->title,
            'link'    => route('tenant.announcements.show', $this->announcement->id),
            'created_at' => now()->toIso8601String(),
            'read_at' => null,
        ]);
    }
}
