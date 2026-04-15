<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Semester;
use App\Models\Teacher;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Inertia\Inertia;
use Illuminate\Support\Facades\DB;

class AttendanceController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        
        $query = SchoolClass::where('status', 'active');
        
        if ($user->role === 'teacher' && $user->teacher) {
            // Get classes where the teacher is either homeroom or teaches a subject
            $teacherId = $user->teacher->id;
            $classIds = DB::table('teaching_assignments')
                ->where('teacher_id', $teacherId)
                ->pluck('class_id')
                ->toArray();
                
            $homeroomClassIds = SchoolClass::where('homeroom_teacher_id', $teacherId)
                ->pluck('id')
                ->toArray();
                
            $allClassIds = array_unique(array_merge($classIds, $homeroomClassIds));
            $query->whereIn('id', $allClassIds);
        }
        
        $classes = $query->withCount('students')
                         ->orderBy('name')
                         ->get();

        return Inertia::render('Tenant/Attendance/Index', [
            'classes' => $classes,
        ]);
    }

    public function show(SchoolClass $class)
    {
        $class->load('students');
        $activeSemester = Semester::where('is_active', true)->first();
        
        if (!$activeSemester) {
            return redirect()->back()->with('error', 'Tidak ada semester aktif. Harap atur semester aktif terlebih dahulu.');
        }

        // Get all unique meetings for this class and semester
        $meetings = Attendance::where('class_id', $class->id)
            ->where('semester_id', $activeSemester->id)
            ->select('meeting_number', 'date', 'recorded_by')
            ->distinct()
            ->orderBy('meeting_number')
            ->get();

        // Get all attendance records
        $attendances = Attendance::where('class_id', $class->id)
            ->where('semester_id', $activeSemester->id)
            ->get()
            ->groupBy('student_id');

        return Inertia::render('Tenant/Attendance/Show', [
            'schoolClass' => $class,
            'students' => $class->students()->orderBy('name')->get(),
            'meetings' => $meetings,
            'attendances' => $attendances,
            'activeSemester' => $activeSemester
        ]);
    }

    public function create(SchoolClass $class)
    {
        $activeSemester = Semester::where('is_active', true)->first();
        
        if (!$activeSemester) {
            return redirect()->back()->with('error', 'Tidak ada semester aktif.');
        }

        $existingMeetings = Attendance::where('class_id', $class->id)
            ->where('semester_id', $activeSemester->id)
            ->select('meeting_number')
            ->distinct()
            ->orderBy('meeting_number')
            ->get();
            
        $latestMeeting = $existingMeetings->max('meeting_number') ?? 0;
            
        $nextMeetingNumber = $latestMeeting + 1;

        return Inertia::render('Tenant/Attendance/Create', [
            'schoolClass' => $class,
            'students' => $class->students()->orderBy('name')->get(),
            'nextMeetingNumber' => $nextMeetingNumber,
            'todayDate' => Carbon::today()->format('Y-m-d'),
            'existingMeetings' => $existingMeetings
        ]);
    }

    public function store(Request $request, SchoolClass $class)
    {
        $activeSemester = Semester::where('is_active', true)->first();
        
        // Add custom validation for unique meeting_number per class and semester
        $validated = $request->validate([
            'date' => 'required|date',
            'meeting_number' => [
                'required',
                'integer',
                'min:1',
                function ($attribute, $value, $fail) use ($class, $activeSemester) {
                    $exists = Attendance::where('class_id', $class->id)
                        ->where('semester_id', $activeSemester->id)
                        ->where('meeting_number', $value)
                        ->exists();
                    if ($exists) {
                        $fail('Pertemuan ke-' . $value . ' sudah ditambahkan sebelumnya.');
                    }
                },
            ],
            'attendances' => 'required|array',
            'attendances.*.student_id' => 'required|exists:students,id',
            'attendances.*.status' => 'required|in:present,sick,permit,absent',
            'attendances.*.notes' => 'nullable|string|max:255',
        ]);

        $teacher = $request->user()->teacher;

        DB::transaction(function () use ($validated, $class, $activeSemester, $teacher) {
            foreach ($validated['attendances'] as $data) {
                Attendance::updateOrCreate(
                    [
                        'class_id' => $class->id,
                        'student_id' => $data['student_id'],
                        'semester_id' => $activeSemester->id,
                        'meeting_number' => $validated['meeting_number'],
                    ],
                    [
                        'date' => $validated['date'],
                        'status' => $data['status'],
                        'notes' => $data['notes'],
                        'recorded_by' => $teacher ? $teacher->id : null,
                    ]
                );
            }
        });

        return redirect()->route('attendance.show', $class->id)->with('success', 'Absensi pertemuan berhasil disimpan.');
    }

    public function edit(SchoolClass $class, $meeting)
    {
        $activeSemester = Semester::where('is_active', true)->first();
        
        $attendances = Attendance::where('class_id', $class->id)
            ->where('semester_id', $activeSemester->id)
            ->where('meeting_number', $meeting)
            ->get()
            ->keyBy('student_id');
            
        if ($attendances->isEmpty()) {
            return redirect()->route('attendance.show', $class->id)->with('error', 'Pertemuan tidak ditemukan.');
        }

        $meetingDate = $attendances->first()->date->format('Y-m-d');

        return Inertia::render('Tenant/Attendance/Edit', [
            'schoolClass' => $class,
            'students' => $class->students()->orderBy('name')->get(),
            'meetingNumber' => $meeting,
            'meetingDate' => $meetingDate,
            'existingAttendances' => $attendances
        ]);
    }

    public function update(Request $request, SchoolClass $class, $meeting)
    {
        $validated = $request->validate([
            'date' => 'required|date',
            'attendances' => 'required|array',
            'attendances.*.student_id' => 'required|exists:students,id',
            'attendances.*.status' => 'required|in:present,sick,permit,absent',
            'attendances.*.notes' => 'nullable|string|max:255',
        ]);

        $activeSemester = Semester::where('is_active', true)->first();
        $teacher = $request->user()->teacher;

        DB::transaction(function () use ($validated, $class, $activeSemester, $teacher, $meeting) {
            foreach ($validated['attendances'] as $data) {
                Attendance::updateOrCreate(
                    [
                        'class_id' => $class->id,
                        'student_id' => $data['student_id'],
                        'semester_id' => $activeSemester->id,
                        'meeting_number' => $meeting,
                    ],
                    [
                        'date' => $validated['date'],
                        'status' => $data['status'],
                        'notes' => $data['notes'],
                        'recorded_by' => $teacher ? $teacher->id : null,
                    ]
                );
            }
        });

        return redirect()->route('attendance.show', $class->id)->with('success', 'Absensi pertemuan berhasil diupdate.');
    }
}
