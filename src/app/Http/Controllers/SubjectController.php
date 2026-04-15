<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Subject;
use Illuminate\Http\Request;
use Inertia\Inertia;

class SubjectController extends Controller
{
    public function index(Request $request)
    {
        $subjects = Subject::query()
            ->when($request->search, fn($q, $s) => $q->where('name', 'like', "%{$s}%")
                ->orWhere('code', 'like', "%{$s}%"))
            ->when($request->category, fn($q, $c) => $q->where('category', $c))
            ->when($request->status, fn($q, $s) => $q->where('status', $s))
            ->orderBy('code')
            ->paginate(20)
            ->withQueryString();

        return Inertia::render('Tenant/Subjects/Index', [
            'subjects' => $subjects,
            'filters'  => $request->only(['search', 'category', 'status']),
        ]);
    }

    public function create()
    {
        return Inertia::render('Tenant/Subjects/Form');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'code'            => 'required|string|max:20|unique:subjects,code',
            'name'            => 'required|string|max:255',
            'education_level' => 'required|in:SD,SMP,SMA',
            'grade_level'     => 'nullable|integer|min:1|max:12',
            'kkm'             => 'required|numeric|min:0|max:100',
            'category'        => 'nullable|in:general,religion,specialty',
            'description'     => 'nullable|string|max:500',
            'status'          => 'required|in:active,inactive',
        ]);

        Subject::create($validated);

        return redirect()->route('subjects.index')
            ->with('success', 'Mata pelajaran berhasil ditambahkan.');
    }

    public function edit(Subject $subject)
    {
        return Inertia::render('Tenant/Subjects/Form', [
            'subject' => $subject,
        ]);
    }

    public function update(Request $request, Subject $subject)
    {
        $validated = $request->validate([
            'code'            => 'required|string|max:20|unique:subjects,code,' . $subject->id,
            'name'            => 'required|string|max:255',
            'education_level' => 'required|in:SD,SMP,SMA',
            'grade_level'     => 'nullable|integer|min:1|max:12',
            'kkm'             => 'required|numeric|min:0|max:100',
            'category'        => 'nullable|in:general,religion,specialty',
            'description'     => 'nullable|string|max:500',
            'status'          => 'required|in:active,inactive',
        ]);

        $subject->update($validated);

        return redirect()->route('subjects.index')
            ->with('success', 'Data mata pelajaran berhasil diperbarui.');
    }

    public function destroy(Subject $subject)
    {
        if ($subject->grades()->count() > 0) {
            return redirect()->back()
                ->with('error', 'Mata pelajaran masih memiliki data nilai. Hapus data nilai terlebih dahulu.');
        }

        $subject->delete();

        return redirect()->route('subjects.index')
            ->with('success', 'Mata pelajaran berhasil dihapus.');
    }
}
