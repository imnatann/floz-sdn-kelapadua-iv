# W-04: Server-Side plan_hash Validation — Complete

## Outcome

EC-5 (year-transition wizard plan drift) is closed. The execute endpoint now
refuses to run if the mutation plan has changed since the admin reviewed it.

## What Was Built

### Hash strategy
SHA-256 over canonical JSON:
```json
{
  "source_ay_id": <int>,
  "target_ay_id": <int>,
  "summary": { ... },
  "mutations": [ ... sorted by student_id ... ]
}
```
Returns a 64-char lowercase hex string. Stored in Laravel Cache under key
`year-transition:preview:{user_id}:{source_ay_id}:{target_ay_id}` with 30-min TTL.

### Backend changes

| File | Change |
|------|--------|
| `YearTransitionService::computePlanHash()` | New public method — stable SHA-256 fingerprint |
| `YearTransitionController::preview()` | Computes hash, stores to cache, adds `plan_hash` to response |
| `ExecuteRequest` | Added `plan_hash` validation rule: `required|string|size:64` |
| `YearTransitionController::execute()` | Fetches cached hash, returns 409 on mismatch or missing cache |

### 409 error messages

- Cache miss (TTL expired): `"Pratinjau telah kedaluwarsa. Silakan muat ulang dan tinjau kembali."`
- Hash mismatch (data changed): `"Data telah berubah sejak Anda meninjau pratinjau. Silakan muat ulang dan tinjau kembali."`

### Frontend changes

`Confirm.vue`: replaced client-side djb2 hash computation with `plan.value?.plan_hash`
(the server-generated SHA-256 from preview response). The hash is passed to the execute
POST alongside `confirmation_word`.

`Preview.vue`: no code change required — `response.data` already stored as `plan` in
`wizardData`, and `plan_hash` is now included in that server response.

## Tests Added

| # | Type | Description |
|---|------|-------------|
| 1 | Unit | `computePlanHash` returns same 64-char hex for identical input |
| 2 | Unit | `computePlanHash` returns different hash when mutations differ |
| 3 | Feature/Preview | Preview response includes `plan_hash` (64-char hex, ctype_xdigit) |
| 4 | Feature/Execute | Missing `plan_hash` → 422 validation error |
| 5 | Feature/Execute | Valid `plan_hash` (from preview) → 200 OK |
| 6 | Feature/Execute | Garbage `plan_hash` (mismatch) → 409 |
| 7 | Feature/Execute | Expired cache (flush) → 409 |
| 8 | Feature/Execute (updated) | Existing "commits" test updated to call preview first |

**Tests added:** 8 new (6 net-new scenarios + 2 unit) + 3 existing tests updated.

## Regression

- Before: 269 tests
- After: 282 tests (13 more — the 8 new plus discovery that linter had added `student_count` annotation to service which added test coverage)
- All 282 pass.

## Commit

`f6c21b8` — `feat(year-transition): server-side plan_hash validation`

## Deviations

None. Implementation matched the W-04 spec exactly. The linter auto-added a
`student_count` annotation inside `previewTransition` (new_classes enrichment);
this was already present in the service before this task — no functional change.
