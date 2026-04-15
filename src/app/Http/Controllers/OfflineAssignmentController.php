<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\OfflineAssignment;
use App\Models\OfflineAssignmentAnswer;
use App\Models\OfflineAssignmentQuestion;
use App\Models\OfflineAssignmentSubmission;
use App\Models\SchoolClass;
use App\Models\Subject;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Inertia\Inertia;

class OfflineAssignmentController extends Controller
{
    public function index(Request $request)
    {
        $user = auth()->user();
        $this->authorize('viewAny', OfflineAssignment::class);

        $assignments = OfflineAssignment::query()
            ->with(['subject', 'classes'])
            ->when($user->isStudent(), function ($query) use ($user) {
                // Students only see active assignments for their class
                $query->where('status', 'active');
                $student = $user->student;
                if ($student) {
                    $query->whereHas('classes', function ($q) use ($student) {
                        $q->where('classes.id', $student->class_id);
                    });
                } else {
                    $query->whereRaw('1 = 0'); // No student record, return empty
                }
            })
            // Teachers see all by default (or could filter by their own if needed)
            ->when($request->search, function ($query, $search) {
                $query->where('title', 'like', "%{$search}%");
            })
            ->when($request->class_id, function ($query, $classId) {
                $query->whereHas('classes', function ($q) use ($classId) {
                    $q->where('classes.id', $classId);
                });
            })
            ->when($request->subject_id, function ($query, $subjectId) {
                $query->where('subject_id', $subjectId);
            })
            ->latest()
            ->paginate(20)
            ->withQueryString();
            
        // For students, load their submission status for each assignment
        if ($user->isStudent() && $user->student) {
             $assignments->getCollection()->transform(function ($assignment) use ($user) {
                $submission = OfflineAssignmentSubmission::where('offline_assignment_id', $assignment->id)
                    ->where('student_id', $user->student->id)
                    ->first();
                $assignment->student_submission = $submission;
                return $assignment;
            });
        }

        return Inertia::render('Tenant/Assignments/Index', [
            'assignments' => $assignments,
            'subjects' => Subject::orderBy('name')->get(['id', 'name']),
            'classes' => SchoolClass::orderBy('name')->get(['id', 'name']),
            'filters' => $request->only(['search', 'class_id', 'subject_id']),
            'is_student' => $user->isStudent(),
        ]);
    }

    public function create(Request $request)
    {
        $this->authorize('create', OfflineAssignment::class);

        $meeting = null;
        if ($request->meeting_id) {
            $meeting = \App\Models\Meeting::with('teachingAssignment.subject', 'teachingAssignment.schoolClass')
                ->find($request->meeting_id);
        }
        
        return Inertia::render('Tenant/Assignments/Create', [
            'subjects' => Subject::orderBy('name')->get(['id', 'name']),
            'classes' => SchoolClass::orderBy('name')->get(['id', 'name']),
            'meeting' => $meeting,
        ]);
    }

    public function edit(OfflineAssignment $offlineAssignment)
    {
        $this->authorize('update', $offlineAssignment);
        
        $offlineAssignment->load(['classes', 'files', 'questions']);
        
        return Inertia::render('Tenant/Assignments/Edit', [
            'assignment' => $offlineAssignment,
            'subjects' => Subject::orderBy('name')->get(['id', 'name']),
            'classes' => SchoolClass::orderBy('name')->get(['id', 'name']),
        ]);
    }

    public function store(Request $request)
    {
        $this->authorize('create', OfflineAssignment::class);
        
        $request->validate([
            'subject_id' => ['required', \Illuminate\Validation\Rule::exists(Subject::class, 'id')],
            'classes' => 'required|array|min:1',
            'classes.*' => [\Illuminate\Validation\Rule::exists(SchoolClass::class, 'id')],
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'due_date' => 'required|date',
            'status' => 'required|in:active,inactive',
            'type' => 'required|in:manual,quiz',
            'file' => 'nullable|file|max:102400',
            // Quiz questions
            'questions' => 'nullable|array',
            'questions.*.question_text' => 'required_with:questions|string',
            'questions.*.question_type' => 'required_with:questions|in:multiple_choice,essay,true_false',
            'questions.*.options' => 'nullable|array',
            'questions.*.correct_answer' => 'nullable|string',
            'questions.*.points' => 'required_with:questions|numeric|min:0',
        ]);

        $assignment = OfflineAssignment::create([
            'teacher_id' => auth()->user()->teacher->id ?? 1,
            'subject_id' => $request->subject_id,
            'meeting_id' => $request->meeting_id,
            'title' => $request->title,
            'description' => $request->description,
            'due_date' => $request->due_date,
            'status' => $request->status,
            'type' => $request->type,
            'created_by' => auth()->id(),
        ]);

        $assignment->classes()->sync($request->classes);

        if ($request->hasFile('file')) {
            $file = $request->file('file');
            $path = $file->store('assignments/' . $assignment->id, 'public');

            $assignment->files()->create([
                'file_path' => $path,
                'file_name' => $file->getClientOriginalName(),
                'file_type' => $file->getMimeType(),
                'file_size' => $file->getSize(),
            ]);
        }

        // Save quiz questions
        if ($request->type === 'quiz' && $request->questions) {
            foreach ($request->questions as $i => $q) {
                $assignment->questions()->create([
                    'question_text' => $q['question_text'],
                    'question_type' => $q['question_type'],
                    'options' => $q['options'] ?? null,
                    'correct_answer' => $q['correct_answer'] ?? null,
                    'points' => $q['points'],
                    'sort_order' => $i,
                ]);
            }
        }

        // Redirect back to course page if created from meeting context
        if ($request->meeting_id) {
            $meeting = \App\Models\Meeting::find($request->meeting_id);
            if ($meeting) {
                return redirect("/tenant/courses/{$meeting->teaching_assignment_id}")->with('success', 'Tugas berhasil dibuat.');
            }
        }

        return to_route('assignments.index')->with('success', 'Tugas berhasil dibuat.');
    }

    public function update(Request $request, OfflineAssignment $offlineAssignment)
    {
        $this->authorize('update', $offlineAssignment);
        
        $request->validate([
            'subject_id' => ['required', \Illuminate\Validation\Rule::exists(Subject::class, 'id')],
            'classes' => 'required|array|min:1',
            'classes.*' => [\Illuminate\Validation\Rule::exists(SchoolClass::class, 'id')],
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'due_date' => 'required|date',
            'status' => 'required|in:active,inactive',
            'type' => 'required|in:manual,quiz',
            'file' => 'nullable|file|max:102400',
            'questions' => 'nullable|array',
            'questions.*.question_text' => 'required_with:questions|string',
            'questions.*.question_type' => 'required_with:questions|in:multiple_choice,essay,true_false',
            'questions.*.options' => 'nullable|array',
            'questions.*.correct_answer' => 'nullable|string',
            'questions.*.points' => 'required_with:questions|numeric|min:0',
        ]);

        $offlineAssignment->update([
            'subject_id' => $request->subject_id,
            'title' => $request->title,
            'description' => $request->description,
            'due_date' => $request->due_date,
            'status' => $request->status,
            'type' => $request->type,
        ]);

        $offlineAssignment->classes()->sync($request->classes);

        if ($request->hasFile('file')) {
            $file = $request->file('file');
            $path = $file->store('assignments/' . $offlineAssignment->id, 'public');

            $offlineAssignment->files()->create([
                'file_path' => $path,
                'file_name' => $file->getClientOriginalName(),
                'file_type' => $file->getMimeType(),
                'file_size' => $file->getSize(),
            ]);
        }

        // Sync quiz questions
        if ($request->type === 'quiz' && $request->questions) {
            $offlineAssignment->questions()->delete();
            foreach ($request->questions as $i => $q) {
                $offlineAssignment->questions()->create([
                    'question_text' => $q['question_text'],
                    'question_type' => $q['question_type'],
                    'options' => $q['options'] ?? null,
                    'correct_answer' => $q['correct_answer'] ?? null,
                    'points' => $q['points'],
                    'sort_order' => $i,
                ]);
            }
        } elseif ($request->type === 'manual') {
            $offlineAssignment->questions()->delete();
        }

        return to_route('assignments.index')->with('success', 'Tugas berhasil diperbarui.');
    }

    public function destroy(OfflineAssignment $offlineAssignment)
    {
        $this->authorize('delete', $offlineAssignment);
        
        $offlineAssignment->delete();
        return back()->with('success', 'Tugas berhasil dihapus.');
    }

    public function show(OfflineAssignment $offlineAssignment)
    {
        $user = auth()->user();
        $this->authorize('view', $offlineAssignment); // Basic check

        $offlineAssignment->load(['subject', 'classes', 'files']);
        
        if ($user->isStudent()) {
             $student = $user->student;
             if (!$student) {
                 abort(403);
             }
             // Check if student is in the allowed classes (redundant with Policy but good for safety)
             if (!$offlineAssignment->classes->pluck('id')->contains($student->class_id)) {
                 abort(403);
             }
             
             $submission = OfflineAssignmentSubmission::where('offline_assignment_id', $offlineAssignment->id)
                ->where('student_id', $student->id)
                ->with('files')
                ->first();

             // Load questions for quiz
             $questions = $offlineAssignment->isQuiz() ? $offlineAssignment->questions : [];
             
             // Load answers if submission exists for quiz
             $answers = [];
             if ($submission && $offlineAssignment->isQuiz()) {
                 $answers = OfflineAssignmentAnswer::where('submission_id', $submission->id)->get()->keyBy('question_id');
             }
             
             // Load meeting context for Activity Navigation
             $meeting = null;
             if ($offlineAssignment->meeting_id) {
                 $meeting = \App\Models\Meeting::with([
                    'materials' => function($q) { $q->orderBy('sort_order')->orderBy('id'); },
                    'assignments' => function($q) { $q->orderBy('id'); }
                 ])->find($offlineAssignment->meeting_id);
             }

             return Inertia::render('Tenant/Assignments/Show', [
                'assignment' => $offlineAssignment,
                'submission' => $submission,
                'meeting' => $meeting,
                'is_student' => true,
                'is_past_due' => $offlineAssignment->due_date->isPast(),
                'questions' => $questions,
                'answers' => $answers,
             ]);
        }
        
        // Teacher Logic (Show all students)
        
        // Get all students from the assigned classes
        $classIds = $offlineAssignment->classes->pluck('id');
        
        // Manual pagination for student results
        $students = Student::whereIn('class_id', $classIds)
            ->with(['class'])
            ->orderBy('name')
            ->paginate(20);
            
        // Load submissions for these students
        $submissions = OfflineAssignmentSubmission::where('offline_assignment_id', $offlineAssignment->id)
            ->whereIn('student_id', $students->pluck('id'))
            ->get()
            ->keyBy('student_id');

        // Transform students to include submission data
        $students->getCollection()->transform(function ($student) use ($submissions) {
            $submission = $submissions->get($student->id);
            $student->submission = $submission;
            return $student;
        });

        // Load meeting context for Activity Navigation
        $meeting = null;
        if ($offlineAssignment->meeting_id) {
            $meeting = \App\Models\Meeting::with([
                'materials' => function($q) { $q->orderBy('sort_order')->orderBy('id'); },
                'assignments' => function($q) { $q->orderBy('id'); }
            ])->find($offlineAssignment->meeting_id);
        }

        return Inertia::render('Tenant/Assignments/Show', [
            'assignment' => $offlineAssignment,
            'students' => $students,
            'meeting' => $meeting,
            'is_student' => false,
            'is_past_due' => $offlineAssignment->due_date->isPast(),
        ]);
    }
    
    public function submit(Request $request, OfflineAssignment $offlineAssignment)
    {
        $user = auth()->user();
        if (!$user->isStudent()) {
            abort(403);
        }
        
        $this->authorize('submit', $offlineAssignment);

        // Different validation based on assignment type
        if ($offlineAssignment->isQuiz()) {
            $request->validate([
                'answers' => 'required|array',
                'answers.*.question_id' => 'required|integer',
                'answers.*.answer' => 'nullable|string',
            ]);
        } else {
            $request->validate([
                'answer_text' => 'nullable|string',
                'answer_link' => 'nullable|url',
                'file' => 'nullable|file|max:102400',
            ]);
            
            if (!$request->answer_text && !$request->answer_link && !$request->hasFile('file')) {
                return back()->with('error', 'Mohon lengkapi jawaban anda (teks, link, atau file).');
            }
        }

        $submission = OfflineAssignmentSubmission::firstOrNew([
            'offline_assignment_id' => $offlineAssignment->id,
            'student_id' => $user->student->id,
        ]);
        
        $submission->submitted_at = now();

        if ($offlineAssignment->isManual()) {
            $submission->answer_text = $request->answer_text;
            $submission->answer_link = $request->answer_link;
        }
        
        $submission->save();

        // Handle file upload for manual
        if ($offlineAssignment->isManual() && $request->hasFile('file')) {
            $file = $request->file('file');
            $path = $file->store('submissions/' . $offlineAssignment->id, 'public');

            $submission->files()->create([
                'file_path' => $path,
                'file_name' => $file->getClientOriginalName(),
                'file_type' => $file->getMimeType(),
                'file_size' => $file->getSize(),
            ]);
        }

        // Handle quiz answers with auto-grading
        if ($offlineAssignment->isQuiz() && $request->answers) {
            $totalPoints = 0;
            $earnedPoints = 0;
            
            // Delete previous answers
            $submission->answers()->delete();

            foreach ($request->answers as $ans) {
                $question = OfflineAssignmentQuestion::find($ans['question_id']);
                if (!$question) continue;

                $totalPoints += $question->points;
                $isCorrect = null;
                $pointsEarned = 0;

                // Auto-grade for multiple_choice and true_false
                if (in_array($question->question_type, ['multiple_choice', 'true_false'])) {
                    $isCorrect = strtolower(trim($ans['answer'] ?? '')) === strtolower(trim($question->correct_answer ?? ''));
                    $pointsEarned = $isCorrect ? $question->points : 0;
                    $earnedPoints += $pointsEarned;
                }
                // Essay questions are graded manually by teacher

                OfflineAssignmentAnswer::create([
                    'submission_id' => $submission->id,
                    'question_id' => $question->id,
                    'answer' => $ans['answer'] ?? null,
                    'is_correct' => $isCorrect,
                    'points_earned' => $pointsEarned,
                ]);
            }

            // Auto-set grade if all questions are auto-gradable
            $hasEssay = $offlineAssignment->questions()->where('question_type', 'essay')->exists();
            if (!$hasEssay && $totalPoints > 0) {
                $submission->grade = round(($earnedPoints / $totalPoints) * 100, 2);
                $submission->save();
            }
        }

        return back()->with('success', 'Tugas berhasil dikumpulkan.');
    }

    public function showStudent(OfflineAssignment $offlineAssignment, Student $student)
    {
        $this->authorize('view', $offlineAssignment); // Teacher only practically via Policy or we add specific check
        if (!auth()->user()->isTeacher()) abort(403);

        $offlineAssignment->load(['subject']);
        $student->load(['class']);
        
        $submission = OfflineAssignmentSubmission::where('offline_assignment_id', $offlineAssignment->id)
            ->where('student_id', $student->id)
            ->with('files')
            ->first();

        return Inertia::render('Tenant/Assignments/Grading', [
            'assignment' => $offlineAssignment,
            'student' => $student,
            'submission' => $submission,
        ]);
    }

    public function storeCorrection(Request $request, OfflineAssignment $offlineAssignment, Student $student)
    {
        $this->authorize('update', $offlineAssignment); // Teacher only

        $request->validate([
            'grade' => 'required|numeric|min:0|max:100',
            'correction_file' => 'nullable|file|max:102400',
        ]);

        $submission = OfflineAssignmentSubmission::firstOrNew([
            'offline_assignment_id' => $offlineAssignment->id,
            'student_id' => $student->id,
        ]);

        $submission->grade = $request->grade;
        if (!$submission->exists) {
            $submission->submitted_at = now(); // Teacher grading marks it as submitted if not already? Or maybe leave null? Let's say submitted.
        }

        if ($request->hasFile('correction_file')) {
            $file = $request->file('correction_file');
            $path = $file->store('corrections/' . $offlineAssignment->id, 'public');
            $submission->correction_file = $path;
            $submission->correction_note = $file->getClientOriginalName();
        }

        $submission->save();

        return to_route('offline-assignments.show', $offlineAssignment->id)
            ->with('success', 'Nilai berhasil disimpan.');
    }
}
