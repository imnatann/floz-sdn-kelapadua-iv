<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\BroadcastMessage;
use Illuminate\Notifications\Notification;

class StudentAbsentNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public $attendance;

    /**
     * Create a new notification instance.
     */
    public function __construct($attendance)
    {
        $this->attendance = $attendance;
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
        $status = ucfirst($this->attendance->status ?? 'Alpha');
        $date = \Carbon\Carbon::parse($this->attendance->date)->translatedFormat('d F Y');
        $studentName = $this->attendance->student->name ?? 'Siswa';

        return [
            'type'    => 'attendance',
            'title'   => 'Pemberitahuan Ketidakhadiran',
            'message' => "{$studentName} tercatat {$status} pada {$date}.",
            'link'    => route('tenant.attendance.index'), // Or link to specific detail if available
        ];
    }

    /**
     * Get the broadcastable representation of the notification.
     */
    public function toBroadcast(object $notifiable): BroadcastMessage
    {
        $status = ucfirst($this->attendance->status ?? 'Alpha');
        $date = \Carbon\Carbon::parse($this->attendance->date)->translatedFormat('d F Y');
        $studentName = $this->attendance->student->name ?? 'Siswa';

        return new BroadcastMessage([
            'id'      => $this->id,
            'type'    => 'attendance',
            'title'   => 'Pemberitahuan Ketidakhadiran',
            'message' => "{$studentName} tercatat {$status} pada {$date}.",
            'link'    => route('tenant.attendance.index'),
            'created_at' => now()->toIso8601String(),
            'read_at' => null,
        ]);
    }
}
