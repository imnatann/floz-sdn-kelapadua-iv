<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreSemesterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', \App\Models\Semester::class);
    }

    public function rules(): array
    {
        $ayId = $this->route('academic_year')->id;
        return [
            'semester_number' => [
                'required',
                'integer',
                Rule::in([1, 2]),
                Rule::unique('semesters')->where('academic_year_id', $ayId),
            ],
            'start_date' => 'required|date',
            'end_date'   => 'required|date|after:start_date',
        ];
    }

    public function messages(): array
    {
        return [
            'semester_number.unique' => 'Semester ini sudah ada untuk tahun ajaran ini.',
            'semester_number.in'     => 'Semester hanya boleh bernilai 1 atau 2.',
        ];
    }
}
