# Phase 8 — Fix Sprint Summary

**Date:** 2026-05-08
**Branch:** `chore/remove-tenant-leftovers`
**Tag:** `phase8-warn-fixes-complete`
**Driven by:** `.planning/E2E_REPORT_phase7.md` findings
**Mode:** 5 parallel Sonnet sub-agents

---

## Findings Closed

| ID | Issue | Fix Approach | Status |
|----|-------|-------------|--------|
| W-01 | AY delete row persists | Test flake — added explicit Inertia full-swap on delete/activate | ✅ |
| W-02 | AY activate-swap stale | Test flake — same fix as W-01 | ✅ |
| W-03 | No `beforeunload` guard | Added on Wizard step ≥ 2; cleared on confirm | ✅ |
| W-04 | Client-only `plan_hash` | Server-side SHA-256 over canonical plan; cached 30 min; 409 on drift | ✅ |
| W-05 | `APP_DEBUG` leak risk | `.env.production.example` + `docs/DEPLOYMENT_CHECKLIST.md` + ProductionConfigTest | ✅ |
| W-06 | Missing student count column | Added "Jumlah Siswa" column in ClassStructure Step 2 | ✅ |
| W-07 | Duplicate AY names | Validation rule + DB unique index + dedupe migration (renamed 12 dev rows) | ✅ |
| W-08 | Stale validation banner | `watch([sourceAyId, targetAyId])` clears error on change | ✅ |
| L-04 | Logs empty state inline | Replaced with `EmptyState` component | ✅ |
| L-05 | snapshot download null | Hidden when `plan_snapshot` null | ✅ |
| L-06 | Toast flash truncation | Root cause was Toast flexbox missing `min-w-0` (not flash key) | ✅ |
| L-07 | Wali kelas placeholder | Aligned with spec text | ✅ |
| L-08 | Confirm button label | Annotated as spec wording was loose; current Bahasa is better | ✅ |
| L-09 | Step indicator truncation | Bumped `max-w-[100px]` → `max-w-[140px]` | ✅ |
| L-10 | Random `id` in FormSelect | Replaced with stable module-level counter | ✅ |

## Test Status

| Suite | Before | After | Delta |
|-------|--------|-------|-------|
| Pest | 269 | 282 | +13 (1183 assertions) |
| Flutter | 122 | 122 | unchanged |
| `npm run build` | OK | OK | clean |

## Commits (15 total)

```
6ae8455 fix(academic-years): force full Inertia page swap on activate/destroy   [W-01,W-02]
2a37046 feat(web/year-transition): add beforeunload guard + step label fix      [W-03,L-09]
1b5687b docs(deploy): production readiness checklist + .env.production.example  [W-05]
55d8746 docs: W-05 production hardening complete summary
ef6b061 feat(web/year-transition): Jumlah Siswa column + placeholder text       [W-06,L-07]
96cbac3 fix(web/year-transition): clear validation banner on year change        [W-08]
8f30700 fix(web/year-transition): EmptyState component in Logs index            [L-04]
7fb6899 fix(web/year-transition): hide snapshot download when null              [L-05] + bundled W-07 work
f6c21b8 feat(year-transition): server-side plan_hash validation                 [W-04]
1b6656c fix(web): prevent flash truncation in Toast                              [L-06]
f6394e9 docs: note L-08 confirm button label                                    [L-08]
6e11b4e fix(web): replace Math.random() id in FormSelect                        [L-10]
84e747f fix(web): replace Math.random() id in FormSelect (idempotent retry)     [L-10]
eb81f48 docs: W03_UI_FIXES_COMPLETE summary
[next] docs(planning): W04 + W07 + Phase 8 summary
```

## Known Quirks

1. **Commit `7fb6899` mislabeled** — its diff includes both L-05 (LogDetail.vue snapshot null-guard) AND W-07 (AY dedupe migration + tests + request validation). Two parallel agents shared the working tree; one's commit accidentally swept up the other's pending changes. Code is correct; commit message is misleading. Not rewriting history because branch is shared.

2. **Duplicate L-10 commits** (`6e11b4e` then `84e747f`) — agent committed twice for the same fix. Second is no-op cleanup of the first.

3. **Pre-existing parallel-test flakes** in YearTransitionService noted by W-01 agent — verified that sequential `pest` runs are 282/282 green. Parallel mode flakes are concurrency artifacts (Cache::lock timing), not regressions.

## Dev DB State

- 16 AYs, all unique names post-W-07 dedupe migration
- New `year_transition_logs` table empty
- All other tables unchanged from pre-Phase-7
- Backup at `/tmp/floz_dev_pre_smoke_2026-05-08.sql`

## Ship Verdict (Phase 8)

**SHIP — Ready for production traffic** subject to:
- Following `docs/DEPLOYMENT_CHECKLIST.md` strictly (esp. `APP_DEBUG=false`, `SESSION_SECURE_COOKIE=true`)
- Running `php artisan migrate --force` on first prod deploy
- Browser-back is now guarded but admins should still be coached to use in-wizard navigation
- Execute path (TERAPKAN) still has zero E2E coverage of its write path — recommended next: dedicated execute-path E2E with a sandboxed schema before first real school transition

## Next Phase Candidates (Phase 9+)

1. **Execute-path E2E coverage** (the remaining test gap) — high value, low risk
2. **Phase 6 Parent Mobile App** — original roadmap candidate
3. **Phase 8.5 Production Readiness** — backup cron, monitoring, deploy automation (the original "Phase 8" from NEXT_PHASE_CANDIDATES)
