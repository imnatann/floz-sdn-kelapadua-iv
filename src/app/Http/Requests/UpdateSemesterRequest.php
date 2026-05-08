<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateSemesterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('semester'));
    }

    public function rules(): array
    {
        $sem = $this->route('semester');
        return [
            'semester_number' => [
                'required',
                'integer',
                Rule::in([1, 2]),
                Rule::unique('semesters')
                    ->where('academic_year_id', $sem->academic_year_id)
                    ->ignore($sem->id),
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
