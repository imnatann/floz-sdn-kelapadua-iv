<?php

namespace App\Http\Requests\Api\V1\Attendance;

use Illuminate\Foundation\Http\FormRequest;

class StoreAttendanceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Authz handled by Policy in controller
    }

    public function rules(): array
    {
        return [
            'entries' => ['required', 'array', 'min:1'],
            'entries.*.student_id' => ['required', 'integer', 'exists:students,id'],
            'entries.*.status' => ['required', 'string', 'in:hadir,sakit,izin,alpha'],
            'entries.*.note' => ['nullable', 'string', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'entries.required' => 'Data absensi wajib diisi.',
            'entries.*.student_id.required' => 'ID siswa wajib diisi.',
            'entries.*.student_id.exists' => 'Siswa tidak ditemukan.',
            'entries.*.status.required' => 'Status kehadiran wajib diisi.',
            'entries.*.status.in' => 'Status harus salah satu dari: hadir, sakit, izin, alpha.',
        ];
    }
}
