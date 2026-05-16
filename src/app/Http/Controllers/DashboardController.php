<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\AcademicYear;
use App\Models\Student;
use App\Models\SchoolClass;
use App\Models\Grade;
use App\Models\ReportCard;
use App\Models\Semester;
use App\Models\Teacher;
use App\Models\Announcement;
use App\Models\Attendance;
use App\Models\StudentClassEnrollment;
use App\Models\TeachingAssignment;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Inertia\Inertia;

use OpenApi\Attributes as OA;

class DashboardController extends Controller
{
    #[OA\Get(
        path: "/dashboard",
        tags: ["Dashboard"],
        summary: "Dashboard Stats",
        description: "Get statistics for the school dashboard"
    )]
    #[OA\Response(
        response: 200,
        description: "Dashboard stats",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "stats", type: "object",
                    properties: [
                        new OA\Property(property: "total_students", type: "integer"),
                        new OA\Property(property: "total_teachers", type: "integer"),
                        new OA\Property(property: "total_classes", type: "integer"),
                        new OA\Property(property: "total_staff", type: "integer"),
                        new OA\Property(property: "attendance_present", type: "integer"),
                        new OA\Property(property: "attendance_absent", type: "integer"),
                    ]
                ),
                new OA\Property(property: "recent_announcements", type: "array", items: new OA\Items(type: "object"))
            ]
        )
    )]
    public function index(Request $request)
    {
        $today = Carbon::today();

        $recentAnnouncements = Announcement::where('is_published', true)
            ->latest()
            ->take(5)
            ->get();

        // Role-based Dashboard Logic
        $user = auth()->user();

        // Get today's day of week (1=Monday, 7=Sunday)
        // Carbon::dayOfWeek returns 0 for Sunday, so we map it to 1-7 (Mon-Sun) to match DB
        $dayOfWeek = $today->dayOfWeekIso; 

        if ($user->isStudent()) {
            $student = $user->student()->with(['class.homeroomTeacher'])->first();
            
            if (!$student) {
                return Inertia::render('Dashboard/StudentDashboard', [
                    'student' => $user,
                    'stats' => [
                        'attendance_percentage' => 0,
                    ],
                    'recentAnnouncements' => $recentAnnouncements,
                    'todaysSchedules' => [],
                ]);
            }
            
            // Student Stats
            $totalAttendance = Attendance::where('student_id', $student->id)->count();
            $presentAttendance = Attendance::where('student_id', $student->id)->where('status', 'present')->count();
            $attendancePercentage = $totalAttendance > 0 ? round(($presentAttendance / $totalAttendance) * 100) : 0;

            $studentStats = [
                'attendance_percentage' => $attendancePercentage,
            ];

            // Fetch Today's Schedule for Student's Class
            $todaysSchedules = [];
            if ($student->class_id) {
                $todaysSchedules = \App\Models\Schedule::where('day_of_week', $dayOfWeek)
                    ->whereHas('teachingAssignment', function ($q) use ($student) {
                        $q->where('class_id', $student->class_id);
                    })
                    ->with(['teachingAssignment.subject', 'teachingAssignment.teacher'])
                    ->orderBy('start_time')
                    ->get();
            }

            return Inertia::render('Dashboard/StudentDashboard', [
                'student' => $student,
                'stats' => $studentStats,
                'recentAnnouncements' => $recentAnnouncements,
                'todaysSchedules' => $todaysSchedules,
            ]);
        }

        if ($user->isTeacher()) {
            $teacher = $user->teacher;

            if (!$teacher) {
                return Inertia::render('Dashboard/TeacherDashboard', [
                    'teacher' => $user,
                    'stats' => [
                        'my_classes_count'   => 0,
                        'my_students_count'  => 0,
                    ],
                    'recentAnnouncements' => $recentAnnouncements,
                    'todaysSchedules' => [],
                ]);
            }

            // Teacher Stats
            $classIds = TeachingAssignment::where('teacher_id', $teacher->id)->pluck('class_id')
                ->merge(SchoolClass::where('homeroom_teacher_id', $teacher->id)->pluck('id'))
                ->unique();

            $teacherStats = [
                'my_classes_count'   => $classIds->count(),
                'my_students_count'  => Student::whereIn('class_id', $classIds)->active()->count(),
            ];

            // Fetch Today's Teaching Schedule
            $todaysSchedules = \App\Models\Schedule::where('day_of_week', $dayOfWeek)
                ->whereHas('teachingAssignment', function ($q) use ($teacher) {
                    $q->where('teacher_id', $teacher->id);
                })
                ->with(['teachingAssignment.subject', 'teachingAssignment.schoolClass'])
                ->orderBy('start_time')
                ->get();

            return Inertia::render('Dashboard/TeacherDashboard', [
                'teacher' => $teacher,
                'stats' => $teacherStats,
                'recentAnnouncements' => $recentAnnouncements,
                'todaysSchedules' => $todaysSchedules,
            ]);
        }

        // Admin Dashboard (Default)
        $academicYears = AcademicYear::orderByDesc('start_date')
            ->get(['id', 'name', 'is_active']);

        $activeAcademicYear = AcademicYear::where('is_active', true)->first();
        $requestedAcademicYear = $request->integer('academic_year_id')
            ? AcademicYear::find($request->integer('academic_year_id'))
            : null;
        $requestedSemester = $request->integer('semester_id')
            ? Semester::with('academicYear')->find($request->integer('semester_id'))
            : null;

        $selectedAcademicYear = $requestedAcademicYear
            ?? $requestedSemester?->academicYear
            ?? $activeAcademicYear
            ?? $academicYears->first();

        $semesters = Semester::query()
            ->when(
                $selectedAcademicYear,
                fn ($query) => $query->where('academic_year_id', $selectedAcademicYear->id)
            )
            ->orderBy('semester_number')
            ->get(['id', 'academic_year_id', 'semester_number', 'start_date', 'end_date', 'is_active']);

        $selectedSemester = null;
        if ($requestedSemester && (! $selectedAcademicYear || (int) $requestedSemester->academic_year_id === (int) $selectedAcademicYear->id)) {
            $selectedSemester = $semesters->firstWhere('id', $requestedSemester->id);
        }

        $selectedSemester ??= $semesters->firstWhere('is_active', true);
        $selectedSemester ??= $semesters->first();

        $stats = [
            'total_students' => $selectedSemester
                ? StudentClassEnrollment::where('semester_id', $selectedSemester->id)->distinct()->count('student_id')
                : Student::active()->count(),
            'total_teachers' => Teacher::where('status', 'active')->count(),
            'total_classes' => $selectedAcademicYear
                ? SchoolClass::where('academic_year_id', $selectedAcademicYear->id)->count()
                : SchoolClass::count(),
            'total_staff' => Teacher::count(),
            'attendance_present' => $selectedSemester
                ? Attendance::where('semester_id', $selectedSemester->id)->where('status', 'present')->count()
                : Attendance::whereDate('date', $today)->where('status', 'present')->count(),
            'attendance_absent' => $selectedSemester
                ? Attendance::where('semester_id', $selectedSemester->id)->where('status', '!=', 'present')->count()
                : Attendance::whereDate('date', $today)->where('status', '!=', 'present')->count(),
        ];

        return Inertia::render('Dashboard/AdminDashboard', [
            'stats'        => $stats,
            'recentAnnouncements' => $recentAnnouncements,
            'academicYears' => $academicYears,
            'semesters' => $semesters,
            'filters' => [
                'academic_year_id' => $selectedAcademicYear?->id,
                'semester_id' => $selectedSemester?->id,
            ],
        ]);
    }
}
