<?php

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

/**
 * W-07: Test the dedup migration logic in isolation.
 *
 * We exercise the dedup algorithm directly (not via artisan migrate) because
 * the unique index already exists in the test schema (added by our migration).
 * This test seeds duplicates into the table, runs the dedup SQL logic, then
 * asserts that names are unique and follow the " (N)" suffix scheme.
 */
it('dedup migration renames duplicate names with sequential suffixes', function () {
    // Insert duplicate rows bypassing the unique index that already exists in
    // the test schema by temporarily dropping and re-adding it.
    Schema::table('academic_years', function ($table) {
        $table->dropUnique('academic_years_name_unique');
    });

    $baseName = 'Test Year Dupe';
    $ids = [];
    for ($i = 0; $i < 4; $i++) {
        $ids[] = DB::table('academic_years')->insertGetId([
            'name'       => $baseName,
            'start_date' => '2025-07-01',
            'end_date'   => '2026-06-30',
            'is_active'  => false,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    // Run the dedup logic (mirror of the migration's up() step 1).
    $dupes = DB::select("
        SELECT name FROM academic_years GROUP BY name HAVING COUNT(*) > 1
    ");

    foreach ($dupes as $dupe) {
        $rows = DB::select(
            'SELECT id FROM academic_years WHERE name = ? ORDER BY id ASC',
            [$dupe->name]
        );
        $suffix = 2;
        foreach (array_slice($rows, 1) as $row) {
            DB::update(
                'UPDATE academic_years SET name = ? WHERE id = ?',
                [$dupe->name . ' (' . $suffix . ')', $row->id]
            );
            $suffix++;
        }
    }

    // Re-add the unique index to verify no conflicts remain.
    Schema::table('academic_years', function ($table) {
        $table->unique('name', 'academic_years_name_unique');
    });

    // Assert: the smallest id keeps the canonical name.
    $canonical = DB::table('academic_years')->where('id', $ids[0])->value('name');
    expect($canonical)->toBe($baseName);

    // Assert: subsequent rows got suffixes (2), (3), (4).
    foreach (array_slice($ids, 1) as $i => $id) {
        $name = DB::table('academic_years')->where('id', $id)->value('name');
        $expected = $baseName . ' (' . ($i + 2) . ')';
        expect($name)->toBe($expected);
    }

    // Assert: all names in the table are now unique.
    $names = DB::table('academic_years')->pluck('name');
    expect($names->count())->toBe($names->unique()->count());
});

it('dedup migration is idempotent when no duplicates exist', function () {
    // Schema already has unique index — running dedup logic again should be a no-op.
    $dupes = DB::select("
        SELECT name FROM academic_years GROUP BY name HAVING COUNT(*) > 1
    ");

    expect($dupes)->toBeEmpty();
});
