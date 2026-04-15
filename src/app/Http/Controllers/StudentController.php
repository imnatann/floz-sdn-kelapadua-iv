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


class StudentController extends Controller
{
    #[OA\Post(
        path: "/tenant/students/import",
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
        path: "/tenant/students/template",
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
        path: "/tenant/students",
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

        $cacheKey = 'students_' . md5(json_encode($request->only(['search', 'class_id', 'status', 'page'])));
        
        $students = cache()->remember($cacheKey, 60, function () use ($request) {
            return Student::query()
                ->with('class')
                ->when($request->search, fn($q, $s) => $q->where('name', 'like', "%{$s}%")
                    ->orWhere('nis', 'like', "%{$s}%"))
                ->when($request->class_id, fn($q, $c) => $q->where('class_id', $c))
                ->when($request->status, fn($q, $s) => $q->where('status', $s))
                ->latest()
                ->paginate(20)
                ->withQueryString();
        });

        $classes = cache()->remember('active_classes_list', 3600, function () {
            return SchoolClass::where('status', 'active')->get(['id', 'name']);
        });

        return Inertia::render('Tenant/Students/Index', [
            'students' => $students,
            'classes'  => $classes,
            'filters'  => $request->only(['search', 'class_id', 'status']),
        ]);
    }

    public function create()
    {
        \Illuminate\Support\Facades\Gate::authorize('create', Student::class);

        $classes = SchoolClass::where('status', 'active')->get(['id', 'name']);

        return Inertia::render('Tenant/Students/Create', [
            'classes' => $classes,
        ]);
    }

    #[OA\Post(
        path: "/tenant/students",
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

        // Create User Account if requested
        if ($request->create_account) {
            $email = $request->nis . '@siswa.sekolah.id';
            
            // Check if user with email already exists in TENANT database
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
        path: "/tenant/students/{student}",
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
            'healthRecord',
            'counselingNotes.counselor',
            'siblings.class'
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

        return Inertia::render('Tenant/Students/Show', [
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

        return Inertia::render('Tenant/Students/Edit', [
            'student' => $student,
            'classes' => $classes,
        ]);
    }

    #[OA\Put(
        path: "/tenant/students/{student}",
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

        $student->update($validated);

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
        path: "/tenant/students/{student}",
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
