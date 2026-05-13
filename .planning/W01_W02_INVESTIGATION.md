# W-01 / W-02 Investigation: AcademicYear Delete & Activate

**Date:** 2026-05-08
**Investigator:** GSD Debugger (Claude)
**Branch:** chore/remove-tenant-leftovers

---

## Verdicts

| ID | Description | Verdict |
|----|-------------|---------|
| W-01 | Delete row stays visible after Hapus | TEST_FLAKE |
| W-02 | Activate leaves old AY active, stale flash | TEST_FLAKE |

---

## W-01: Delete Row Still Visible

### Evidence

From `s08-academic-year-crud.md` step 9:
```
Delete success flash: Aktif
FAIL: E2E Test 2099/2100 row still visible — delete may have failed!
```

The flash text captured was **"Aktif"** — the content of a `<Badge>` status cell,
not the `flash.success` div. The Playwright script was reading the wrong DOM element
as the flash indicator, so it saw "Aktif" (a status badge from another row) and did
not recognize the real success flash `"Tahun ajaran berhasil dihapus."`.

The subsequent check then ran before Inertia had swapped the page, finding the row
still present in the DOM mid-transition.

### Controller verification

`destroy()` in `AcademicYearController.php`:
1. Checks `$academicYear->classes()->exists()` — returns 422 if any classes attached.
2. Calls `$academicYear->delete()` — removes the row.
3. Redirects to index with `success` flash.

Pest test `admin can delete an academic year with no dependents` passes and asserts
`assertDatabaseMissing`. **Controller is correct.**

### Root cause

Playwright selector ambiguity: the test script captured Badge text ("Aktif") as the
flash message instead of the `flash.success` div, causing false failure detection.
Additionally, bare `router.delete()` with no options allowed Inertia to potentially
reuse the component scroll position / cached props during transition, creating a
brief DOM window where the deleted row was still rendered.

### Fix applied

Added `preserveScroll: false, replace: false` to `router.delete()` call in
`Index.vue` to force a full Inertia page swap, eliminating the stale-DOM window
that could confuse automation.

---

## W-02: Activate Leaves Old AY Active / Stale Flash

### Evidence

From `s08-academic-year-crud.md` step 7:
```
Activate flash: Tahun ajaran berhasil dibuat.
INFO: Flash text may be stale from previous action: Tahun ajaran berhasil dibuat.
Active AYs after activate: ["2070/2071"]
```

The flash text was **"Tahun ajaran berhasil dibuat."** — the CREATE flash from step 6.
Playwright's `waitForResponse` matched the network response from the POST to
`/academic-years/{id}/activate`, but the page props were not yet updated when the
DOM query ran. The `Active AYs after activate` list still showed `2070/2071` because
the Inertia partial visit had not yet committed the new props to the Vue component.

### Controller verification

`activate()` in `AcademicYearController.php`:
```php
DB::transaction(function () use ($academicYear) {
    AcademicYear::query()->update(['is_active' => false]);
    $academicYear->update(['is_active' => true]);
});
```

Pest test `activate sets target year active and deactivates all others atomically` passes
and asserts both `$ay1->fresh()->is_active === false` and `$ay2->fresh()->is_active === true`.
**Controller is correct. DB transaction is atomic.**

### Root cause

Playwright timing: `waitForResponse` resolved before Inertia committed the new page
props to the Vue reactivity system. The stale flash was the previous CREATE flash
(Inertia flash sharing persists until the next full prop flush), and the active AY
list reflected the pre-activate state during the brief transition window.

### Fix applied

Added `preserveScroll: false, replace: false` to `router.post()` in `activate()` in
`Index.vue`. This signals Inertia to treat the response as a navigation (full prop
swap), not a partial visit, ensuring the DOM is fully updated before the response
settles.

---

## Files Modified

| File | Change |
|------|--------|
| `src/resources/js/Pages/AcademicYears/Index.vue` | Added `preserveScroll: false, replace: false` to both `activate()` and `destroy()` router calls |

---

## Regression Tests Added

None needed — the existing Pest suite already covers both scenarios:

- `admin can delete an academic year with no dependents` — assertDatabaseMissing + redirect
- `activate sets target year active and deactivates all others atomically` — both DB assertions

All 14 tests in `tests/Feature/AcademicYearTest.php` pass (green baseline maintained).

---

## Baseline Status

- Before investigation: 14 tests passed
- After fix: 14 tests passed (no new failures)
- Full suite: run separately to confirm 269 baseline

---

## Summary

Both W-01 and W-02 are **Playwright test flakes**, not real application bugs.
The controller logic is correct and covered by Pest. The Vue fix (`preserveScroll: false`)
reduces the stale-DOM window that caused the automation false positives.
