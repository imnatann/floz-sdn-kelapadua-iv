<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreSemesterRequest;
use App\Http\Requests\UpdateSemesterRequest;
use App\Models\AcademicYear;
use App\Models\Semester;
use App\Services\EnrollmentCarryOverService;
use Illuminate\Database\QueryException;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;
use Inertia\Response;

class SemesterController extends Controller
{
    public function index(AcademicYear $academicYear): Response
    {
        $this->authorize('viewAny', Semester::class);

        return Inertia::render('Semesters/Index', [
            'academicYear' => $academicYear,
            'semesters'    => $academicYear->semesters()->orderBy('semester_number')->get(),
        ]);
    }

    public function create(AcademicYear $academicYear): Response
    {
        $this->authorize('create', Semester::class);

        return Inertia::render('Semesters/Form', [
            'academicYear' => $academicYear,
        ]);
    }

    public function store(StoreSemesterRequest $request, AcademicYear $academicYear): RedirectResponse
    {
        $academicYear->semesters()->create($request->validated());

        return redirect()->route('academic-years.semesters.index', $academicYear)
            ->with('success', 'Semester berhasil dibuat.');
    }

    public function edit(Semester $semester): Response
    {
        $this->authorize('update', $semester);

        return Inertia::render('Semesters/Form', [
            'academicYear' => $semester->academicYear,
            'semester'     => $semester,
        ]);
    }

    public function update(UpdateSemesterRequest $request, Semester $semester): RedirectResponse
    {
        $semester->update($request->validated());

        return redirect()->route('academic-years.semesters.index', $semester->academic_year_id)
            ->with('success', 'Semester berhasil diperbarui.');
    }

    public function destroy(Semester $semester): RedirectResponse
    {
        $this->authorize('delete', $semester);
        $ayId = $semester->academic_year_id;

        // Guard: check FK dependents proactively
        if ($semester->grades()->exists() || $semester->reportCards()->exists()) {
            return back()->withErrors([
                'message' => 'Semester tidak bisa dihapus karena masih memiliki data nilai atau rapor.',
            ])->setStatusCode(422);
        }

        $semester->delete();

        return redirect()->route('academic-years.semesters.index', $ayId)
            ->with('success', 'Semester berhasil dihapus.');
    }

    public function activate(Semester $semester): RedirectResponse
    {
        $this->authorize('activate', $semester);

        $result = DB::transaction(function () use ($semester) {
            // Single active semester globally (Phase 2 Bug D)
            Semester::where('is_active', true)->update(['is_active' => false]);
            $semester->update(['is_active' => true]);

            return app(EnrollmentCarryOverService::class)->execute($semester->id);
        });

        $msg = "Semester {$semester->semester_number} sekarang aktif.";
        if ($result['carried'] > 0) {
            $msg .= " {$result['carried']} siswa di-carry-over dari semester sebelumnya.";
        }
        if ($result['skipped'] > 0) {
            $msg .= " {$result['skipped']} siswa di-skip (sudah keluar/lulus).";
        }

        return redirect()->route('academic-years.semesters.index', $semester->academic_year_id)
            ->with('success', $msg);
    }

    public function carryOverPreview(Semester $semester)
    {
        $this->authorize('activate', $semester);
        return response()->json(
            app(EnrollmentCarryOverService::class)->preview($semester->id)
        );
    }
}
