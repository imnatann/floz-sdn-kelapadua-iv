<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\ReportCard;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Services\PdfGeneratorService;
use App\Services\ReportCardService;
use Illuminate\Http\Request;
use Inertia\Inertia;
use OpenApi\Attributes as OA;

class ReportCardController extends Controller
{
    public function __construct(
        protected ReportCardService $reportCardService,
        protected PdfGeneratorService $pdfService,
    ) {}

    #[OA\Get(
        path: "/report-cards",
        tags: ["Report Cards"],
        summary: "List Report Cards",
        description: "Get list of report cards with filtering"
    )]
    #[OA\Parameter(name: "class_id", in: "query", description: "Filter by class ID", required: false, schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "semester_id", in: "query", description: "Filter by semester ID", required: false, schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "status", in: "query", description: "Filter by status", required: false, schema: new OA\Schema(type: "string", enum: ["draft", "published"]))]
    #[OA\Response(response: 200, description: "List of report cards")]
    public function index(Request $request)
    {
        $user = auth()->user();

        // If the user is a student, show only their report cards
        if ($user->isStudent()) {
            $studentId = $user->student->id;
            
            // Get semesters where the student has grades or a report card
            $semesters = Semester::with('academicYear')->whereHas('grades', function ($query) use ($studentId) {
                $query->where('student_id', $studentId);
            })->orWhereHas('reportCards', function ($query) use ($studentId) {
                $query->where('student_id', $studentId);
            })->orderByDesc('start_date')->get();

            $selectedSemesterId = $request->semester_id ?? $semesters->first()?->id;

            // Get grades for the selected semester
            $grades = [];
            $reportCard = null;

            if ($selectedSemesterId) {
                $grades = \App\Models\Grade::with('subject')
                    ->where('student_id', $studentId)
                    ->where('semester_id', $selectedSemesterId)
                    ->get();
                
                $reportCard = ReportCard::with(['schoolClass.homeroomTeacher', 'semester.academicYear'])
                    ->where('student_id', $studentId)
                    ->where('semester_id', $selectedSemesterId)
                    ->first();
            }

            return Inertia::render('ReportCards/StudentIndex', [
                'semesters'   => $semesters,
                'grades'      => $grades,
                'reportCard'  => $reportCard,
                'filters'     => ['semester_id' => $selectedSemesterId],
            ]);
        }

        // For teachers and administrators, show the regular view
        $reportCards = ReportCard::query()
            ->with(['student', 'schoolClass', 'semester.academicYear'])
            ->when($request->class_id, fn($q, $c) => $q->where('class_id', $c))
            ->when($request->semester_id, fn($q, $s) => $q->where('semester_id', $s))
            ->when($request->status, fn($q, $s) => $q->where('status', $s))
            ->orderByRaw('CASE WHEN rank IS NULL THEN 1 ELSE 0 END')
            ->orderBy('rank')
            ->orderBy('id')
            ->paginate(20)
            ->withQueryString();

        $classes = SchoolClass::where('status', 'active')->get(['id', 'name']);
        $semesters = Semester::with('academicYear')->get();

        // Class IDs the user may generate/publish report cards for:
        //  - admin: all active classes
        //  - teacher: only classes where they are homeroom teacher (wali kelas)
        if ($user->isSchoolAdmin()) {
            $manageableClassIds = $classes->pluck('id')->all();
        } elseif ($user->isTeacher() && $user->teacher) {
            $manageableClassIds = SchoolClass::where('homeroom_teacher_id', $user->teacher->id)
                ->pluck('id')
                ->all();
        } else {
            $manageableClassIds = [];
        }

        return Inertia::render('ReportCards/Index', [
            'reportCards'         => $reportCards,
            'classes'             => $classes,
            'semesters'           => $semesters,
            'filters'             => $request->only(['class_id', 'semester_id', 'status']),
            'manageableClassIds'  => $manageableClassIds,
        ]);
    }

    /**
     * Assert the user may generate/publish report cards for the given class.
     * Admin: always allowed. Teacher: only if homeroom of that class.
     */
    private function authorizeManageClass(int $classId): void
    {
        $user = auth()->user();
        if ($user->isSchoolAdmin()) {
            return;
        }
        if ($user->isTeacher() && $user->teacher) {
            $isHomeroom = SchoolClass::where('id', $classId)
                ->where('homeroom_teacher_id', $user->teacher->id)
                ->exists();
            abort_unless($isHomeroom, 403, 'Hanya wali kelas yang dapat mengelola rapor kelas ini.');
            return;
        }
        abort(403, 'Unauthorized');
    }

    #[OA\Post(
        path: "/report-cards/generate",
        tags: ["Report Cards"],
        summary: "Generate Report Cards",
        description: "Generate report cards for a class and semester"
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["class_id", "semester_id", "report_type"],
            properties: [
                new OA\Property(property: "class_id", type: "integer"),
                new OA\Property(property: "semester_id", type: "integer"),
                new OA\Property(property: "report_type", type: "string", enum: ["uts", "final"]),
            ]
        )
    )]
    #[OA\Response(response: 302, description: "Redirect to index")]
    public function generate(Request $request)
    {
        $validated = $request->validate([
            'class_id'    => 'required|exists:classes,id',
            'semester_id' => 'required|exists:semesters,id',
            'report_type' => 'required|in:uts,final',
        ]);

        $this->authorizeManageClass((int) $validated['class_id']);

        $class = SchoolClass::with('students')->findOrFail($validated['class_id']);

        foreach ($class->students as $student) {
            $this->reportCardService->generate(
                $student->id,
                $validated['class_id'],
                $validated['semester_id'],
                $validated['report_type']
            );
        }

        // Calculate rankings
        $this->reportCardService->calculateRankings(
            $validated['class_id'],
            $validated['semester_id'],
            $validated['report_type']
        );

        return redirect()->route('report-cards.index', [
            'class_id'    => $validated['class_id'],
            'semester_id' => $validated['semester_id'],
        ])->with('success', 'Rapor berhasil digenerate untuk seluruh siswa di kelas ini.');
    }

    #[OA\Get(
        path: "/report-cards/{reportCard}",
        tags: ["Report Cards"],
        summary: "Show Report Card",
        description: "Get detailed view of a report card"
    )]
    #[OA\Parameter(name: "reportCard", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Report card details")]
    public function show(ReportCard $reportCard)
    {
        $reportCard->load([
            'student',
            'schoolClass.homeroomTeacher',
            'semester.academicYear',
        ]);

        $grades = \App\Models\Grade::where('student_id', $reportCard->student_id)
            ->where('semester_id', $reportCard->semester_id)
            ->with('subject')
            ->orderBy('subject_id')
            ->get();

        $user = auth()->user();
        $canManage = $user->isSchoolAdmin()
            || ($user->isTeacher() && $user->teacher && SchoolClass::where('id', $reportCard->class_id)
                ->where('homeroom_teacher_id', $user->teacher->id)
                ->exists());

        return Inertia::render('ReportCards/Show', [
            'reportCard' => $reportCard,
            'grades'     => $grades,
            'canManage'  => $canManage,
        ]);
    }

    #[OA\Post(
        path: "/report-cards/{reportCard}/publish",
        tags: ["Report Cards"],
        summary: "Publish Report Card",
        description: "Mark a report card as published"
    )]
    #[OA\Parameter(name: "reportCard", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 302, description: "Redirect back")]
    public function publish(ReportCard $reportCard)
    {
        $this->authorizeManageClass($reportCard->class_id);

        $this->reportCardService->publish($reportCard);

        return back()->with('success', 'Rapor berhasil dipublikasikan.');
    }

    #[OA\Get(
        path: "/report-cards/{reportCard}/pdf",
        tags: ["Report Cards"],
        summary: "Download Report Card PDF",
        description: "Download the PDF version of the report card"
    )]
    #[OA\Parameter(name: "reportCard", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(
        response: 200,
        description: "PDF File",
        content: new OA\MediaType(
            mediaType: "application/pdf",
            schema: new OA\Schema(type: "string", format: "binary")
        )
    )]
    public function downloadPdf(ReportCard $reportCard)
    {
        $path = $this->pdfService->generateReportCardPdf($reportCard);

        return response()->download($path);
    }
}
