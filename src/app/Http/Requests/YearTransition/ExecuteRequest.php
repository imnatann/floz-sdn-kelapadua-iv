<?php

namespace App\Http\Requests\YearTransition;

use Illuminate\Foundation\Http\FormRequest;

class ExecuteRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('manage_year_transition');
    }

    public function rules(): array
    {
        return [
            'source_academic_year_id' => 'required|integer|exists:academic_years,id',
            'target_academic_year_id' => [
                'required', 'integer', 'exists:academic_years,id',
                'different:source_academic_year_id',
            ],
            'overrides'               => 'nullable|array',
            'overrides.*.action'      => 'required|string|in:promote,graduate,retain,transfer_out,dropout',
            'overrides.*.reason'      => 'nullable|string|max:500',
            'confirmation_word'       => 'required|string|in:TERAPKAN',
            'plan_hash'               => 'required|string|size:64',
        ];
    }

    public function messages(): array
    {
        return [
            'target_academic_year_id.different' => 'Tahun ajaran tujuan harus berbeda dari tahun sumber.',
            'overrides.*.action.in'             => 'Tindakan tidak valid. Pilih: promote, graduate, retain, transfer_out, atau dropout.',
            'confirmation_word.in'              => 'Ketik "TERAPKAN" untuk mengkonfirmasi.',
        ];
    }
}
