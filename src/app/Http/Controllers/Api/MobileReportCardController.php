<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ReportCard;
use Illuminate\Http\Request;

class MobileReportCardController extends Controller
{
    /**
     * GET /api/v1/report-cards
     * List report cards for the authenticated user.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        if ($user->isStudent()) {
            $student = $user->student;
            if (!$student) {
                return response()->json(['report_cards' => []]);
            }

            $reportCards = ReportCard::where('student_id', $student->id)
                ->where('status', 'published') // Only show published report cards
                ->with('semester')
                ->latest('published_at')
                ->get()
                ->map(fn($rc) => [
                    'id'            => $rc->id,
                    'semester_name' => $rc->semester->name ?? 'Semester',
                    'academic_year' => $rc->semester->academicYear->name ?? 'Tahun Ajaran',
                    'average_score' => $rc->average_score,
                    'rank'          => $rc->rank,
                    'published_at'  => $rc->published_at?->toISOString(),
                ]);

            return response()->json(['report_cards' => $reportCards]);
        }

        // Parent and Teacher logic can be added later as needed
        return response()->json(['report_cards' => []]);
    }

    /**
     * GET /api/v1/report-cards/{id}
     * Detail report card
     */
    public function show(Request $request, $id)
    {
        $user = $request->user();
        
        if ($user->isStudent()) {
            $student = $user->student;
            if (!$student) {
                return response()->json(['message' => 'Not found'], 404);
            }

            $rc = ReportCard::where('id', $id)
                ->where('student_id', $student->id)
                ->where('status', 'published')
                ->with(['semester.academicYear', 'schoolClass'])
                ->firstOrFail();

            return response()->json([
                'id'                 => $rc->id,
                'semester_name'      => $rc->semester->name ?? '-',
                'academic_year'      => $rc->semester->academicYear->name ?? '-',
                'class_name'         => $rc->schoolClass->name ?? '-',
                'average_score'      => $rc->average_score,
                'total_score'        => $rc->total_score,
                'rank'               => $rc->rank,
                'attendance_present' => $rc->attendance_present,
                'attendance_sick'    => $rc->attendance_sick,
                'attendance_permit'  => $rc->attendance_permit,
                'attendance_absent'  => $rc->attendance_absent,
                'achievements'       => $rc->achievements,
                'notes'              => $rc->notes,
                'behavior_notes'     => $rc->behavior_notes,
                'homeroom_comment'   => $rc->homeroom_comment,
                'principal_comment'  => $rc->principal_comment,
                'pdf_url'            => $rc->pdf_url,
                'published_at'       => $rc->published_at?->toISOString(),
            ]);
        }

        return response()->json(['message' => 'Unauthorized'], 403);
    }

    /**
     * GET /api/v1/report-cards/{id}/pdf
     * Retrieve PDF download URL or stream the PDF
     */
    public function pdf(Request $request, $id)
    {
        $user = $request->user();

        if ($user->isStudent()) {
            $student = $user->student;
            $rc = ReportCard::where('id', $id)
                ->where('student_id', $student->id)
                ->where('status', 'published')
                ->firstOrFail();

            if ($rc->pdf_url) {
                return response()->json(['url' => $rc->pdf_url]);
            }

            // Fallback generation if PDF is not statically stored
            return response()->json(['message' => 'PDF URL not available'], 404);
        }

        return response()->json(['message' => 'Unauthorized'], 403);
    }
}
