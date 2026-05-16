<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\DB;
use App\Models\User;
use App\Notifications\NewAnnouncementNotification;

class AnnouncementController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $announcements = Announcement::with('author')
            ->where('is_published', true)
            ->where(function ($query) use ($user) {
                // Show 'all'
                $query->where('target_audience', 'all');
                
                // Show role-specific
                if ($user->isTeacher()) {
                    $query->orWhere('target_audience', 'teachers');
                } elseif ($user->isStudent()) {
                    $query->orWhere('target_audience', 'students');
                }
            })
            ->when($request->search, function ($query, $search) {
                $query->where('title', 'like', "%{$search}%");
            })
            ->orderBy('is_pinned', 'desc') // Pinned first
            ->orderBy('created_at', 'desc')
            ->paginate(12) // Grid layout usually takes more space
            ->withQueryString();

        return inertia('Announcements/Index', [
            'announcements' => $announcements,
            'filters' => $request->only(['search']),
        ]);
    }

    public function show(Announcement $announcement)
    {
        // Add authorization check if needed (e.g. student shouldn't see teacher announcements)
        
        return inertia('Announcements/Show', [
            'announcement' => $announcement->load('author'),
        ]);
    }

    public function create()
    {
        return inertia('Announcements/Form');
    }

    public function edit(Announcement $announcement)
    {
        return inertia('Announcements/Form', [
            'announcement' => $announcement,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string', // Rich text HTML
            'excerpt' => 'nullable|string|max:500',
            'target_audience' => 'required|in:all,teachers,students',
            'type' => 'required|in:info,event,alert',
            'is_pinned' => 'boolean',
            'is_published' => 'boolean',
        ]);

        // Auto-generate Excerpt if empty
        if (empty($validated['excerpt'])) {
            $validated['excerpt'] = Str::limit(strip_tags($validated['content']), 150);
        }

        $announcement = $request->user()->announcements()->create($validated);

        if ($validated['is_published']) {
            $query = User::where('is_active', true);

            if ($validated['target_audience'] === 'teachers') {
                $query->whereHas('teacher'); // Assuming relation exists or filter by role
                // Better: filter by role using the scope or attribute if available, or just check role column
                 $query->where('role', \App\Enums\UserRole::Teacher);
            } elseif ($validated['target_audience'] === 'students') {
                 $query->where('role', \App\Enums\UserRole::Student);
            }
            // If 'all', no extra filter needed (sends to everyone)

            // Exclude the creator? Maybe not needed if admin creates it.
            // But if a teacher creates it, they might not need a notif.
            $query->where('id', '!=', $request->user()->id);

            $recipients = $query->get();
            
            if ($recipients->count() > 0) {
                // Notification::send($recipients, new NewAnnouncementNotification($announcement));
                
                $notifications = [];
                $events = [];
                $now = now();
                
                foreach ($recipients as $recipient) {
                    $uuid = (string) Str::uuid();
                    
                    $notifications[] = [
                        'id' => $uuid,
                        'type' => NewAnnouncementNotification::class,
                        'notifiable_type' => get_class($recipient),
                        'notifiable_id' => $recipient->id,
                        'data' => json_encode([
                            'type' => 'announcement',
                            'title' => 'Pengumuman Baru',
                            'message' => $announcement->title,
                            'link' => route('announcements.show', $announcement->id),
                        ]),
                        'read_at' => null,
                        'created_at' => $now,
                        'updated_at' => $now,
                    ];
                    
                    $events[] = new \App\Events\AnnouncementPosted($announcement, $recipient->id, $uuid);
                }
                
                // Batch insert to DB
                DB::table('notifications')->insert($notifications);
                
                // Dispatch events synchronously
                foreach ($events as $event) {
                    event($event);
                }
            }
        }

        return redirect()->route('announcements.index')
            ->with('success', 'Pengumuman berhasil dibuat.');
    }

    public function update(Request $request, Announcement $announcement)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'excerpt' => 'nullable|string|max:500',
            'target_audience' => 'required|in:all,teachers,students',
            'type' => 'required|in:info,event,alert',
            'is_pinned' => 'boolean',
            'is_published' => 'boolean',
        ]);

        // Auto-generate Excerpt if empty
        if (empty($validated['excerpt'])) {
            $validated['excerpt'] = Str::limit(strip_tags($validated['content']), 150);
        }

        $announcement->update($validated);

        return redirect()->route('announcements.index')
            ->with('success', 'Pengumuman berhasil diperbarui.');
    }

    public function destroy(Announcement $announcement)
    {
        $announcement->delete();

        return redirect()->route('announcements.index')
            ->with('success', 'Pengumuman berhasil dihapus.');
    }
}
