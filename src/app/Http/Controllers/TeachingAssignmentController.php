<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Notifications\NewAssignmentNotification;
use Illuminate\Http\Request;
use Inertia\Inertia;

class TeachingAssignmentController extends Controller
{
    public function __construct()
    {
        $this->authorizeResource(TeachingAssignment::class, 'teaching_assignment');
    }

    public function index(Request $request)
    {
        $assignments = TeachingAssignment::query()
            ->with(['teacher', 'subject', 'schoolClass', 'academicYear'])
            ->when($request->teacher_id, fn($q, $id) => $q->where('teacher_id', $id))
            ->when($request->subject_id, fn($q, $id) => $q->where('subject_id', $id))
            ->when($request->class_id, fn($q, $id) => $q->where('class_id', $id))
            ->when($request->academic_year_id, fn($q, $id) => $q->where('academic_year_id', $id))
            ->orderByDesc('created_at')
            ->paginate(20)
            ->withQueryString();

        return Inertia::render('Tenant/TeachingAssignments/Index', [
            'assignments'   => $assignments,
            'teachers'      => Teacher::where('status', 'active')->orderBy('name')->get(['id', 'name', 'nip']),
            'subjects'      => Subject::where('status', 'active')->orderBy('name')->get(['id', 'name', 'code']),
            'classes'       => SchoolClass::where('status', 'active')->orderBy('name')->get(['id', 'name']),
            'academicYears' => AcademicYear::orderByDesc('start_date')->get(['id', 'name', 'is_active']),
            'filters'       => $request->only(['teacher_id', 'subject_id', 'class_id', 'academic_year_id']),
        ]);
    }

    public function create()
    {
        return Inertia::render('Tenant/TeachingAssignments/Create', [
            'teachers'      => Teacher::where('status', 'active')->orderBy('name')->get(['id', 'name', 'nip']),
            'subjects'      => Subject::where('status', 'active')->orderBy('name')->get(['id', 'name', 'code']),
            'classes'       => SchoolClass::where('status', 'active')->orderBy('name')->get(['id', 'name']),
            'academicYears' => AcademicYear::orderByDesc('start_date')->get(['id', 'name', 'is_active']),
        ]);
    }

    public function edit(TeachingAssignment $teachingAssignment)
    {
        return Inertia::render('Tenant/TeachingAssignments/Edit', [
            'assignment'    => $teachingAssignment->load(['teacher', 'subject', 'schoolClass', 'academicYear']),
            'teachers'      => Teacher::where('status', 'active')->orderBy('name')->get(['id', 'name', 'nip']),
            'subjects'      => Subject::where('status', 'active')->orderBy('name')->get(['id', 'name', 'code']),
            'classes'       => SchoolClass::where('status', 'active')->orderBy('name')->get(['id', 'name']),
            'academicYears' => AcademicYear::orderByDesc('start_date')->get(['id', 'name', 'is_active']),
        ]);
    }

    public function update(Request $request, TeachingAssignment $teachingAssignment)
    {
        $validated = $request->validate([
            'teacher_id'       => 'required|exists:teachers,id',
            'subject_id'       => 'required|exists:subjects,id',
            'class_id'         => 'required|exists:classes,id',
            'academic_year_id' => 'required|exists:academic_years,id',
        ]);

        // Check for duplicate assignment (excluding current one)
        $exists = TeachingAssignment::where([
            'teacher_id'       => $request->teacher_id,
            'subject_id'       => $request->subject_id,
            'class_id'         => $request->class_id,
            'academic_year_id' => $request->academic_year_id,
        ])->where('id', '!=', $teachingAssignment->id)->exists();

        if ($exists) {
            return redirect()->back()->with('error', 'Penugasan ini sudah ada.');
        }

        $teachingAssignment->update($validated);

        return redirect()->route('teaching-assignments.index')
            ->with('success', 'Penugasan guru berhasil diperbarui.');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'teacher_id'       => 'required|exists:teachers,id',
            'subject_id'       => 'required|exists:subjects,id',
            'class_id'         => 'required|exists:classes,id',
            'academic_year_id' => 'required|exists:academic_years,id',
        ]);

        // Check for duplicate assignment
        $exists = TeachingAssignment::where([
            'teacher_id'       => $request->teacher_id,
            'subject_id'       => $request->subject_id,
            'class_id'         => $request->class_id,
            'academic_year_id' => $request->academic_year_id,
        ])->exists();

        if ($exists) {
            return redirect()->back()->with('error', 'Penugasan ini sudah ada.');
        }

        // Optional: Check if subject is already assigned to another teacher in the same class (uncomment if one subject per class rule applies)
        /*
        $conflict = TeachingAssignment::where([
            'subject_id'       => $request->subject_id,
            'class_id'         => $request->class_id,
            'academic_year_id' => $request->academic_year_id,
        ])->exists();

        if ($conflict) {
            return redirect()->back()->with('error', 'Mata pelajaran ini sudah diajarkan guru lain di kelas tersebut.');
        }
        */

        $assignment = TeachingAssignment::create($validated);

        // Notify Teacher
        if ($assignment->teacher && $assignment->teacher->user) {
            $assignment->teacher->user->notify(new NewAssignmentNotification($assignment));
        }

        return redirect()->route('teaching-assignments.index')
            ->with('success', 'Penugasan guru berhasil ditambahkan.');
    }

    public function destroy(TeachingAssignment $teachingAssignment)
    {
        $teachingAssignment->delete();

        return redirect()->route('teaching-assignments.index')
            ->with('success', 'Penugasan berhasil dihapus.');
    }
}
