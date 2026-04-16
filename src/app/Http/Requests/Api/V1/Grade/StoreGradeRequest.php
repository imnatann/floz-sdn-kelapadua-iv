<?php

namespace App\Http\Requests\Api\V1\Grade;

use Illuminate\Foundation\Http\FormRequest;

class StoreGradeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'entries' => ['required', 'array', 'min:1'],
            'entries.*.student_id' => ['required', 'integer', 'exists:students,id'],
            'entries.*.daily_test_avg' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'entries.*.mid_test' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'entries.*.final_test' => ['nullable', 'numeric', 'min:0', 'max:100'],
        ];
    }

    public function messages(): array
    {
        return [
            'entries.required' => 'Data nilai wajib diisi.',
            'entries.*.student_id.required' => 'ID siswa wajib diisi.',
            'entries.*.student_id.exists' => 'Siswa tidak ditemukan.',
            'entries.*.daily_test_avg.max' => 'Nilai harian maksimal 100.',
            'entries.*.mid_test.max' => 'Nilai UTS maksimal 100.',
            'entries.*.final_test.max' => 'Nilai UAS maksimal 100.',
        ];
    }
}
