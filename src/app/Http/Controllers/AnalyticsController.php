<?php

namespace App\Http\Controllers;

use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\TeachingAssignment;
use App\Services\AnalyticsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Gate;
use Inertia\Inertia;
use Inertia\Response;

class AnalyticsController extends Controller
{
    public function __construct(private readonly AnalyticsService $analytics) {}

    public function index(): Response
    {
        $this->authorize('view-analytics');

        $user     = Auth::user();
        $semester = Semester::where('is_active', true)->firstOrFail();

        return Inertia::render('Analytics/Dashboard', [
            'todaysAttendance'   => $this->analytics->todaysAttendance($user),
            'missingAttendance'  => $user->isSchoolAdmin()
                                        ? $this->analytics->classesMissingAttendance()
                                        : null,
            'classAvgComparison' => $this->analytics->classAvgComparison($semester->id, $user),
            'activeSemester'     => $semester,
            'isAdmin'            => $user->isSchoolAdmin(),
        ]);
    }

    public function reports(): Response
    {
        $this->authorize('view-analytics');

        $user     = Auth::user();
        $semester = Semester::where('is_active', true)->firstOrFail();
        $ay       = $semester->academicYear;

        // Scope classes dropdown to teacher's visible classes
        $classQuery = SchoolClass::where('academic_year_id', $ay->id)->orderBy('name');

        if (! $user->isSchoolAdmin() && $user->teacher) {
            $teacher  = $user->teacher;
            $homeroom = SchoolClass::where('homeroom_teacher_id', $teacher->id)->pluck('id');
            $taught   = TeachingAssignment::where('teacher_id', $teacher->id)->pluck('class_id');
            $visible  = $homeroom->merge($taught)->unique()->values()->all();
            $classQuery->whereIn('id', $visible);
        }

        return Inertia::render('Analytics/Reports', [
            'activeSemester'  => $semester,
            'teacherWorkload' => $user->isSchoolAdmin()
                                    ? $this->analytics->teacherWorkload($ay->id)
                                    : null,
            'classes'         => $classQuery->get(['id', 'name']),
            'isAdmin'         => $user->isSchoolAdmin(),
        ]);
    }

    public function data(Request $request, string $widget): JsonResponse
    {
        $this->authorize('view-analytics');

        $user = Auth::user();

        // Widget-level gate for admin-only widgets
        if (! Gate::allows('viewWidget', $widget)) {
            abort(403, "Widget {$widget} is restricted to administrators.");
        }

        $semesterId = (int) $request->input(
            'semester_id',
            Semester::where('is_active', true)->value('id')
        );
        $classId = (int) $request->input('class_id', 0);

        $result = match ($widget) {
            'subject-grade-distribution' => $this->analytics->subjectGradeDistribution($classId, $semesterId, $user),
            'attendance-trend'           => $this->analytics->attendanceTrend($classId, $semesterId, 12, $user),
            'at-risk-students'           => $this->analytics->atRiskStudents($semesterId, null, $user),
            'teacher-workload'           => $this->analytics->teacherWorkload(
                                               Semester::findOrFail($semesterId)->academicYear->id,
                                               $user
                                           ),
            default => abort(404, "Widget {$widget} not found"),
        };

        return response()->json($result);
    }

    public function exportAttendance(Request $request)
    {
        $this->authorize('view-analytics');

        $request->validate(['semester_id' => 'required|integer|exists:semesters,id']);

        $user       = Auth::user();
        $semester   = Semester::with('academicYear')->findOrFail($request->semester_id);
        $schoolName = config('app.school_name', 'Sekolah');
        $filename   = "Rekap_Absensi_{$schoolName}_{$semester->academicYear->name}_Sem{$semester->semester_number}_" . now()->format('Ymd') . '.xlsx';

        return \Maatwebsite\Excel\Facades\Excel::download(
            new \App\Exports\AttendanceRecapExport($semester->id, $user),
            $filename
        );
    }

    public function exportGrades(Request $request)
    {
        $this->authorize('view-analytics');

        $request->validate([
            'class_id'   => 'required|integer|exists:classes,id',
            'semester_id'=> 'required|integer|exists:semesters,id',
            'subject_id' => 'nullable|integer|exists:subjects,id',
        ]);

        $user      = Auth::user();
        $classId   = (int) $request->class_id;
        $semId     = (int) $request->semester_id;
        $subjectId = $request->subject_id ? (int) $request->subject_id : null;

        // Authorization: non-admin teachers may only export subjects they teach in that class
        if (! $user->isSchoolAdmin()) {
            $teacher = $user->teacher;
            if (! $teacher) {
                abort(403, 'Akses ditolak.');
            }

            if ($subjectId !== null) {
                // Teacher must teach this subject in this class
                $hasAssignment = TeachingAssignment::where('teacher_id', $teacher->id)
                    ->where('class_id', $classId)
                    ->where('subject_id', $subjectId)
                    ->exists();

                if (! $hasAssignment) {
                    // Homeroom teacher may export all subjects for their class
                    $isHomeroom = \App\Models\SchoolClass::where('id', $classId)
                        ->where('homeroom_teacher_id', $teacher->id)
                        ->exists();

                    if (! $isHomeroom) {
                        abort(403, 'Anda tidak mengajar mata pelajaran ini di kelas ini.');
                    }
                }
            } else {
                // Exporting all subjects: must be homeroom or have at least one assignment in class
                $isHomeroom = \App\Models\SchoolClass::where('id', $classId)
                    ->where('homeroom_teacher_id', $teacher->id)
                    ->exists();

                $hasAnyAssignment = TeachingAssignment::where('teacher_id', $teacher->id)
                    ->where('class_id', $classId)
                    ->exists();

                if (! $isHomeroom && ! $hasAnyAssignment) {
                    abort(403, 'Anda tidak memiliki akses ke kelas ini.');
                }
            }
        }

        $class    = \App\Models\SchoolClass::findOrFail($classId);
        $semester = Semester::findOrFail($semId);

        $filename = "Rekap_Nilai_{$class->name}_{$semester->name}_" . now()->format('Ymd') . '.xlsx';

        return \Maatwebsite\Excel\Facades\Excel::download(
            new \App\Exports\GradeRecapExport($classId, $semId, $subjectId, $user),
            $filename
        );
    }
}
