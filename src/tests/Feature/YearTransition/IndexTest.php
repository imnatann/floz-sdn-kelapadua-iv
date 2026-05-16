<?php

use App\Models\AcademicYear;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('preselects target academic year from query string', function () {
    $admin = User::factory()->schoolAdmin()->create();
    $target = AcademicYear::factory()->create();

    $this->actingAs($admin)
        ->get(route('year-transition.index', ['target_academic_year_id' => $target->id]))
        ->assertOk()
        ->assertInertia(fn ($page) => $page
            ->component('YearTransition/Wizard')
            ->where('initialTargetAcademicYearId', $target->id)
        );
});
