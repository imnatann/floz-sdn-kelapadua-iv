<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Grade;
use App\Models\Subject;
use Illuminate\Http\Request;

class MobileGradeController extends Controller
{
    /**
     * GET /api/v1/grades
     * List grades grouped by subject for the authenticated student.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        if ($user->isStudent()) {
            $student = $user->student;
            if (!$student) {
                return response()->json(['grades' => []]);
            }

            $grades = Grade::where('student_id', $student->id)
                ->with('subject')
                ->get()
                ->groupBy('subject_id')
                ->map(function ($subjectGrades, $subjectId) {
                    $subject = $subjectGrades->first()->subject;
                    $avg = round($subjectGrades->avg('final_score'), 1) ?? 0.0;
                    return [
                        'subject_id'   => $subjectId,
                        'subject_name' => $subject->name ?? '-',
                        'average'      => (float) $avg,
                        'grade_count'  => $subjectGrades->count(),
                    ];
                })
                ->values();

            return response()->json(['grades' => $grades]);
        }

        if ($user->isTeacher()) {
            // Teacher: list subjects they teach
            $teacher = $user->teacher;
            if (!$teacher) {
                return response()->json(['subjects' => []]);
            }

            $subjects = $teacher->teachingAssignments()
                ->with(['subject', 'schoolClass'])
                ->get()
                ->map(fn($ta) => [
                    'teaching_assignment_id' => $ta->id,
                    'subject_id'   => $ta->subject_id,
                    'subject_name' => $ta->subject->name ?? '-',
                    'class_id'     => $ta->class_id,
                    'class_name'   => $ta->schoolClass->name ?? '-',
                ]);

            return response()->json(['subjects' => $subjects]);
        }

        return response()->json(['grades' => []]);
    }

    /**
     * GET /api/v1/grades/{subjectId}
     * Detail grades for a specific subject.
     */
    public function show(Request $request, $subjectId)
    {
        $user = $request->user();

        if ($user->isStudent()) {
            $student = $user->student;
            if (!$student) {
                return response()->json(['grades' => []]);
            }

            $grades = Grade::where('student_id', $student->id)
                ->where('subject_id', $subjectId)
                ->with('subject')
                ->get()
                ->map(fn($g) => [
                    'id'           => $g->id,
                    'component'    => $g->description ?? '-',
                    'score'        => (float) ($g->knowledge_score ?? 0),
                    'final_score'  => (float) ($g->final_score ?? 0),
                    'kkm'          => (float) ($g->subject->kkm ?? 75),
                    'predicate'    => $g->predicate,
                    'semester'     => 'Semester ' . ($g->semester->semester_number ?? '-'),
                    'created_at'   => $g->created_at?->toISOString(),
                ]);

            $subject = Subject::find($subjectId);

            return response()->json([
                'subject' => [
                    'id'   => $subject?->id,
                    'name' => $subject?->name,
                ],
                'grades' => $grades,
            ]);
        }

        return response()->json(['grades' => []]);
    }
}
