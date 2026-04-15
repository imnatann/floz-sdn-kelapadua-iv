<?php

namespace App\Http\Resources\Api\V1;

use App\Enums\UserRole;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $data = [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'role' => $this->role->value,
            'avatar_url' => $this->avatar_url ?? null,
            'is_active' => (bool) $this->is_active,
        ];

        if ($this->role === UserRole::Student && $this->student) {
            $student = $this->student;
            $data['student'] = [
                'id' => $student->id,
                'nis' => $student->nis,
                'nisn' => $student->nisn,
                'class' => $student->class ? [
                    'id' => $student->class->id,
                    'name' => $student->class->name,
                    'homeroom_teacher' => optional($student->class->homeroomTeacher)->name,
                ] : null,
            ];
        }

        if ($this->role === UserRole::Teacher && $this->teacher) {
            $data['teacher'] = [
                'id' => $this->teacher->id,
                'nip' => $this->teacher->nip ?? null,
                'name' => $this->teacher->name,
            ];
        }

        return $data;
    }
}
