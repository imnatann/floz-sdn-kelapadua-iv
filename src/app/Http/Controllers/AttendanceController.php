<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Semester;
use App\Models\StudentClassEnrollment;
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

        // Filter by academic year: explicit query param, else default to active AY
        $activeAy = AcademicYear::where('is_active', true)->first();
        $selectedAyId = $request->integer('academic_year_id') ?: $activeAy?->id;
        $student = ($user->isStudent() && $user->student) ? $user->student : null;

        $academicYears = AcademicYear::orderByDesc('start_date')->get(['id', 'name', 'is_active']);
        $query = SchoolClass::query()->with('academicYear:id,name,is_active');

        if ($student) {
            $academicYears = AcademicYear::query()
                ->whereHas('semesters.enrollments', fn ($q) => $q->where('student_id', $student->id))
                ->orderByDesc('start_date')
                ->get(['id', 'name', 'is_active']);

            if ($academicYears->isEmpty() && $activeAy) {
                $academicYears = AcademicYear::whereKey($activeAy->id)->get(['id', 'name', 'is_active']);
            }

            $selectedAyId = $request->integer('academic_year_id')
                ?: (($activeAy && $academicYears->contains('id', $activeAy->id))
                    ? $activeAy->id
                    : $academicYears->first()?->id);

            $enrollmentClassIds = StudentClassEnrollment::query()
                ->where('student_id', $student->id)
                ->whereHas('semester', fn ($q) => $q->when($selectedAyId, fn ($qq, $ay) => $qq->where('academic_year_id', $ay)))
                ->pluck('class_id');

            $student->loadMissing('class');
            $currentClassId = $student->class && (! $selectedAyId || (int) $student->class->academic_year_id === (int) $selectedAyId)
                ? [$student->class_id]
                : [];

            $classIds = $enrollmentClassIds
                ->merge($currentClassId)
                ->filter()
                ->unique()
                ->values();

            $query->whereIn('id', $classIds->all() ?: [0]);
        } elseif ($user->isTeacher() && $user->teacher) {
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
            $query->where('status', 'active')->whereIn('id', $allClassIds);
        } else {
            $query->where('status', 'active');
        }

        if ($selectedAyId) {
            $query->where('academic_year_id', $selectedAyId);
        }

        $query->withCount([
            'enrollments as students_count' => fn ($q) => $q
                ->whereHas(
                    'semester',
                    fn ($qq) => $qq->when($selectedAyId, fn ($qqq, $ay) => $qqq->where('academic_year_id', $ay))
                )
                ->select(DB::raw('count(distinct student_id)')),
        ]);

        $classes = $query->orderBy('grade_level')->orderBy('name')->get();

        return Inertia::render('Attendance/Index', [
            'classes'       => $classes,
            'academicYears' => $academicYears,
            'filters'       => ['academic_year_id' => $selectedAyId],
        ]);
    }

    public function show(SchoolClass $class)
    {
        $user = request()->user();
        $class->load('students');
        $activeSemester = Semester::where('is_active', true)->first();

        if (!$activeSemester) {
            return redirect()->back()->with('error', 'Tidak ada semester aktif. Harap atur semester aktif terlebih dahulu.');
        }

        // Siswa: must be in this class
        if ($user->isStudent() && $user->student && $user->student->class_id !== $class->id) {
            abort(403, 'Anda hanya dapat melihat absensi kelas Anda sendiri.');
        }

        // Get all unique meetings for this class and semester
        // Use groupBy meeting_number to ensure one row per meeting (avoids duplicate headers
        // if recorded_by differs across records in the same session).
        $meetings = Attendance::where('class_id', $class->id)
            ->where('semester_id', $activeSemester->id)
            ->select('meeting_number', \Illuminate\Support\Facades\DB::raw('MIN(date) as date'), \Illuminate\Support\Facades\DB::raw('MIN(recorded_by) as recorded_by'))
            ->groupBy('meeting_number')
            ->orderBy('meeting_number')
            ->get();

        // Scope attendance + student list: siswa only sees own row
        $attendancesQuery = Attendance::where('class_id', $class->id)
            ->where('semester_id', $activeSemester->id);
        $studentsQuery = Student::query()
            ->select('students.*')
            ->join('student_class_enrollments as sce', 'sce.student_id', '=', 'students.id')
            ->where('sce.class_id', $class->id)
            ->where('sce.semester_id', $activeSemester->id)
            ->orderBy('students.name');

        if ($user->isStudent() && $user->student) {
            $attendancesQuery->where('student_id', $user->student->id);
            $studentsQuery->where('students.id', $user->student->id);
        }

        $attendances = $attendancesQuery->get()->groupBy('student_id');

        return Inertia::render('Attendance/Show', [
            'schoolClass' => $class,
            'students' => $studentsQuery->get(),
            'meetings' => $meetings,
            'attendances' => $attendances,
            'activeSemester' => $activeSemester
        ]);
    }

    /**
     * Assert the authenticated user is the homeroom teacher (wali kelas) of $class.
     * Admin is always allowed.
     */
    private function authorizeHomeroomOrAdmin(Request $request, SchoolClass $class): void
    {
        $user = $request->user();

        if ($user->isSchoolAdmin()) {
            return;
        }

        if ($user->isTeacher() && $user->teacher) {
            abort_unless(
                (int) $class->homeroom_teacher_id === (int) $user->teacher->id,
                403,
                'Hanya wali kelas yang dapat mengelola absensi kelas ini.'
            );
            return;
        }

        abort(403, 'Unauthorized');
    }

    public function create(SchoolClass $class)
    {
        // A8 guard: only wali kelas (homeroom teacher) or admin may input attendance.
        $this->authorizeHomeroomOrAdmin(request(), $class);

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

        return Inertia::render('Attendance/Create', [
            'schoolClass' => $class,
            'students' => Student::query()
                ->select('students.*')
                ->join('student_class_enrollments as sce', 'sce.student_id', '=', 'students.id')
                ->where('sce.class_id', $class->id)
                ->where('sce.semester_id', $activeSemester->id)
                ->orderBy('students.name')
                ->get(),
            'nextMeetingNumber' => $nextMeetingNumber,
            'todayDate' => Carbon::today()->format('Y-m-d'),
            'existingMeetings' => $existingMeetings
        ]);
    }

    public function store(Request $request, SchoolClass $class)
    {
        // A8 guard: only wali kelas (homeroom teacher) or admin may store attendance.
        $this->authorizeHomeroomOrAdmin($request, $class);

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
        // A8 guard: only wali kelas (homeroom teacher) or admin may edit attendance.
        $this->authorizeHomeroomOrAdmin(request(), $class);

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

        return Inertia::render('Attendance/Edit', [
            'schoolClass' => $class,
            'students' => Student::query()
                ->select('students.*')
                ->join('student_class_enrollments as sce', 'sce.student_id', '=', 'students.id')
                ->where('sce.class_id', $class->id)
                ->where('sce.semester_id', $activeSemester->id)
                ->orderBy('students.name')
                ->get(),
            'meetingNumber' => $meeting,
            'meetingDate' => $meetingDate,
            'existingAttendances' => $attendances
        ]);
    }

    public function update(Request $request, SchoolClass $class, $meeting)
    {
        // A8 guard: only wali kelas (homeroom teacher) or admin may update attendance.
        $this->authorizeHomeroomOrAdmin($request, $class);

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
