# W-07: Academic Year Unique Name — Complete

**Date:** 2026-05-08
**Commit:** 7fb6899 (bundled into L-05 commit by prior session)

## Summary

Option B implemented: DB-level unique index + validation + safe pre-cleanup migration.

## Dev DB Rename Log

Duplicate group: `"2026/2027 - Ganjil"` (13 rows with ids 1-13)

| id | Old name              | New name                    |
|----|----------------------|-----------------------------|
| 1  | 2026/2027 - Ganjil   | 2026/2027 - Ganjil (unchanged — canonical) |
| 2  | 2026/2027 - Ganjil   | 2026/2027 - Ganjil (2)      |
| 3  | 2026/2027 - Ganjil   | 2026/2027 - Ganjil (3)      |
| 4  | 2026/2027 - Ganjil   | 2026/2027 - Ganjil (4)      |
| 5  | 2026/2027 - Ganjil   | 2026/2027 - Ganjil (5)      |
| 6  | 2026/2027 - Ganjil   | 2026/2027 - Ganjil (6)      |
| 7  | 2026/2027 - Ganjil   | 2026/2027 - Ganjil (7)      |
| 8  | 2026/2027 - Ganjil   | 2026/2027 - Ganjil (8)      |
| 9  | 2026/2027 - Ganjil   | 2026/2027 - Ganjil (9)      |
| 10 | 2026/2027 - Ganjil   | 2026/2027 - Ganjil (10)     |
| 11 | 2026/2027 - Ganjil   | 2026/2027 - Ganjil (11)     |
| 12 | 2026/2027 - Ganjil   | 2026/2027 - Ganjil (12)     |
| 13 | 2026/2027 - Ganjil   | 2026/2027 - Ganjil (13)     |

**Total rows renamed:** 12
**Rows preserved unchanged:** 4 (ids 1, 14, 15, 16)
**Post-migrate unique name count:** 16/16

## Files Changed

- `src/database/migrations/2026_05_08_154500_dedupe_and_unique_academic_year_name.php` — new migration
- `src/app/Http/Requests/StoreAcademicYearRequest.php` — max:20→255, array syntax
- `src/app/Http/Requests/UpdateAcademicYearRequest.php` — max:20→255, Rule::unique()->ignore()
- `src/tests/Feature/AcademicYearTest.php` — 3 new validation tests added
- `src/tests/Feature/AcademicYearDedupeTest.php` — new file, 2 migration dedup tests

## Test Results

- New tests added: 4 (3 in AcademicYearTest, 2 in AcademicYearDedupeTest; 1 was pre-existing)
- Total passing: 282 (parallel run 2)
- Flakes noted: YearTransition/ExecuteTest flakes under --parallel (pre-existing, W-01/W-02)
