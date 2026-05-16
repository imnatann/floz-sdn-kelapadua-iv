<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreAcademicYearRequest;
use App\Http\Requests\UpdateAcademicYearRequest;
use App\Models\AcademicYear;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;
use Inertia\Response;

class AcademicYearController extends Controller
{
    public function __construct()
    {
        $this->authorizeResource(AcademicYear::class, 'academic_year');
    }

    public function index(): Response
    {
        $academicYears = AcademicYear::withCount('semesters')
            ->orderByDesc('start_date')
            ->paginate(20);

        return Inertia::render('AcademicYears/Index', [
            'academicYears' => $academicYears,
        ]);
    }

    public function create(): Response
    {
        return Inertia::render('AcademicYears/Form');
    }

    public function store(StoreAcademicYearRequest $request): RedirectResponse
    {
        AcademicYear::create($request->validated());

        return redirect()->route('academic-years.index')
            ->with('success', 'Tahun ajaran berhasil dibuat.');
    }

    public function edit(AcademicYear $academicYear): Response
    {
        return Inertia::render('AcademicYears/Form', [
            'academicYear' => $academicYear,
        ]);
    }

    public function update(UpdateAcademicYearRequest $request, AcademicYear $academicYear): RedirectResponse
    {
        $academicYear->update($request->validated());

        return redirect()->route('academic-years.index')
            ->with('success', 'Tahun ajaran berhasil diperbarui.');
    }

    public function destroy(AcademicYear $academicYear): RedirectResponse
    {
        $this->authorize('delete', $academicYear);

        // Guard: proactively check FK dependents before attempting delete
        // (classes use onDelete cascade — we must prevent accidental cascade deletion)
        if ($academicYear->classes()->exists()) {
            return back()->withErrors([
                'message' => 'Tahun ajaran tidak bisa dihapus karena masih memiliki data kelas.',
            ])->setStatusCode(422);
        }

        $academicYear->delete();

        return redirect()->route('academic-years.index')
            ->with('success', 'Tahun ajaran berhasil dihapus.');
    }

    public function activate(AcademicYear $academicYear): RedirectResponse
    {
        $this->authorize('activate', $academicYear);

        DB::transaction(function () use ($academicYear) {
            AcademicYear::query()->update(['is_active' => false]);
            $academicYear->update(['is_active' => true]);
        });

        return redirect()->route('academic-years.index')
            ->with('success', "Tahun ajaran {$academicYear->name} sekarang aktif.");
    }
}
