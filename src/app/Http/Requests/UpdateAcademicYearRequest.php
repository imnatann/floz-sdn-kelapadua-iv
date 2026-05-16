<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateAcademicYearRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('academic_year'));
    }

    public function rules(): array
    {
        $id = $this->route('academic_year')->id;
        return [
            'name'       => [
                'required',
                'string',
                'max:255',
                Rule::unique('academic_years', 'name')->ignore($id),
            ],
            'start_date' => 'required|date',
            'end_date'   => 'required|date|after:start_date',
        ];
    }
}
