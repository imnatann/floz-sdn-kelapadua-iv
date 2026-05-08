<?php

use App\Models\AcademicYear;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\StudentMutation;
use App\Models\User;
use App\Models\YearTransitionLog;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

it('execute returns 422 without TERAPKAN confirmation word', function () {
    $admin  = User::factory()->create(['role' => 'school_admin']);
    $source = AcademicYear::factory()->create();
    $target = AcademicYear::factory()->create();

    $this->actingAs($admin)
        ->postJson(route('year-transition.execute'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
            'confirmation_word'       => 'SALAH',
        ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['confirmation_word']);
});

it('execute returns 422 with lowercase terapkan (case-sensitive)', function () {
    $admin  = User::factory()->create(['role' => 'school_admin']);
    $source = AcademicYear::factory()->create();
    $target = AcademicYear::factory()->create();

    $this->actingAs($admin)
        ->postJson(route('year-transition.execute'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
            'confirmation_word'       => 'terapkan',
        ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['confirmation_word']);
});

it('execute commits transition and returns log id', function () {
    $admin  = User::factory()->create(['role' => 'school_admin']);
    $source = AcademicYear::factory()->create(['is_active' => true]);
    $target = AcademicYear::factory()->create();

    // Source AY needs both grade-3 (students live here) AND grade-4 (promotion destination)
    // AND grade-6 (for graduation) — the classMap mirrors all source classes.
    $class3 = SchoolClass::factory()->create([
        'academic_year_id' => $source->id,
        'grade_level'      => 3,
        'name'             => 'Kelas 3A',
    ]);
    SchoolClass::factory()->create([
        'academic_year_id' => $source->id,
        'grade_level'      => 4,
        'name'             => 'Kelas 4A',
    ]); // Mirror of this becomes the promotion target for grade-3 students
    Student::factory()->count(4)->create(['class_id' => $class3->id, 'status' => 'active']);

    // W-04: call preview first to cache the hash
    $previewResponse = $this->actingAs($admin)
        ->postJson(route('year-transition.preview'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
        ])
        ->assertOk();
    $planHash = $previewResponse->json('plan_hash');

    $response = $this->actingAs($admin)
        ->postJson(route('year-transition.execute'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
            'confirmation_word'       => 'TERAPKAN',
            'plan_hash'               => $planHash,
        ])
        ->assertOk()
        ->assertJsonStructure(['log_id', 'summary']);

    expect(YearTransitionLog::count())->toBe(1);
    expect(StudentMutation::where('type', 'promotion')->count())->toBe(4);
});

it('execute returns 403 for non-admin users', function () {
    $teacher = User::factory()->create(['role' => 'teacher']);
    $source  = AcademicYear::factory()->create();
    $target  = AcademicYear::factory()->create();

    $this->actingAs($teacher)
        ->postJson(route('year-transition.execute'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
            'confirmation_word'       => 'TERAPKAN',
        ])
        ->assertForbidden();
});

it('execute rolls back and returns 500 on service exception', function () {
    $admin  = User::factory()->create(['role' => 'school_admin']);
    $source = AcademicYear::factory()->create(['is_active' => true]);
    $target = AcademicYear::factory()->create();
    $class  = SchoolClass::factory()->create([
        'academic_year_id' => $source->id,
        'grade_level'      => 5,
        'name'             => 'Kelas 5A',
    ]);
    Student::factory()->count(2)->create(['class_id' => $class->id, 'status' => 'active']);

    // W-04: call preview first (with real service) to populate cache
    $previewResponse = $this->actingAs($admin)
        ->postJson(route('year-transition.preview'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
        ])
        ->assertOk();
    $planHash = $previewResponse->json('plan_hash');

    $this->instance(
        \App\Services\YearTransitionService::class,
        \Mockery::mock(\App\Services\YearTransitionService::class, function ($mock) {
            $mock->shouldReceive('executeTransition')
                ->andThrow(new \RuntimeException('Forced failure'));
        })
    );

    $this->actingAs($admin)
        ->postJson(route('year-transition.execute'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
            'confirmation_word'       => 'TERAPKAN',
            'plan_hash'               => $planHash,
        ])
        ->assertStatus(500);

    expect(YearTransitionLog::count())->toBe(0);
});

// ── W-04: plan_hash validation ────────────────────────────────────────────────

it('execute returns 422 when plan_hash is missing', function () {
    $admin  = User::factory()->create(['role' => 'school_admin']);
    $source = AcademicYear::factory()->create(['is_active' => true]);
    $target = AcademicYear::factory()->create();
    $class  = SchoolClass::factory()->create([
        'academic_year_id' => $source->id,
        'grade_level'      => 3,
        'name'             => 'Kelas 3A',
    ]);
    SchoolClass::factory()->create([
        'academic_year_id' => $source->id,
        'grade_level'      => 4,
        'name'             => 'Kelas 4A',
    ]);
    Student::factory()->count(2)->create(['class_id' => $class->id, 'status' => 'active']);

    $this->actingAs($admin)
        ->postJson(route('year-transition.execute'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
            'confirmation_word'       => 'TERAPKAN',
            // plan_hash intentionally absent
        ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['plan_hash']);
});

it('execute with valid plan_hash (from preview) succeeds', function () {
    $admin  = User::factory()->create(['role' => 'school_admin']);
    $source = AcademicYear::factory()->create(['is_active' => true]);
    $target = AcademicYear::factory()->create();
    $class3 = SchoolClass::factory()->create([
        'academic_year_id' => $source->id,
        'grade_level'      => 3,
        'name'             => 'Kelas 3A',
    ]);
    SchoolClass::factory()->create([
        'academic_year_id' => $source->id,
        'grade_level'      => 4,
        'name'             => 'Kelas 4A',
    ]);
    Student::factory()->count(2)->create(['class_id' => $class3->id, 'status' => 'active']);

    // Call preview first to cache the hash
    $previewResponse = $this->actingAs($admin)
        ->postJson(route('year-transition.preview'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
        ])
        ->assertOk();
    $planHash = $previewResponse->json('plan_hash');

    $this->actingAs($admin)
        ->postJson(route('year-transition.execute'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
            'confirmation_word'       => 'TERAPKAN',
            'plan_hash'               => $planHash,
        ])
        ->assertOk()
        ->assertJsonStructure(['log_id', 'summary']);
});

it('execute with stale plan_hash returns 409', function () {
    $admin  = User::factory()->create(['role' => 'school_admin']);
    $source = AcademicYear::factory()->create(['is_active' => true]);
    $target = AcademicYear::factory()->create();
    $class  = SchoolClass::factory()->create([
        'academic_year_id' => $source->id,
        'grade_level'      => 3,
        'name'             => 'Kelas 3A',
    ]);
    SchoolClass::factory()->create([
        'academic_year_id' => $source->id,
        'grade_level'      => 4,
        'name'             => 'Kelas 4A',
    ]);
    Student::factory()->count(2)->create(['class_id' => $class->id, 'status' => 'active']);

    // Call preview to populate cache
    $this->actingAs($admin)
        ->postJson(route('year-transition.preview'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
        ])
        ->assertOk();

    // Submit with a garbage hash (different from cached)
    $this->actingAs($admin)
        ->postJson(route('year-transition.execute'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
            'confirmation_word'       => 'TERAPKAN',
            'plan_hash'               => str_repeat('a', 64), // garbage 64-char hex
        ])
        ->assertStatus(409)
        ->assertJsonFragment(['message' => 'Data telah berubah sejak Anda meninjau pratinjau. Silakan muat ulang dan tinjau kembali.']);
});

it('execute with expired/missing cache returns 409', function () {
    $admin  = User::factory()->create(['role' => 'school_admin']);
    $source = AcademicYear::factory()->create(['is_active' => true]);
    $target = AcademicYear::factory()->create();
    $class  = SchoolClass::factory()->create([
        'academic_year_id' => $source->id,
        'grade_level'      => 3,
        'name'             => 'Kelas 3A',
    ]);
    Student::factory()->count(2)->create(['class_id' => $class->id, 'status' => 'active']);

    // Call preview to get a real hash, then manually flush the cache
    $previewResponse = $this->actingAs($admin)
        ->postJson(route('year-transition.preview'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
        ])
        ->assertOk();
    $planHash = $previewResponse->json('plan_hash');

    // Simulate TTL expiry by flushing the cache
    \Illuminate\Support\Facades\Cache::flush();

    $this->actingAs($admin)
        ->postJson(route('year-transition.execute'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
            'confirmation_word'       => 'TERAPKAN',
            'plan_hash'               => $planHash,
        ])
        ->assertStatus(409)
        ->assertJsonFragment(['message' => 'Pratinjau telah kedaluwarsa. Silakan muat ulang dan tinjau kembali.']);
});

it('execute returns 409 when target AY already has classes (idempotency)', function () {
    $admin  = User::factory()->create(['role' => 'school_admin']);
    $source = AcademicYear::factory()->create(['is_active' => true]);
    $target = AcademicYear::factory()->create();
    $class  = SchoolClass::factory()->create([
        'academic_year_id' => $source->id,
        'grade_level'      => 4,
        'name'             => 'Kelas 4A',
    ]);
    Student::factory()->count(3)->create(['class_id' => $class->id, 'status' => 'active']);

    // W-04: call preview first to get hash, THEN pre-populate target (to simulate idempotency)
    $previewResponse = $this->actingAs($admin)
        ->postJson(route('year-transition.preview'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
        ])
        ->assertOk();
    $planHash = $previewResponse->json('plan_hash');

    // Pre-populate target AY (simulating prior execution)
    SchoolClass::factory()->create([
        'academic_year_id' => $target->id,
        'grade_level'      => 5,
        'name'             => 'Kelas 5A',
    ]);

    $this->actingAs($admin)
        ->postJson(route('year-transition.execute'), [
            'source_academic_year_id' => $source->id,
            'target_academic_year_id' => $target->id,
            'confirmation_word'       => 'TERAPKAN',
            'plan_hash'               => $planHash,
        ])
        ->assertStatus(409);
});
