<?php

namespace App\Http\Controllers;

use App\Models\SchoolClass;
use App\Models\Semester;
use App\Services\AnalyticsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class AnalyticsController extends Controller
{
    public function __construct(private readonly AnalyticsService $analytics) {}

    public function index(): Response
    {
        $this->authorize('view-analytics');

        $semester = Semester::where('is_active', true)->firstOrFail();
        $ay       = $semester->academicYear;

        return Inertia::render('Analytics/Dashboard', [
            'todaysAttendance'   => $this->analytics->todaysAttendance(),
            'missingAttendance'  => $this->analytics->classesMissingAttendance(),
            'classAvgComparison' => $this->analytics->classAvgComparison($semester->id),
            'activeSemester'     => $semester,
        ]);
    }

    public function reports(): Response
    {
        $this->authorize('view-analytics');

        $semester = Semester::where('is_active', true)->firstOrFail();
        $ay       = $semester->academicYear;

        return Inertia::render('Analytics/Reports', [
            'activeSemester'  => $semester,
            'teacherWorkload' => $this->analytics->teacherWorkload($ay->id),
            'classes'         => SchoolClass::where('academic_year_id', $ay->id)
                                    ->orderBy('name')
                                    ->get(['id', 'name']),
        ]);
    }

    public function data(Request $request, string $widget): JsonResponse
    {
        $this->authorize('view-analytics');

        $semesterId = (int) $request->input(
            'semester_id',
            Semester::where('is_active', true)->value('id')
        );
        $classId = (int) $request->input('class_id', 0);

        $result = match ($widget) {
            'subject-grade-distribution' => $this->analytics->subjectGradeDistribution($classId, $semesterId),
            'attendance-trend'           => $this->analytics->attendanceTrend($classId, $semesterId),
            'at-risk-students'           => $this->analytics->atRiskStudents($semesterId),
            'teacher-workload'           => $this->analytics->teacherWorkload(
                                               Semester::findOrFail($semesterId)->academicYear->id
                                           ),
            default => abort(404, "Widget {$widget} not found"),
        };

        return response()->json($result);
    }

    public function exportAttendance(Request $request)
    {
        $this->authorize('view-analytics');

        $request->validate(['semester_id' => 'required|integer|exists:semesters,id']);

        $semester   = Semester::with('academicYear')->findOrFail($request->semester_id);
        $schoolName = config('app.school_name', 'Sekolah');
        $filename   = "Rekap_Absensi_{$schoolName}_{$semester->academicYear->name}_Sem{$semester->semester_number}_" . now()->format('Ymd') . '.xlsx';

        return \Maatwebsite\Excel\Facades\Excel::download(
            new \App\Exports\AttendanceRecapExport($semester->id),
            $filename
        );
    }
}
