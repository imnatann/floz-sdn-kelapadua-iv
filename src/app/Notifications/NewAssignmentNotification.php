<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue; // Optional: Use if you want to queue
use Illuminate\Notifications\Messages\BroadcastMessage;
use Illuminate\Notifications\Notification;

class NewAssignmentNotification extends Notification
{
    use Queueable;

    public $assignment;

    /**
     * Create a new notification instance.
     */
    public function __construct($assignment)
    {
        $this->assignment = $assignment;
    }

    /**
     * Get the notification's delivery channels.
     *
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return ['database', 'broadcast'];
    }

    /**
     * Get the array representation of the notification.
     *
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        return [
            'type'    => 'assignment',
            'title'   => 'Penugasan Baru',
            'message' => "Anda ditugaskan mengajar {$this->assignment->subject->name} di kelas {$this->assignment->schoolClass->name}.",
            'link'    => route('tenant.teaching-assignments.index'),
        ];
    }

    /**
     * Get the broadcastable representation of the notification.
     */
    public function toBroadcast(object $notifiable): BroadcastMessage
    {
        return new BroadcastMessage([
            'id'      => $this->id,
            'type'    => 'assignment',
            'title'   => 'Penugasan Baru',
            'message' => "Anda ditugaskan mengajar {$this->assignment->subject->name} di kelas {$this->assignment->schoolClass->name}.",
            'link'    => route('tenant.teaching-assignments.index'),
            'created_at' => now()->toIso8601String(),
            'read_at' => null,
        ]);
    }
}
