<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class SubmitAssignmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Authz handled by role middleware + service layer
    }

    public function rules(): array
    {
        return [
            'answer_text' => ['nullable', 'string', 'max:10000', 'required_without:answer_link'],
            'answer_link' => ['nullable', 'url', 'max:2048', 'required_without:answer_text'],
        ];
    }

    public function messages(): array
    {
        return [
            'answer_text.required_without' => 'Isi jawaban atau link terlebih dahulu.',
            'answer_link.required_without' => 'Isi jawaban atau link terlebih dahulu.',
            'answer_link.url'              => 'Link harus berupa URL yang valid.',
            'answer_text.max'              => 'Jawaban maksimal 10.000 karakter.',
            'answer_link.max'              => 'Link maksimal 2.048 karakter.',
        ];
    }
}
