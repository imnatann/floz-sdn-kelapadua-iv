<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Student;
use App\Models\SchoolClass;
use App\Imports\StudentsImport;
use Maatwebsite\Excel\Facades\Excel;
use Illuminate\Http\Request;
use Inertia\Inertia;
use OpenApi\Attributes as OA;
use Barryvdh\DomPDF\Facade\Pdf;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use App\Services\StudentEnrollmentSync;
use App\Models\StudentMutation;


class StudentController extends Controller
{
    #[OA\Post(
        path: "/students/import",
        tags: ["Students"],
        summary: "Import Students",
        description: "Import students from Excel/CSV file"
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\MediaType(
            mediaType: "multipart/form-data",
            schema: new OA\Schema(
                properties: [
                    new OA\Property(property: "file", type: "string", format: "binary", description: "Excel/CSV file")
                ]
            )
        )
    )]
    #[OA\Response(response: 302, description: "Redirect back with success/error")]
    public function import(Request $request)
    {
        \Illuminate\Support\Facades\Gate::authorize('create', Student::class);

        $request->validate([
            'file' => 'required|mimes:xlsx,csv',
        ]);

        try {
            Excel::import(new StudentsImport, $request->file('file'));
            return back()->with('success', 'Data siswa berhasil diimport.');
        } catch (\Maatwebsite\Excel\Validators\ValidationException $e) {
             $failures = $e->failures();
             $messages = [];
             foreach ($failures as $failure) {
                 $messages[] = 'Baris ' . $failure->row() . ': ' . implode(', ', $failure->errors());
             }
             return back()->withErrors(['file' => implode('<br>', $messages)]);
        } catch (\Exception $e) {
            return back()->withErrors(['file' => 'Terjadi kesalahan: ' . $e->getMessage()]);
        }
    }

    #[OA\Get(
        path: "/students/template",
        tags: ["Students"],
        summary: "Download Import Template",
        description: "Download CSV template for student import"
    )]
    #[OA\Response(
        response: 200,
        description: "CSV Template",
        content: new OA\MediaType(
            mediaType: "text/csv",
            schema: new OA\Schema(type: "string", format: "binary")
        )
    )]
    public function downloadTemplate()
    {
        \Illuminate\Support\Facades\Gate::authorize('create', Student::class);

        $headers = ['NIS', 'NISN', 'Nama Lengkap', 'Jenis Kelamin', 'Tempat Lahir', 'Tanggal Lahir', 'Agama', 'Alamat', 'Nama Orang Tua', 'No HP Orang Tua', 'Kelas'];
        $callback = function() use ($headers) {
            $file = fopen('php://output', 'w');
            fputcsv($file, $headers);
            // Example row
            fputcsv($file, ['12345', '0012345678', 'Contoh Siswa', 'L', 'Jakarta', '2010-01-01', 'Islam', 'Jl. Contoh No. 1', 'Budi', '08123456789', '7A']);
            fclose($file);
        };
        return response()->stream($callback, 200, [
            "Content-type" => "text/csv",
            "Content-Disposition" => "attachment; filename=template_siswa.csv",
            "Pragma" => "no-cache",
        ]);
    }

    #[OA\Get(
        path: "/students",
        tags: ["Students"],
        summary: "List Students",
        description: "Get list of students with filtering"
    )]
    #[OA\Parameter(name: "search", in: "query", description: "Search by name or NIS", required: false, schema: new OA\Schema(type: "string"))]
    #[OA\Parameter(name: "class_id", in: "query", description: "Filter by class ID", required: false, schema: new OA\Schema(type: "integer"))]
    #[OA\Parameter(name: "status", in: "query", description: "Filter by status", required: false, schema: new OA\Schema(type: "string", enum: ["active", "graduated", "transferred", "dropout"]))]
    #[OA\Response(response: 200, description: "List of students")]
    public function index(Request $request)
    {
        \Illuminate\Support\Facades\Gate::authorize('viewAny', Student::class);

        // Resolve academic year filter: explicit param > active AY
        $activeAy = \App\Models\AcademicYear::where('is_active', true)->first();
        $selectedAyId = $request->integer('academic_year_id') ?: $activeAy?->id;

        $semesterId = $request->integer('semester_id') ?: null;

        // NOTE: do NOT cache the LengthAwarePaginator — it bakes absolute URLs
        // (host + scheme) from request()->url() at generation time. Reusing a
        // cached paginator from one host (e.g. ngrok) on a different origin
        // (e.g. 127.0.0.1) produces cross-origin pagination links and the
        // browser blocks the XHR with a CORS preflight redirect error.
        if ($semesterId) {
            // Historical roster: join enrollments, return all statuses
            $students = Student::query()
                ->select('students.*')
                ->selectRaw('sce.class_id as enrollment_class_id, sce.status as enrollment_status, sce.exit_date as enrollment_exit_date')
                ->join('student_class_enrollments as sce', 'sce.student_id', '=', 'students.id')
                ->where('sce.semester_id', $semesterId)
                ->with(['class.academicYear:id,name,is_active'])
                ->when($request->search, fn($q, $s) => $q->where(function ($qq) use ($s) {
                    $qq->where('students.name', 'like', "%{$s}%")
                       ->orWhere('students.nis', 'like', "%{$s}%");
                }))
                ->when($request->class_id, fn($q, $c) => $q->where('sce.class_id', $c))
                ->orderByDesc('students.id')
                ->paginate(20)
                ->withQueryString();
        } else {
            // Current view (existing behavior, unchanged)
            $students = Student::query()
                ->with('class.academicYear:id,name,is_active')
                ->when($request->search, fn($q, $s) => $q->where(function ($qq) use ($s) {
                    $qq->where('name', 'like', "%{$s}%")
                       ->orWhere('nis', 'like', "%{$s}%");
                }))
                ->when($request->class_id, fn($q, $c) => $q->where('class_id', $c))
                ->when($request->status, fn($q, $s) => $q->where('status', $s))
                ->when($selectedAyId, fn($q, $ay) => $q->whereHas('class', fn($cq) => $cq->where('academic_year_id', $ay)))
                ->latest()
                ->paginate(20)
                ->withQueryString();
        }

        // Classes filtered to selected AY (so the Kelas dropdown only shows kelas of that AY)
        $classes = SchoolClass::where('status', 'active')
            ->when($selectedAyId, fn($q, $ay) => $q->where('academic_year_id', $ay))
            ->orderBy('grade_level')
            ->orderBy('name')
            ->get(['id', 'name']);

        $academicYears = \App\Models\AcademicYear::orderByDesc('start_date')->get(['id', 'name', 'is_active']);

        $semesters = $selectedAyId
            ? \App\Models\Semester::where('academic_year_id', $selectedAyId)->orderBy('semester_number')->get(['id', 'semester_number', 'is_active'])
            : collect();

        return Inertia::render('Students/Index', [
            'students'      => $students,
            'classes'       => $classes,
            'academicYears' => $academicYears,
            'semesters'     => $semesters,
            'filters'       => array_merge(
                $request->only(['search', 'class_id', 'status']),
                ['academic_year_id' => $selectedAyId, 'semester_id' => $semesterId]
            ),
        ]);
    }

    public function create()
    {
        \Illuminate\Support\Facades\Gate::authorize('create', Student::class);

        $classes = SchoolClass::where('status', 'active')->get(['id', 'name']);

        return Inertia::render('Students/Create', [
            'classes' => $classes,
        ]);
    }

    #[OA\Post(
        path: "/students",
        tags: ["Students"],
        summary: "Create Student",
        description: "Create a new student"
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["nis", "name"],
            properties: [
                new OA\Property(property: "nis", type: "string"),
                new OA\Property(property: "nisn", type: "string"),
                new OA\Property(property: "name", type: "string"),
                new OA\Property(property: "gender", type: "string", enum: ["male", "female"]),
                new OA\Property(property: "birth_place", type: "string"),
                new OA\Property(property: "birth_date", type: "string", format: "date"),
                new OA\Property(property: "religion", type: "string"),
                new OA\Property(property: "address", type: "string"),
                new OA\Property(property: "parent_name", type: "string"),
                new OA\Property(property: "parent_phone", type: "string"),
                new OA\Property(property: "email", type: "string", format: "email"),
                new OA\Property(property: "class_id", type: "integer"),
            ]
        )
    )]
    #[OA\Response(response: 302, description: "Redirect to index")]
    public function store(Request $request)
    {
        \Illuminate\Support\Facades\Gate::authorize('create', Student::class);

        $validated = $request->validate([
            'nis'          => 'required|string|max:20|unique:students',
            'nisn'         => 'nullable|string|max:20|unique:students',
            'name'         => 'required|string|max:255',
            'gender'       => 'nullable|in:male,female',
            'birth_place'  => 'nullable|string|max:100',
            'birth_date'   => 'nullable|date',
            'religion'     => 'nullable|string|max:20',
            'address'      => 'nullable|string',
            'parent_name'  => 'nullable|string|max:255',
            'parent_phone' => 'nullable|string|max:20',
            'email'        => 'nullable|email',
            'class_id'     => 'nullable|exists:classes,id',
            'nik'          => 'nullable|string|max:20|unique:students',
            'family_card_number' => 'nullable|string|max:20',

            // Account fields
            'create_account' => 'nullable|boolean',
        ]);

        $student = Student::create($validated);

        // Phase 1 — temporal tracking: write enrollment for active semester
        app(StudentEnrollmentSync::class)->syncCurrent($student, $student->class_id);

        // Create User Account if requested
        if ($request->create_account) {
            $email = $request->nis . '@siswa.sekolah.id';
            
            $existingUser = User::where('email', $email)->first();
            
            if (!$existingUser) {
                User::create([
                    'name' => $request->name,
                    'email' => $email,
                    'password' => Hash::make('password'),
                    'role' => \App\Enums\UserRole::Student,
                ]);

                // Update student email to match
                $student->update(['email' => $email]);
            }
        }

        return redirect()->route('students.index')
            ->with('success', 'Siswa berhasil ditambahkan.');
    }

    #[OA\Get(
        path: "/students/{student}",
        tags: ["Students"],
        summary: "Show Student",
        description: "Get student details"
    )]
    #[OA\Parameter(name: "student", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 200, description: "Student details")]
    public function show(Student $student)
    {
        \Illuminate\Support\Facades\Gate::authorize('view', $student);

        $student->load([
            'class.homeroomTeacher',
            'grades.subject',
            'grades.semester.academicYear',
            'reportCards',
            'mutations.fromClass',
            'mutations.toClass',
            // 'healthRecord' + 'counselingNotes.counselor' — relations not yet implemented on Student model
            'siblings.class',
        ]);

        $academicHistory = $student->grades
            ->groupBy(fn($grade) => $grade->semester_id)
            ->map(function ($grades) {
                $semester = $grades->first()->semester;
                $name = $semester ? ($semester->academicYear->name . ' - Sem ' . $semester->semester_number) : 'Unknown';
                return [
                    'semester' => $name,
                    'average' => round($grades->avg('final_score'), 2)
                ];
            })->values();

        return Inertia::render('Students/Show', [
            'student' => $student,
            'academicHistory' => $academicHistory
        ]);
    }

    public function downloadIdCard(Student $student)
    {
        \Illuminate\Support\Facades\Gate::authorize('view', $student);

        $student->load(['class', 'healthRecord']);
        
        $pdf = Pdf::loadView('pdf.student_id_card', compact('student'));
        return $pdf->download('KARTU_PELAJAR_' . $student->nis . '.pdf');
    }


    public function edit(Student $student)
    {
        \Illuminate\Support\Facades\Gate::authorize('update', $student);

        $classes = SchoolClass::where('status', 'active')->get(['id', 'name']);

        return Inertia::render('Students/Edit', [
            'student' => $student,
            'classes' => $classes,
        ]);
    }

    #[OA\Put(
        path: "/students/{student}",
        tags: ["Students"],
        summary: "Update Student",
        description: "Update student details"
    )]
    #[OA\Parameter(name: "student", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "nis", type: "string"),
                new OA\Property(property: "name", type: "string"),
                new OA\Property(property: "status", type: "string", enum: ["active", "graduated", "transferred", "dropout"]),
            ]
        )
    )]
    #[OA\Response(response: 302, description: "Redirect to show")]
    public function update(Request $request, Student $student)
    {
        \Illuminate\Support\Facades\Gate::authorize('update', $student);

        $validated = $request->validate([
            'nis'          => "required|string|max:20|unique:students,nis,{$student->id}",
            'nisn'         => "nullable|string|max:20|unique:students,nisn,{$student->id}",
            'name'         => 'required|string|max:255',
            'gender'       => 'nullable|in:male,female',
            'birth_place'  => 'nullable|string|max:100',
            'birth_date'   => 'nullable|date',
            'religion'     => 'nullable|string|max:20',
            'address'      => 'nullable|string',
            'parent_name'  => 'nullable|string|max:255',
            'parent_phone' => 'nullable|string|max:20',
            'email'        => 'nullable|email',
            'class_id'     => 'nullable|exists:classes,id',
            'nik'          => "nullable|string|max:20|unique:students,nik,{$student->id}",
            'family_card_number' => 'nullable|string|max:20',
            'status'       => 'required|in:active,graduated,transferred,dropout',

            // Account fields
            'update_account' => 'nullable|boolean',
        ]);

        $oldClassId = $student->class_id;
        $student->update($validated);

        // Phase 1 — temporal tracking: log mutation + sync enrollment if class changed mid-semester
        if (array_key_exists('class_id', $validated) && (int) $validated['class_id'] !== (int) $oldClassId) {
            StudentMutation::create([
                'student_id'    => $student->id,
                'type'          => 'transfer_in',
                'from_class_id' => $oldClassId,
                'to_class_id'   => $student->class_id,
                'date'          => now()->toDateString(),
                'reason'        => 'Pindah kelas (mid-semester admin edit)',
            ]);
            app(StudentEnrollmentSync::class)->syncCurrent($student, $student->class_id);
        }

        // Handle Account Updates / Reset
        if ($request->update_account) {
            // Generate email from NIS (or use existing student email if we want to respect manual overrides, but requirement implies strict automation)
            // Let's stick to NIS@siswa.sekolah.id for consistency as requested
            $email = $request->nis . '@siswa.sekolah.id';

            $user = User::where('email', $email)->first();

            // If user exists, reset password
            if ($user) {
                $user->password = Hash::make('password');
                $user->name = $request->name; // Update name just in case
                $user->save();
            } 
            // If user doesn't exist, create it
            else {
                 User::create([
                    'name' => $request->name,
                    'email' => $email,
                    'password' => Hash::make('password'),
                    'role' => \App\Enums\UserRole::Student,
                ]);
            }

            // Ensure student email is synced
            if ($student->email !== $email) {
                $student->update(['email' => $email]);
            }
        }

        return redirect()->route('students.show', $student)
            ->with('success', 'Data siswa berhasil diperbarui.');
    }

    #[OA\Delete(
        path: "/students/{student}",
        tags: ["Students"],
        summary: "Delete Student",
        description: "Delete a student"
    )]
    #[OA\Parameter(name: "student", in: "path", required: true, schema: new OA\Schema(type: "integer"))]
    #[OA\Response(response: 302, description: "Redirect to index")]
    public function destroy(Student $student)
    {
        \Illuminate\Support\Facades\Gate::authorize('delete', $student);

        $student->delete();

        return redirect()->route('students.index')
            ->with('success', 'Siswa berhasil dihapus.');
    }
}
