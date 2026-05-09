# Phase 12 — Teacher Per-Class Analytics Scope

**Date:** 2026-05-09
**Branch:** `chore/remove-tenant-leftovers`
**Tag:** `phase12-teacher-analytics-complete`
**Mode:** GSD pipeline — planner → 2 parallel executors (backend + frontend)

---

## Goal

Extend Phase 11 admin analytics to teachers with strict per-class scoping. Wali kelas sees their class data; regular teacher sees their teaching assignments' subjects. Teacher A cannot see Teacher B's data.

---

## Locked Decisions

| # | Decision |
|---|----------|
| 1 | Reuse `/analytics` and `/analytics/reports` routes — controller scopes data by user |
| 2 | Wali kelas: full kelas data (all subjects, all students) |
| 3 | Regular teacher: only their TeachingAssignment subjects/classes |
| 4 | Combined-role teacher: union of homeroom + TA visible class IDs |
| 5 | Admin-only widgets (`teacherWorkload`, `classesMissingAttendance`) — `AuthorizationException` if non-admin |
| 6 | Permission key split: `manage_analytics` (admin) + `view_own_class_analytics` (teacher with ≥1 visible class) |
| 7 | Authorization moves from middleware to Policy + service-level scoping |
| 8 | Excel export accepts user scope; teacher gets only their classes' sheets |

---

## Architecture: `visibleClassIds(User $user): array`

Single helper in `AnalyticsService` consumed by all 7 widget methods:

```php
private function visibleClassIds(User $user): array
{
    if ($user->isSchoolAdmin()) {
        // Active AY classes
        return SchoolClass::where('academic_year_id', $activeAY->id)->pluck('id')->all();
    }
    if (! $user->teacher) return [];  // fail closed
    
    $homeroomed = SchoolClass::where('homeroom_teacher_id', $user->teacher->id)->pluck('id');
    $taught = TeachingAssignment::where('teacher_id', $user->teacher->id)->pluck('class_id')->unique();
    return $homeroomed->merge($taught)->unique()->values()->all();
}
```

Each widget method then applies `WHERE class_id IN ($visibleClassIds)`. Default `?User $scope = null` preserves admin-test backwards compatibility.

---

## Phase 12 Commits (8)

```
561f18f  test(analytics/scope): RED scope tests for 7 widgets
3c35739  feat(analytics/scope): visibleClassIds helper + scope all widgets
5e9216e  test(analytics/scope): RED policy tests
f6b3891  feat(analytics/scope): refactor policy, permissions, routes
29ad791  feat(analytics/scope): controller passes Auth::user() to service
bf155e5  test(analytics/scope): 6 teacher isolation feature tests
27a88ac  docs(phase12): backend completion summary
1b98e33  feat(web/analytics): gate nav + widgets by role
```

---

## Test Status

| Suite | Phase 8.5 | Phase 12 | Delta |
|-------|-----------|----------|-------|
| **Pest** | 324 (~1320 assertions) | **361** (1405 assertions) | **+37 tests, +85 assertions** |
| **Flutter** | 122 | 122 | unchanged |
| **Vite build** | OK | OK | clean |

**Test categories added:**
- 22 service unit tests (scope correctness × 7 widgets)
- 9 policy unit tests (view + viewWidget)
- 6 feature isolation tests (Teacher A vs B, wali vs regular, orphan, regression)

---

## Authorization Verification

| Scenario | Outcome |
|----------|---------|
| Teacher A queries data → sees Teacher B's class | ❌ BLOCKED |
| Wali kelas accesses full class subjects | ✅ ALLOWED |
| Regular guru accesses non-TA subject | ❌ BLOCKED |
| Teacher with no homeroom + no TA | ❌ DENIED at policy (403) |
| Teacher accesses `teacherWorkload` widget | ❌ AuthorizationException |
| Teacher accesses `classesMissingAttendance` | ❌ AuthorizationException |
| Admin regression — unfiltered data | ✅ Preserved |

---

## Frontend Gating

- AppLayout nav: "Analitik" + "Laporan" visible if `manage_analytics OR view_own_class_analytics`
- Dashboard.vue: W2 (`classesMissingAttendance`) + W8 (top/at-risk class) `v-if="isAdmin"`
- Reports.vue: W7 (Teacher Workload) `v-if="isAdmin"`
- Subtitle: "Menampilkan kelas yang Anda ampu" (teacher) vs "Ringkasan seluruh sekolah" (admin)
- Excel export: visible to both, with teacher-scope subtitle

---

## Cumulative State (Phase 7 → Phase 12)

| Phase | Description | Tests | Tag |
|-------|-------------|-------|-----|
| Phase 7 | School-year transition wizard | 269 | `phase7-school-year-transition-complete` |
| Phase 7 e2e | Playwright audit | 269 | `phase7-e2e-audit-complete` |
| Phase 8 | 8 WARN + 7 LOW fixes | 282 | `phase8-warn-fixes-complete` |
| Phase 9 | Execute-path coverage | 292 | `phase9-execute-coverage-complete` |
| Phase 11 | Analytics dashboard | 316 | `phase11-analytics-complete` |
| Phase 8.5 | Production readiness infra | 324 | `phase8-5-prod-readiness-complete` |
| **Phase 12** | **Teacher analytics scope** | **361** | `phase12-teacher-analytics-complete` |

---

## Ship Verdict

**SHIP.** Teachers can now self-service their class analytics without admin involvement. Strict isolation between teachers verified by 6 dedicated isolation tests. Admin behavior unchanged (regression preserved).

---

## Recommended Next Phases

1. **Phase 11.5** — Dinas Excel template fidelity (need real sample)
2. **Phase 6** — Parent Mobile App (large user value)
3. **Phase 13** — Student self-service analytics (own grades/attendance)
4. **Phase 14** — Teacher analytics on mobile (Flutter)
5. **Phase 15** — Staging VPS deploy rehearsal
