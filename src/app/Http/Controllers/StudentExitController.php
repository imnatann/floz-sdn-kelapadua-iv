<?php

namespace App\Http\Controllers;

use App\Models\Semester;
use App\Models\Student;
use App\Models\StudentClassEnrollment;
use App\Models\StudentMutation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;

class StudentExitController extends Controller
{
    public function store(Request $request, Student $student)
    {
        Gate::authorize('update', $student);

        $validated = $request->validate([
            'status'    => 'required|in:transferred_out,dropped_out,graduated',
            'exit_date' => 'required|date',
            'reason'    => 'nullable|string|max:500',
        ]);

        $studentStatusMap = [
            'transferred_out' => 'transferred',
            'dropped_out'     => 'dropout',
            'graduated'       => 'graduated',
        ];
        $mutationTypeMap = [
            'transferred_out' => 'transfer_out',
            'dropped_out'     => 'dropout',
            'graduated'       => 'graduated',
        ];

        DB::transaction(function () use ($student, $validated, $studentStatusMap, $mutationTypeMap) {
            $activeSem = Semester::where('is_active', true)->first();

            StudentMutation::create([
                'student_id'    => $student->id,
                'type'          => $mutationTypeMap[$validated['status']],
                'from_class_id' => $student->class_id,
                'to_class_id'   => null,
                'date'          => $validated['exit_date'],
                'reason'        => $validated['reason'] ?? null,
            ]);

            if ($activeSem) {
                StudentClassEnrollment::where('student_id', $student->id)
                    ->where('semester_id', $activeSem->id)
                    ->update([
                        'status'      => $validated['status'],
                        'exit_date'   => $validated['exit_date'],
                        'exit_reason' => $validated['reason'] ?? null,
                    ]);
            }

            $student->update(['status' => $studentStatusMap[$validated['status']]]);
        });

        return redirect()->route('students.show', $student)
            ->with('success', 'Siswa berhasil ditandai keluar.');
    }
}
