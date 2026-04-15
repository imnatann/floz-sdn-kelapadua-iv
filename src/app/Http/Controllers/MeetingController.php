<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Meeting;
use App\Models\MeetingMaterial;
use App\Models\TeachingAssignment;
use App\Models\OfflineAssignment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Inertia\Inertia;

class MeetingController extends Controller
{
    /**
     * Course list page — shows all teaching assignments as courses.
     * Teacher: all their own teaching assignments.
     * Student: all subjects for their class.
     */
    public function index(Request $request)
    {
        $user = auth()->user();

        $query = TeachingAssignment::with(['teacher', 'subject', 'schoolClass', 'academicYear']);

        if ($user->isTeacher() && $user->teacher) {
            $query->where('teacher_id', $user->teacher->id);
        } elseif ($user->isStudent() && $user->student) {
            $query->where('class_id', $user->student->class_id);
        } else {
            $query->whereRaw('1 = 0');
        }

        $courses = $query->latest()->get();

        // For each course, generate meetings if they don't exist yet (for existing teaching assignments)
        foreach ($courses as $course) {
            if ($course->meetings()->count() === 0) {
                Meeting::generateForTeachingAssignment($course->id);
            }
        }

        return Inertia::render('Tenant/Courses/Index', [
            'courses' => $courses,
            'is_teacher' => $user->isTeacher(),
        ]);
    }

    /**
     * Course detail page — shows all meetings with their contents.
     */
    public function show(TeachingAssignment $teachingAssignment)
    {
        $user = auth()->user();
        $this->authorize('viewCourse', [Meeting::class, $teachingAssignment]);

        // Generate meetings if they don't exist (for pre-existing teaching assignments)
        if ($teachingAssignment->meetings()->count() === 0) {
            Meeting::generateForTeachingAssignment($teachingAssignment->id);
        }

        $teachingAssignment->load(['teacher', 'subject', 'schoolClass', 'academicYear']);

        $meetings = $teachingAssignment->meetings()
            ->with([
                'materials',
                'assignments' => function ($q) {
                    $q->with('questions');
                },
            ])
            ->get();

        // For students: filter to only unlocked meetings & load their submissions
        $isStudent = $user->isStudent();
        if ($isStudent && $user->student) {
            // Load submission status for each assignment
            $meetings->each(function ($meeting) use ($user) {
                $meeting->assignments->each(function ($assignment) use ($user) {
                    $submission = $assignment->submissions()
                        ->where('student_id', $user->student->id)
                        ->first();
                    $assignment->student_submission = $submission;
                });
            });
        }

        return Inertia::render('Tenant/Courses/Show', [
            'course' => $teachingAssignment,
            'meetings' => $meetings,
            'is_teacher' => $user->isTeacher(),
            'is_student' => $isStudent,
        ]);
    }

    /**
     * Dedicated Meeting Details page (Phase 1)
     */
    public function showMeeting(TeachingAssignment $teachingAssignment, Meeting $meeting)
    {
        $user = auth()->user();
        $this->authorize('viewCourse', [Meeting::class, $teachingAssignment]);

        // Ensure this meeting belongs to the teaching assignment
        if ($meeting->teaching_assignment_id !== $teachingAssignment->id) {
            abort(404);
        }

        $teachingAssignment->load(['subject', 'schoolClass']);
        
        $meeting->load([
            'materials' => function ($q) {
                $q->orderBy('sort_order')->orderBy('id');
            },
            'assignments' => function ($q) {
                // If it's a student, load their submission status
                $isStudent = auth()->user()->isStudent();
                if ($isStudent) {
                    $q->with(['submissions' => function ($sq) {
                        $sq->where('student_id', auth()->user()->student->id ?? 0);
                    }]);
                }
            }
        ]);

        return Inertia::render('Tenant/Meetings/Show', [
            'course' => $teachingAssignment,
            'meeting' => $meeting,
            'is_teacher' => $user->isTeacher(),
            'is_student' => $user->isStudent(),
        ]);
    }

    /**
     * Toggle meeting lock status or update meeting details.
     */
    public function updateMeeting(Request $request, Meeting $meeting)
    {
        $this->authorize('update', $meeting);

        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'is_locked' => 'sometimes|boolean',
        ]);

        $meeting->update($validated);

        return back()->with('success', 'Pertemuan berhasil diperbarui.');
    }

    /**
     * Add material (file/link/text) to a meeting.
     */
    public function storeMaterial(Request $request, Meeting $meeting)
    {
        $this->authorize('manageMaterial', $meeting);

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'type' => 'required|in:file,link,text',
            'content' => 'nullable|string',
            'url' => 'nullable|url|max:500',
            'file' => 'nullable|file|max:20480', // 20MB max
        ]);

        $data = [
            'title' => $validated['title'],
            'type' => $validated['type'],
            'sort_order' => $meeting->materials()->count(),
        ];

        if ($validated['type'] === 'text') {
            $data['content'] = $validated['content'] ?? '';
        } elseif ($validated['type'] === 'link') {
            $data['url'] = $validated['url'] ?? '';
        } elseif ($validated['type'] === 'file' && $request->hasFile('file')) {
            $file = $request->file('file');
            $path = $file->store("meetings/{$meeting->id}/materials", 'public');
            $data['file_path'] = $path;
            $data['file_name'] = $file->getClientOriginalName();
            $data['file_size'] = $file->getSize();
        }

        $meeting->materials()->create($data);

        return back()->with('success', 'Materi berhasil ditambahkan.');
    }

    /**
     * Delete a material from a meeting.
     */
    public function destroyMaterial(MeetingMaterial $meetingMaterial)
    {
        $meeting = $meetingMaterial->meeting;
        $this->authorize('manageMaterial', $meeting);

        // Delete file from storage if exists
        if ($meetingMaterial->file_path) {
            Storage::disk('public')->delete($meetingMaterial->file_path);
        }

        $meetingMaterial->delete();

        return back()->with('success', 'Materi berhasil dihapus.');
    }

    /**
     * Show a dedicated page for a specific material (Activity Viewer)
     */
    public function showMaterial(MeetingMaterial $meetingMaterial)
    {
        $meeting = $meetingMaterial->meeting;
        $course = $meeting->teachingAssignment;
        
        $this->authorize('viewCourse', [Meeting::class, $course]);

        $course->load(['subject', 'schoolClass']);
        
        // Find previous and next activities for navigation footer
        // We'll pass all materials and assignments for this meeting to front-end to build the navigation
        $meeting->load([
            'materials' => function($q) { $q->orderBy('sort_order')->orderBy('id'); },
            'assignments' => function($q) { $q->orderBy('id'); }
        ]);

        return Inertia::render('Tenant/Materials/Show', [
            'course' => $course,
            'meeting' => $meeting,
            'material' => $meetingMaterial,
            'is_teacher' => auth()->user()->isTeacher(),
            'is_student' => auth()->user()->isStudent(),
        ]);
    }
}
