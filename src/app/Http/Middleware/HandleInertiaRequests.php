<?php

namespace App\Http\Middleware;

use Illuminate\Http\Request;
use Inertia\Middleware;

class HandleInertiaRequests extends Middleware
{
    /**
     * The root template that is loaded on the first page visit.
     *
     * @var string
     */
    protected $rootView = 'app';

    /**
     * Determine the current asset version.
     */
    public function version(Request $request): ?string
    {
        return parent::version($request);
    }

    /**
     * Define the props that are shared by default.
     *
     * @return array<string, mixed>
     */
    public function share(Request $request): array
    {
        return [
            ...parent::share($request),
            'auth' => [
                'user' => function () use ($request) {
                    $user = $request->user();
                    if ($user) {
                        $user->load(['student:id,email', 'teacher:id,email']);
                    }
                    return $user;
                },
                'permissions' => function () use ($request) {
                    $user = $request->user();

                    if (! $user instanceof \App\Models\User) {
                        return [];
                    }

                    return [
                        'manage_students' => $user->can('create', \App\Models\Student::class),
                        'manage_teachers' => $user->can('create', \App\Models\Teacher::class),
                        'manage_grades' => $user->can('create', \App\Models\Grade::class),
                        'view_all_students' => $user->can('viewAny', \App\Models\Student::class),
                        'manage_classes' => $user->isSchoolAdmin(),
                        'manage_subjects' => $user->isSchoolAdmin(),
                        'manage_assignments' => $user->isSchoolAdmin(),
                        'manage_academic_years'     => $user->isSchoolAdmin(),
                        'manage_year_transition'    => $user->isSchoolAdmin() || $user->isSuperAdmin(),
                    ];
                },
            ],
            'school' => fn () => [
                'name'    => config('school.name'),
                'address' => config('school.address'),
                'email'   => config('school.email'),
                'phone'   => config('school.phone'),
            ],
            'flash' => [
                'message' => fn () => $request->session()->get('message'),
                'error'   => fn () => $request->session()->get('error'),
                'success' => fn () => $request->session()->get('success'),
            ],
        ];
    }
}
