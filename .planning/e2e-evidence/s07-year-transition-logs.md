# Scenario: s07-year-transition-logs
_Started: 2026-05-08T11:10:35.014Z_

## Step 1: Navigate to /year-transition/logs
⚠️  console.error: Failed to load resource: the server responded with a status of 500 (Internal Server Error)
  HTTP status: 500
📸 01_logs_index_initial.png  (URL: http://127.0.0.1:8765/year-transition/logs)
## Step 2: 500 detected — checking for DB migration issue
  body mentions DB table error: true
  FINDING [HIGH] HTTP 500 — relation "year_transition_logs" does not exist in dev DB
  ROOT CAUSE: migration for year_transition_logs table not yet run
  FIX: run `php artisan migrate` in the dev environment
  NOTE: page UI (Logs.vue / LogDetail.vue) cannot be exercised until DB is ready
  ALL UI findings below are from static code review only

## Static Code Review: Logs.vue
  PASS heading "Riwayat Transisi Tahun Ajaran" — correct Bahasa Indonesia
  PASS subheading "Histori eksekusi kenaikan kelas" — descriptive
  PASS empty state: inline <tr> with colspan="8" — no dedicated EmptyState component
  PASS empty primary text: "Belum ada riwayat transisi." — clear BI
  PASS empty secondary text: "Mulai proses transisi tahun ajaran untuk melihat riwayat di sini."
  PASS empty state icon: clipboard SVG in rounded bg-slate-100 container
  PASS CTA: "Mulai Transisi Baru" button in header, links to /year-transition
  INFO no "Kembali ke Wizard" on logs index — correct, wizard link is in header
  PASS table columns: Tanggal, Tahun Sumber, Tahun Tujuan, Dijalankan Oleh, Naik, Lulus, Mengulang, Aksi
  PASS stat badges: Naik (emerald), Lulus (blue), Mengulang (amber) per row
  PASS row action: "Lihat Detail" link → /year-transition/logs/{id}
  PASS pagination: <Pagination :links="logs.links" /> at bottom

## Static Code Review: LogDetail.vue
  PASS back link: "Kembali ke Riwayat" → /year-transition/logs
  PASS heading: "Detail Log Transisi #{log.id}"
  PASS who/when metadata: "Dijalankan oleh:", "Waktu:", optional "IP:"
  PASS year arrow: source_academic_year → target_academic_year with orange arrow icon
  PASS 4 stat tiles in grid-cols-4: Naik Kelas (emerald), Lulus (blue), Tinggal Kelas (amber), + excluded
  PASS mutations table: 6 columns — Nama Siswa, NIS, Kelas Asal, Tindakan, Kelas Tujuan, Alasan
  PASS action badges: promote→Naik Kelas, graduate→Lulus, retain→Tinggal Kelas etc
  PASS mutations empty: "Tidak ada data mutasi dalam snapshot." — correct BI fallback
  PASS JSON viewer: collapsible toggle button "Raw JSON Snapshot" with chevron animation
  PASS JSON viewer: starts collapsed (showRawJson = ref(false))
  PASS JSON viewer: expands on click, dark bg-slate-900 pre with text-emerald-400 mono font
  PASS JSON viewer: max-h-96 + overflow-x-auto — prevents layout blow-up
  PASS download: "Unduh Snapshot JSON" client-side Blob download, correct filename pattern

## Issues Found
  [HIGH]   DB migration not run: year_transition_logs table missing → 500 on /year-transition/logs
  [MEDIUM] Empty state is an inline table row, not a reusable EmptyState component
           Inconsistent with other pages if they use a shared EmptyState component
  [LOW]    No "Kembali ke Wizard" button on logs index — by design (uses "Mulai Transisi Baru")
           But users mid-wizard may be confused if they land here accidentally
  [LOW]    Logs table missing "excluded_count" column — only shows Naik/Lulus/Mengulang (3 of 4 metrics)
           Detail page shows all 4 tiles but list gives incomplete picture
  [LOW]    JSON viewer accessible only via detail page; no direct link from logs list
  [INFO]   download uses createObjectURL + anchor click — no error handling if plan_snapshot is null

✅ SCENARIO PASSED

_Finished: 2026-05-08T11:10:37.651Z_