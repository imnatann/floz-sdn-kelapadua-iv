<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\SchoolClass;
use App\Models\Teacher;
use Illuminate\Http\Request;
use Inertia\Inertia;

class TeacherController extends Controller
{
    public function index(Request $request)
    {
        \Illuminate\Support\Facades\Gate::authorize('viewAny', Teacher::class);

        $teachers = Teacher::query()
            ->when($request->search, fn($q, $s) => $q->where('name', 'like', "%{$s}%")
                ->orWhere('nip', 'like', "%{$s}%")
                ->orWhere('email', 'like', "%{$s}%"))
            ->when($request->status, fn($q, $s) => $q->where('status', $s))
            ->with('classes')
            ->latest()
            ->paginate(20)
            ->withQueryString();

        return Inertia::render('Tenant/Staff/Index', [
            'teachers' => $teachers,
            'filters'  => $request->only(['search', 'status']),
        ]);
    }

    public function create()
    {
        \Illuminate\Support\Facades\Gate::authorize('create', Teacher::class);

        return Inertia::render('Tenant/Staff/Create');
    }

    public function store(Request $request)
    {
        \Illuminate\Support\Facades\Gate::authorize('create', Teacher::class);

        $validated = $request->validate([
            'name'        => 'required|string|max:255',
            'nip'         => 'nullable|string|max:30|unique:teachers,nip',
            'nuptk'       => 'nullable|string|max:30|unique:teachers,nuptk',
            'email'       => 'nullable|email|max:255|unique:teachers,email',
            'phone'       => 'nullable|string|max:20',
            'gender'      => 'required|in:male,female',
            'birth_place' => 'nullable|string|max:100',
            'birth_date'  => 'nullable|date',
            'address'     => 'nullable|string|max:500',
            'status'      => 'required|in:active,inactive',
        ]);

        Teacher::create($validated);

        return redirect()->route('staff.index')
            ->with('success', 'Guru berhasil ditambahkan.');
    }

    public function edit(Teacher $staff)
    {
        \Illuminate\Support\Facades\Gate::authorize('update', $staff);

        return Inertia::render('Tenant/Staff/Edit', [
            'teacher' => $staff,
        ]);
    }

    public function update(Request $request, Teacher $staff)
    {
        \Illuminate\Support\Facades\Gate::authorize('update', $staff);

        $validated = $request->validate([
            'name'        => 'required|string|max:255',
            'nip'         => 'nullable|string|max:30|unique:teachers,nip,' . $staff->id,
            'nuptk'       => 'nullable|string|max:30|unique:teachers,nuptk,' . $staff->id,
            'email'       => 'nullable|email|max:255|unique:teachers,email,' . $staff->id,
            'phone'       => 'nullable|string|max:20',
            'gender'      => 'required|in:male,female',
            'birth_place' => 'nullable|string|max:100',
            'birth_date'  => 'nullable|date',
            'address'     => 'nullable|string|max:500',
            'status'      => 'required|in:active,inactive',
        ]);

        $staff->update($validated);

        return redirect()->route('staff.index')
            ->with('success', 'Data guru berhasil diperbarui.');
    }

    public function destroy(Teacher $staff)
    {
        \Illuminate\Support\Facades\Gate::authorize('delete', $staff);

        // Check if teacher is homeroom of any class
        if ($staff->classes()->count() > 0) {
            return redirect()->back()
                ->with('error', 'Guru ini masih menjadi wali kelas. Hapus terlebih dahulu penugasan wali kelas.');
        }

        $staff->delete();

        return redirect()->route('staff.index')
            ->with('success', 'Data guru berhasil dihapus.');
    }
}
