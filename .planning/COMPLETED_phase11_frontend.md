# Phase 11 Frontend — Analytics Dashboard

## Status: COMPLETE (pending backend + smoke test)

## Files Created
- `src/resources/js/Components/Charts/BaseChart.vue` — SSR-safe ApexCharts wrapper
- `src/resources/js/Pages/Analytics/Dashboard.vue` — W1/W2/W3/W8 dashboard
- `src/resources/js/Pages/Analytics/Reports.vue` — W4/W5/W6/W7 reports with filter panel

## Files Modified
- `src/resources/js/Layouts/AppLayout.vue` — Added Analitik + Laporan nav entries
- `src/package.json` — Added apexcharts + vue3-apexcharts

## Tasks Completed

| Task | Description | Status | Commit |
|------|-------------|--------|--------|
| 1 | Install ApexCharts | Done | da6d78e |
| 2 | BaseChart.vue wrapper | Done | ac6eb56 |
| 3 | Dashboard.vue | Done | ac6eb56 |
| 4 | Reports.vue (incl. BLOCK-2 W7 fix) | Done | ac6eb56 |
| 5 | AppLayout.vue nav entries | Done | ac6eb56 |
| 6 | npm run build | PASS | — |
| 7 | Smoke test | PENDING (await backend) | — |

## Build Status
Clean. 1024 modules transformed. ApexCharts code-split into separate chunks (~517KB + ~533KB, lazy-loaded via defineAsyncComponent).

## BLOCK-2 W7 Fix Verification
W7 Teacher Workload table is FULLY RENDERED in Reports.vue:
- Columns: Nama Guru, Jumlah TA, Total Jam/Minggu
- Sortable by all 3 columns (click header to toggle asc/desc)
- Totals footer row showing sum of ta_count and hours_per_week
- Empty state when no data
- Loading skeleton during fetch

## API Contract Honored
- GET /analytics → Dashboard.vue props: todaysAttendance, classAvgComparison, classesMissingAttendance, topClass, atRiskClass
- GET /analytics/reports → Reports.vue props: classes, semesters, subjects, defaultFilters
- GET /analytics/data/{widget}?... → axios fetch per widget on filter change
- GET /analytics/export/attendance?... → window.location redirect for file download

## Deviations
- Used existing `chart.js`/`vue-chartjs` ecosystem was available, but installed ApexCharts as instructed
- Pagination component uses Laravel paginator `links` prop format; implemented inline pagination buttons for W6 client-side sort/paginate instead
- Task 7 smoke screenshots deferred — backend agent must complete first

## Smoke Test (when backend ready)
1. Start dev server: `cd src && php artisan serve --port=8765`
2. Login as school_admin
3. Navigate to /analytics — verify 4 widgets render
4. Navigate to /analytics/reports — change filters, verify W4-W7 reload
5. Click Export Excel — verify download
6. Save screenshots to `.planning/phase11-smoke/`
