<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * W-07: Enforce unique academic_year names.
 *
 * Strategy (Option B):
 *   1. Rename duplicate names by appending " (2)", " (3)", … to every row
 *      EXCEPT the one with the smallest id (which keeps the canonical name).
 *   2. Add a unique index on academic_years.name.
 *
 * Idempotent: the SELECT only touches rows whose current name already matches
 * another row, so a second run is a no-op once all names are unique.
 *
 * down() drops the unique index but does NOT attempt to restore original names
 * (lossy rename — rows remain with their new suffixed names).
 */
return new class extends Migration
{
    public function up(): void
    {
        // Step 1: deduplicate names row-by-row.
        $dupes = DB::select("
            SELECT name
            FROM   academic_years
            GROUP  BY name
            HAVING COUNT(*) > 1
        ");

        foreach ($dupes as $dupe) {
            // Fetch all rows with this name ordered by id ascending.
            // The smallest id keeps the canonical name; the rest get suffixes.
            $rows = DB::select(
                'SELECT id FROM academic_years WHERE name = ? ORDER BY id ASC',
                [$dupe->name]
            );

            // Skip the first (canonical) row; rename the rest.
            $suffix = 2;
            foreach (array_slice($rows, 1) as $row) {
                $newName = $dupe->name . ' (' . $suffix . ')';
                DB::update(
                    'UPDATE academic_years SET name = ? WHERE id = ?',
                    [$newName, $row->id]
                );
                $suffix++;
            }
        }

        // Step 2: add unique index (will succeed now that names are unique).
        Schema::table('academic_years', function (Blueprint $table) {
            $table->unique('name', 'academic_years_name_unique');
        });
    }

    public function down(): void
    {
        Schema::table('academic_years', function (Blueprint $table) {
            $table->dropUnique('academic_years_name_unique');
        });
        // Renamed rows are NOT restored — names remain suffixed.
    }
};
