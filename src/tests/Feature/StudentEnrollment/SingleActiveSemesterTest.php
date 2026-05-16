<?php

use App\Models\AcademicYear;
use App\Models\Semester;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('activating a semester deactivates the globally-active semester in any other AY', function () {
    $admin = User::create(['name' => 'Admin', 'email' => 'admin@test', 'password' => 'x', 'role' => 'school_admin', 'is_active' => true]);
    $ay1 = AcademicYear::create(['name' => '2025/2026', 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2026-06-30']);
    $ay2 = AcademicYear::create(['name' => '2026/2027', 'is_active' => false, 'start_date' => '2026-07-01', 'end_date' => '2027-06-30']);

    $semA = Semester::create(['academic_year_id' => $ay1->id, 'semester_number' => 1, 'is_active' => true, 'start_date' => '2025-07-01', 'end_date' => '2025-12-31']);
    $semB = Semester::create(['academic_year_id' => $ay2->id, 'semester_number' => 1, 'is_active' => false, 'start_date' => '2026-07-01', 'end_date' => '2026-12-31']);

    $this->actingAs($admin)->post("/semesters/{$semB->id}/activate")->assertRedirect();

    expect(Semester::find($semA->id)->is_active)->toBeFalse();
    expect(Semester::find($semB->id)->is_active)->toBeTrue();
    expect(Semester::where('is_active', true)->count())->toBe(1);
});
