<?php

namespace App\Events;

use App\Models\Announcement;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class AnnouncementPosted implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $announcement;
    public $userId;
    public $notificationId;

    /**
     * Create a new event instance.
     */
    public function __construct(Announcement $announcement, int $userId, string $notificationId)
    {
        $this->announcement = $announcement;
        $this->userId = $userId;
        $this->notificationId = $notificationId;
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('App.Models.Tenant.User.' . $this->userId),
        ];
    }
    
    public function broadcastAs()
    {
        return 'AnnouncementPosted';
    }

    public function broadcastWith()
    {
        return [
            'id' => $this->notificationId,
            'type' => 'App\\Notifications\\Tenant\\NewAnnouncementNotification', // Match DB type
            'title' => 'Pengumuman Baru',
            'message' => $this->announcement->title,
            'link' => route('tenant.announcements.show', $this->announcement->id),
            'created_at' => now()->toIso8601String(),
            'read_at' => null,
            'data' => [ // Redundant but helpful if frontend expects 'data' wrapper
                'title' => 'Pengumuman Baru',
                'message' => $this->announcement->title,
                'link' => route('tenant.announcements.show', $this->announcement->id),
                'type' => 'announcement',
            ]
        ];
    }
}
