<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\OfflineAssignment;
use App\Models\OfflineAssignmentSubmission;
use Illuminate\Http\Request;

class MobileAssignmentController extends Controller
{
    /**
     * GET /api/v1/assignments
     * List assignments for the student's class, optionally filtered by status.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        if (!$user->isStudent()) {
            return response()->json(['message' => 'Hanya siswa yang dapat melihat tugas'], 403);
        }

        $student = $user->student;
        if (!$student || !$student->class_id) {
            return response()->json([
                'data' => []
            ]);
        }

        $classId = $student->class_id;
        $statusFilter = $request->get('status', 'upcoming'); // 'upcoming' or 'completed'
        $perPage = $request->get('per_page', 15);

        $query = OfflineAssignment::whereHas('classes', function ($q) use ($classId) {
                $q->where('class_id', $classId);
            })
            ->where('status', 'active')
            ->with(['subject', 'teacher']);

        if ($statusFilter === 'completed') {
            // Assignments where the student has submitted SOME submission record
            $query->whereHas('submissions', function ($q) use ($student) {
                $q->where('student_id', $student->id);
            })->orderByDesc('due_date');
        } else {
            // Upcoming or overdue, but not submitted yet
            $query->whereDoesntHave('submissions', function ($q) use ($student) {
                $q->where('student_id', $student->id);
            })->orderBy('due_date');
        }

        $assignments = $query->paginate($perPage)->through(function ($a) {
            return [
                'id' => $a->id,
                'title' => $a->title,
                'description' => \Illuminate\Support\Str::limit(strip_tags($a->description), 100),
                'due_date' => $a->due_date ? $a->due_date->toISOString() : null,
                'subject' => $a->subject->name ?? '-',
                'teacher' => $a->teacher->name ?? '-',
                'type' => $a->type,
            ];
        });

        return response()->json($assignments);
    }

    /**
     * GET /api/v1/assignments/{id}
     * Detail of a single assignment
     */
    public function show(Request $request, $id)
    {
        $user = $request->user();
        if (!$user->isStudent()) {
            return response()->json(['message' => 'Hanya siswa yang dapat melihat tugas'], 403);
        }

        $student = $user->student;
        if (!$student || !$student->class_id) {
            return response()->json(['message' => 'Kelas siswa tidak ditemukan'], 404);
        }

        $assignment = OfflineAssignment::whereHas('classes', function ($q) use ($student) {
                $q->where('class_id', $student->class_id);
            })
            ->where('status', 'active')
            ->with(['subject', 'teacher', 'files'])
            ->findOrFail($id);

        $submission = OfflineAssignmentSubmission::where('offline_assignment_id', $assignment->id)
            ->where('student_id', $student->id)
            ->first();

        return response()->json([
            'assignment' => [
                'id' => $assignment->id,
                'title' => $assignment->title,
                'description' => $assignment->description,
                'due_date' => $assignment->due_date ? $assignment->due_date->toISOString() : null,
                'subject' => $assignment->subject->name ?? '-',
                'teacher' => $assignment->teacher->name ?? '-',
                'type' => $assignment->type,
                'files' => $assignment->files->map(fn($f) => [
                    'id' => $f->id,
                    'file_name' => $f->file_name,
                    'file_path' => $f->file_path,
                    'file_url' => asset('storage/' . $f->file_path)
                ]),
                'submission' => $submission ? [
                    'id' => $submission->id,
                    'status' => $submission->grade !== null ? 'graded' : 'submitted',
                    'submitted_at' => $submission->submitted_at ? $submission->submitted_at->toISOString() : null,
                    'score' => $submission->grade !== null ? (int) $submission->grade : null,
                    'teacher_notes' => $submission->correction_note,
                ] : null
            ]
        ]);
    }
}
