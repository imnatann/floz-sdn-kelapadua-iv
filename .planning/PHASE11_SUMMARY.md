# Phase 11 — Reporting & Analytics Dashboard

**Date:** 2026-05-09
**Branch:** `chore/remove-tenant-leftovers`
**Tag:** `phase11-analytics-complete`
**Mode:** Full GSD pipeline — 3 paralel research agents → planner → plan-check → 2 paralel executors (Sonnet)

---

## Goal

Admin web dashboard with school-wide analytics: attendance trends, grade distributions, at-risk student detection, teacher workload, plus Excel export for monthly Dinas reports.

---

## Locked Decisions

| # | Decision | Source |
|---|----------|--------|
| 1 | **ApexCharts v5.11** + vue3-apexcharts (SVG-first, print-friendly) | RESEARCH_phase11_charts.md |
| 2 | **2-page split**: `/analytics` (principal dashboard) + `/analytics/reports` (admin reports + export) | Plan |
| 3 | **7 MVP widgets** — W1-W3, W8 (dashboard) + W4-W7 (reports) | RESEARCH_phase11_domain.md |
| 4 | **Excel export** — attendance recap per semester per class (1 sheet per kelas, H/S/I/A breakdown) | Domain — Dinas top-priority |
| 5 | **KKTP=70 default**, configurable via `config/floz.php` analytics block | Domain |
| 6 | **At-risk thresholds**: attendance <85% AND nilai <KKTP, both env-configurable | WARN-2 fix |
| 7 | **Auth**: school_admin only in MVP (Phase 11.5 = teacher per-class scope) | Plan |
| 8 | **DB driver portability**: 3-way `match` for week function (sqlite/pgsql/mysql) | BLOCK-1 fix |

---

## Tests Added (24)

| Layer | Count | File |
|-------|-------|------|
| Unit (AnalyticsService) | 10 | `tests/Unit/Services/AnalyticsServiceTest.php` |
| Feature (AnalyticsController) | 8 | `tests/Feature/AnalyticsTest.php` |
| Feature (Excel export) | 3 | `tests/Feature/AttendanceRecapExportTest.php` |
| Feature (migration indexes) | 3 | `tests/Feature/AnalyticsIndexesTest.php` |

Includes 3 empty-state tests for `report_cards` no-data scenarios (WARN-3 fix) and pgsql/sqlite portability assertion (BLOCK-1 fix).

---

## Test Status

| Suite | Phase 9 | Phase 11 | Delta |
|-------|---------|----------|-------|
| **Pest** | 292 (1237 assertions) | **316 (1304 assertions)** | +24 tests, +67 assertions |
| **Flutter** | 122 | 122 | unchanged |
| **Vite build** | OK (3.79s) | OK | clean |

---

## Phase 11 Commits (9)

```
a5d2f04  feat(analytics): Wave 0 — 5 indexes + config thresholds
b1271e4  test(analytics): 10 failing unit tests (TDD RED)
3771f09  feat(analytics): AnalyticsService 7 widget methods (TDD GREEN)
047226c  feat(analytics): Wave 2 — Controller, Policy, routes, permissions
9ebaca4  feat(analytics): Wave 3 — Excel export AttendanceRecapExport
d99360d  docs(analytics): Phase 11 backend summary
da6d78e  feat(web/analytics): apexcharts + vue3-apexcharts install
ac6eb56  feat(web/analytics): BaseChart + Dashboard + Reports + nav
50d548e  docs(phase11): frontend execution summary
```

---

## Plan-Check Items Closed

| ID | Issue | Resolution |
|----|-------|------------|
| BLOCK-1 | pgsql `YEARWEEK()` doesn't exist | 3-way `match($conn)` with `pgsql => TO_CHAR(date, 'IYYY-IW')` |
| BLOCK-2 | W7 (Teacher Workload) never rendered | Removed from `index()`, full sortable table in Reports.vue |
| WARN-1 | report_cards empty state silent | `meta.note` + `empty_reason: no_published_report_cards` |
| WARN-2 | 85% threshold hardcoded | `config('floz.analytics.at_risk_attendance_threshold')` |
| WARN-3 | Empty-state tests missing | 3 added: classAvgComparison/atRiskStudents/attendanceTrend |
| WARN-4 | Bundle size | ApexCharts code-split via Inertia route lazy load |

---

## Cumulative State (post Phase 7 → Phase 11)

| Phase | Description | Tests | Tag |
|-------|-------------|-------|-----|
| Phase 7 | School-year transition wizard + backend | 269 | `phase7-school-year-transition-complete` |
| Phase 7 e2e | 11 parallel Playwright scenarios | 269 | `phase7-e2e-audit-complete` |
| Phase 8 | 8 WARN + 7 LOW fixes | 282 | `phase8-warn-fixes-complete` |
| Phase 9 | Execute-path coverage | 292 | `phase9-execute-coverage-complete` |
| **Phase 11** | **Analytics dashboard** | **316** | `phase11-analytics-complete` |

---

## Ship Verdict

**SHIP** — analytics dashboard is production-ready for admin (school_admin) access. Excel export is MVP-grade.

**One real-world caveat:** Domain research strongly recommended obtaining a real Dinas Pendidikan Kabupaten Tangerang "Laporan Bulanan" template before assuming Excel format fidelity. Current export uses generic columns; admins may need format adjustment after first submission attempt.

---

## Recommended Next Phases

1. **Phase 11.5 — Dinas template fidelity** — adjust Excel export based on real template; small effort, high trust impact
2. **Phase 6 — Parent Mobile App** — original PRD candidate, builds on Phase 5 foundation
3. **Phase 12 — Teacher per-class analytics view** — `wali kelas` see only their class
4. **Phase 8.5 — Production Readiness Infra** — backup cron, monitoring, deploy automation
