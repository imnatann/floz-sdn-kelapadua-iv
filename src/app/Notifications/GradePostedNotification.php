<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\BroadcastMessage;
use Illuminate\Notifications\Notification;

class GradePostedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public $grade;

    /**
     * Create a new notification instance.
     */
    public function __construct($grade)
    {
        $this->grade = $grade;
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
        // Assuming Grade model has subject relationship
        $subject = $this->grade->subject ? $this->grade->subject->name : 'Mata Pelajaran';
        $type = ucfirst($this->grade->type ?? 'Nilai');

        return [
            'type'    => 'grade',
            'title'   => 'Nilai Baru',
            'message' => "Nilai {$type} {$subject}: {$this->grade->score}",
            'link'    => route('tenant.report-cards.index'), // Linking to report card as grades might extend to detailed view later
        ];
    }

    /**
     * Get the broadcastable representation of the notification.
     */
    public function toBroadcast(object $notifiable): BroadcastMessage
    {
        $subject = $this->grade->subject ? $this->grade->subject->name : 'Mata Pelajaran';
        $type = ucfirst($this->grade->type ?? 'Nilai');

        return new BroadcastMessage([
            'id'      => $this->id,
            'type'    => 'grade',
            'title'   => 'Nilai Baru',
            'message' => "Nilai {$type} {$subject}: {$this->grade->score}",
            'link'    => route('tenant.report-cards.index'),
            'created_at' => now()->toIso8601String(),
            'read_at' => null,
        ]);
    }
}
