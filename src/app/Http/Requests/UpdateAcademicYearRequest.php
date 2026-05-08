<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

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
            'name'       => "required|string|max:20|unique:academic_years,name,{$id}",
            'start_date' => 'required|date',
            'end_date'   => 'required|date|after:start_date',
        ];
    }
}
