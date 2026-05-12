<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Schedule;
use App\Models\TeachingAssignment;
use App\Models\SchoolClass;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Validation\Rule;

class ScheduleController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        // Students are always scoped to their own class
        if ($user->isStudent() && $user->student) {
            $classId = $user->student->class_id;
            $classes = SchoolClass::with('homeroomTeacher')
                ->withCount(['students', 'teachingAssignments'])
                ->where('id', $classId)
                ->orderBy('name')
                ->get();
        } else {
            // For filtering by class in the admin/teacher view
            $classId = $request->input('class_id');
            $classesQuery = SchoolClass::with('homeroomTeacher')
                ->withCount(['students', 'teachingAssignments'])
                ->orderBy('name');

            // Scope teacher: only classes they are homeroom of OR have a TA in
            if ($user->isTeacher() && $user->teacher) {
                $teacherId = $user->teacher->id;
                $taClassIds = TeachingAssignment::where('teacher_id', $teacherId)->pluck('class_id')->all();
                $homeroomClassIds = SchoolClass::where('homeroom_teacher_id', $teacherId)->pluck('id')->all();
                $visibleIds = array_values(array_unique(array_merge($taClassIds, $homeroomClassIds)));
                $classesQuery->whereIn('id', $visibleIds ?: [0]);
            }

            $classes = $classesQuery->get();
        }
        
        $schedules = [];
        $selectedClass = null;

        if ($classId) {
            $selectedClass = SchoolClass::find($classId);
            $schedules = Schedule::whereHas('teachingAssignment', function ($query) use ($classId) {
                    $query->where('class_id', $classId);
                })
                ->with(['teachingAssignment.subject', 'teachingAssignment.teacher'])
                ->orderBy('day_of_week')
                ->orderBy('start_time')
                ->get()
                ->groupBy('day_of_week');
        }

        // Get all teaching assignments for the current class (if selected) to populate the "Add Schedule" dropdown
        $teachingAssignments = $classId 
            ? TeachingAssignment::where('class_id', $classId)
                ->with(['subject', 'teacher'])
                ->get()
            : [];

        return Inertia::render('Schedules/Index', [
            'classes' => $classes,
            'schedules' => $schedules,
            'teachingAssignments' => $teachingAssignments,
            'filters' => ['class_id' => $classId],
            'selectedClass' => $selectedClass,
        ]);
    }

    public function store(Request $request)
    {
        if (! $request->user()->isSchoolAdmin()) {
            abort(403, 'Unauthorized');
        }

        $validated = $request->validate([
            'day_of_week' => 'required|integer|min:1|max:7',
            'items' => 'required|array|min:1',
            'items.*.teaching_assignment_id' => 'required|exists:teaching_assignments,id',
            'items.*.start_time' => 'required|date_format:H:i',
            'items.*.end_time' => 'required|date_format:H:i|after:items.*.start_time',
        ], [
            'items.*.teaching_assignment_id.required' => 'Mapel harus dipilih.',
            'items.*.start_time.required' => 'Jam mulai wajib diisi.',
            'items.*.end_time.after' => 'Jam selesai harus setelah jam mulai.',
        ]);

        \Illuminate\Support\Facades\DB::transaction(function () use ($validated) {
            foreach ($validated['items'] as $item) {
                // Here we could add overlap checking logic if needed
                Schedule::create([
                    'teaching_assignment_id' => $item['teaching_assignment_id'],
                    'day_of_week' => $validated['day_of_week'],
                    'start_time' => $item['start_time'],
                    'end_time' => $item['end_time'],
                ]);
            }
        });

        return redirect()->back()->with('success', 'Jadwal berhasil ditambahkan.');
    }

    public function update(Request $request, Schedule $schedule)
    {
        if (! $request->user()->isSchoolAdmin()) {
            abort(403, 'Unauthorized');
        }

        $validated = $request->validate([
            'teaching_assignment_id' => 'required|exists:teaching_assignments,id',
            'day_of_week' => 'required|integer|min:1|max:7',
            'start_time' => 'required|date_format:H:i',
            'end_time' => 'required|date_format:H:i|after:start_time',
        ], [
            'end_time.after' => 'Jam selesai harus setelah jam mulai.',
        ]);

        $schedule->update($validated);

        return redirect()->back()->with('success', 'Jadwal berhasil diperbarui.');
    }

    public function destroy(Schedule $schedule)
    {
        if (! request()->user()->isSchoolAdmin()) {
            abort(403, 'Unauthorized');
        }

        $schedule->delete();
        return redirect()->back()->with('success', 'Jadwal berhasil dihapus.');
    }
}
