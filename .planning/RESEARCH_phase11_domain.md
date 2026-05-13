# Phase 11 Domain Research — Analytics Dashboard
# SDN Kelapadua IV, Kabupaten Tangerang

> Research date: 2026-05-09 | Scope: Kepala Sekolah + Admin + Wali Kelas analytics views

---

## 1. Reporting Requirements (Dinas/Dapodik)

### Mandatory Periodic Reports (SD level, Kabupaten Tangerang)

- **Laporan Bulanan (Monthly Report)** — submitted to UPT/Dinas Pendidikan each month.
  Fields required: jumlah siswa aktif per kelas (L/P breakdown), jumlah siswa absen (hadir/sakit/izin/alpha),
  jumlah guru hadir, kondisi sarana prasarana. Format: Excel/Word, submitted physically or via SIMA/SIMBA portal.

- **Rekap Kehadiran Siswa per Semester** — aggregate of daily attendance per student per kelas per semester.
  Columns: NIS, Nama, Kelas, Hadir (hari), Sakit (hari), Izin (hari), Alpha (hari), Total Tidak Hadir, % Kehadiran.
  Used as input for: kenaikan kelas eligibility (≥85% threshold), laporan ke Dinas end-of-semester.

- **Rekap Nilai per Semester (Leger Nilai)** — one row per student, columns per mata pelajaran.
  Sub-columns: Nilai Harian (rata-rata), Nilai Tengah Semester (PTS), Nilai Akhir Semester (PAS), Nilai Akhir, Predikat.
  Submitted to Dinas as part of semester close.

- **Data Siswa Aktif (Dapodik sync)** — monthly operator obligation: keep Dapodik student counts current.
  Key fields: NIS, NISN, nama, tanggal lahir, jenis kelamin, status (aktif/pindah/lulus/putus sekolah), rombel.

- **Rapor Pendidikan (Platform Kemendikdasmen)** — annual upload of aggregate school performance indicators
  (literasi, numerasi, iklim sekolah). School operators download results from raporpendidikan.dikdasmen.go.id.
  FLOZ is not a replacement for this; the dashboard helps admins prepare the data inputs.

### Standard Excel/Format Conventions

- Attendance recap: 4-column sub-group per week or month: **H / S / I / A** (Hadir, Sakit, Izin, Alpha)
- Grade recap: columns L (Laki-laki count) and P (Perempuan count) at class summary level
- Signature block at bottom: Kepala Sekolah name + NIP + stempel sekolah (for printed versions)
- Paper size: A4 landscape for wide tables; A4 portrait for student-level detail

---

## 2. Daily Dashboard Priorities (Kepala Sekolah Morning View)

Ordered by operational urgency:

1. **Hari ini: % kehadiran seluruh sekolah** — single number, color-coded (green ≥95%, yellow 85–94%, red <85%).
   Drill-down: per kelas. If a class has no attendance recorded yet, flag it prominently ("Belum diisi").

2. **Kelas yang belum mengisi absensi hari ini** — list by class + wali kelas name. Actionable: kepala sekolah
   can immediately contact the responsible teacher.

3. **Rekap absensi minggu ini vs minggu lalu** — simple trend bar. The principal wants to see if this week is
   better or worse than last week without opening a separate report.

4. **Siswa dengan kehadiran rendah bulan ini (<80%)** — alert list. Name, kelas, % hadir. Inputs to student
   intervention before they fall below the 85% semester threshold.

5. **Progress pengisian nilai semester (% kelas sudah input nilai)** — especially relevant in the 2–3 weeks
   before rapor period. Kepala sekolah monitors teacher compliance, not individual grades.

6. **Pengumuman terbaru** — last 3 announcements, with counts of how many users have read them (if tracked).

---

## 3. Use Cases by Role

### School Admin / Operator

- **Laporan rekap bulanan siap ekspor** — generate monthly Excel per above Dinas format, prefilled from DB.
  This is the single highest-value feature; it eliminates 2–4 hours of manual Excel work per month.
- **Perbandingan performa antar kelas** — which Kelas 4 section has the highest average nilai akhir this semester?
  Bar chart, sortable, filterable by mata pelajaran.
- **Distribusi nilai per mata pelajaran per kelas** — how many A/B/C/D per subject per class. Pie or stacked bar.
- **Rekap gender per kelas** — L/P count per rombel. Used for Dinas gender-disaggregated reports.
- **Perbandingan semester Ganjil vs Genap** — did school performance improve? Line or grouped bar.
- **Status pengisian data guru** — which teachers have not yet submitted grades or attendance for the period.

### Wali Kelas (Homeroom Teacher)

- **Dashboard kelas saya** — scoped to their own rombel only. Shows:
  - Absensi kelas bulan ini (H/S/I/A breakdown)
  - Siswa dengan kehadiran < threshold
  - Rata-rata nilai per mata pelajaran untuk kelas mereka
  - Siswa dengan nilai di bawah KKM/KKTP di lebih dari 1 mata pelajaran (at-risk flag)
- **Ekspor rekap absensi kelas** — Excel for their own class, per month or per semester.
- **Perbandingan nilai siswa antar mata pelajaran** — heatmap-style: student × subject grid with color by predicate.

### Guru Mata Pelajaran

- **Distribusi nilai yang sudah diinput** — for their subjects across their assigned classes.
- **Siswa yang perlu remedial** — students below KKTP per subject they teach.
- **Workload summary** — which classes they are assigned to (read-only; set by admin).

---

## 4. Recommended Widgets

| # | Widget | Chart Type | Primary Consumer |
|---|--------|-----------|-----------------|
| W1 | Kehadiran sekolah hari ini (%) | Single stat + color badge | Kepala Sekolah |
| W2 | Kelas belum isi absensi hari ini | Alert list / table | Kepala Sekolah |
| W3 | Trend absensi mingguan (8 weeks) | Line chart, stacked area | Admin, Kepala Sekolah |
| W4 | Rekap absensi kelas (H/S/I/A) | Stacked bar per class | Admin, Wali Kelas |
| W5 | Perbandingan rata-rata nilai per kelas | Horizontal bar chart | Admin, Kepala Sekolah |
| W6 | Distribusi predikat nilai per mapel | Donut/pie (A/B/C/D) | Admin, Wali Kelas |
| W7 | Siswa at-risk (absen rendah + nilai rendah) | Sortable table + flag | Wali Kelas, Admin |
| W8 | Progress pengisian nilai guru | Progress bar per teacher/class | Admin, Kepala Sekolah |
| W9 | Gender breakdown per kelas | Stacked bar (L/P) | Admin |
| W10 | Semester comparison (Ganjil vs Genap) | Grouped bar, per class/mapel | Admin, Kepala Sekolah |
| W11 | Heatmap siswa × mapel (nilai predikat) | Color grid table | Wali Kelas |
| W12 | Teacher workload (mapel × jumlah kelas) | Simple table | Admin |

---

## 5. Export Requirements

### Must-Have (MVP)

- **Excel: Rekap Kehadiran Siswa per Kelas per Semester**
  Columns: No, NIS, Nama Siswa, [month columns with H/S/I/A sub-cols], Total H, Total S, Total I, Total A, % Hadir.
  One sheet per kelas. Auto-generated from attendance data. This eliminates the biggest manual pain point.

- **Excel: Leger Nilai (Grade Summary) per Kelas per Semester**
  Columns: No, NIS, Nama Siswa, [mapel columns with Nilai Harian / PTS / PAS / Nilai Akhir / Predikat sub-cols],
  Rata-rata, Peringkat Kelas.
  One sheet per kelas. Mirrors the existing report card data.

### Should-Have

- **PDF: Rekap absensi kelas** — printable version of above for binder archival.
- **CSV: Raw export** — all grades or all attendance for a semester, for Dinas ad-hoc requests.

### Already Covered (Out of Scope for Phase 11)

- **PDF Rapor Siswa** — individual report card PDF is handled by the existing ReportCard module.

### Excel Template Structure

Laporan Bulanan Dinas format suggested column headers:
```
Bulan: [month] | Tahun Ajaran: [year] | Kelas: [rombel]
No | NIS | Nama | [Week1: H S I A] | [Week2: H S I A] | ... | Total H | Total S | Total I | Total A | % Hadir
```
Bottom rows: Jumlah (totals), % per category, Kepala Sekolah signature block.

---

## 6. KKM / Threshold Conventions

### Grading System

| Convention | Value | Notes |
|-----------|-------|-------|
| KKM legacy (K-13) | Typically 65–75 per school decision | SDN often sets 70 or 75 |
| KKTP (Kurikulum Merdeka) | School-defined; not a single national number | Replace KKM in UI labels |
| Predikat A (Sangat Baik) | ≥ 90 | Consistent across most SD |
| Predikat B (Baik) | 80–89 | |
| Predikat C (Cukup) | 70–79 | |
| Predikat D (Perlu Bimbingan) | < 70 | Triggers remedial |
| Passing threshold for FLOZ default | 70 | Configurable per school |
| Attendance threshold for kenaikan kelas | ≥ 85% effective school days | Permendikbudristek No. 21/2022 |
| At-risk attendance flag | < 80% in-semester | Early warning before hitting 85% cutoff |

### KKTP vs KKM in UI

Under Kurikulum Merdeka, the term "KKM" is officially replaced by "KKTP" (Kriteria Ketercapaian Tujuan
Pembelajaran). FLOZ UI should use "KKTP" in labels but treat it functionally the same way: a numeric
threshold below which a student is flagged for remedial. Default: 70. Configurable per school year.

### Semester Labels

- **Semester 1 = Semester Ganjil** (~July–December)
- **Semester 2 = Semester Genap** (~January–June)
- Always display full label in reports: "Semester 1 (Ganjil) Tahun Ajaran 2025/2026"

---

## 7. Top 10 Recommended Dashboard Widgets (Prioritized)

| Priority | Widget | Rationale |
|----------|--------|-----------|
| 1 | Kehadiran sekolah hari ini + kelas belum isi | Immediate daily operational need; reduces teacher follow-up calls |
| 2 | Ekspor Excel: Rekap Absensi Semester | Eliminates biggest manual pain point; direct Dinas deliverable |
| 3 | Trend absensi mingguan per kelas (line chart) | Admins spot chronic-absence classes 3 weeks before they become critical |
| 4 | Siswa at-risk table (low attendance + low grades) | Wali kelas intervention; most requested by school operators |
| 5 | Ekspor Excel: Leger Nilai per Kelas | Second Dinas deliverable; saves 2+ hours per semester close |
| 6 | Perbandingan rata-rata nilai per kelas (bar) | Kepala sekolah monthly check; identifies underperforming classes |
| 7 | Distribusi predikat per mapel per kelas (donut) | Teacher-level feedback; wali kelas use in class meetings |
| 8 | Progress pengisian nilai guru (%) | Admin compliance monitoring; critical 2 weeks before rapor |
| 9 | Semester comparison Ganjil vs Genap (grouped bar) | Year-end analysis; used in teacher council (dewan guru) meetings |
| 10 | Heatmap siswa × mapel (predikat grid) | Power-user feature for wali kelas; nice to have, not critical path |

---

## 8. Privacy / Access Boundaries

| Role | Can See | Cannot See |
|------|---------|-----------|
| school_admin / kepala_sekolah | All classes, all students, all teachers, all exports | Nothing hidden at school level |
| wali_kelas | Only their assigned rombel (this academic year) | Other classes' student data, other teachers' grade input status |
| guru_mapel | Only their assigned subjects × classes | Other subjects' grades, other teachers' assignments |
| student | Only their own grades, attendance, report cards | Any peer data, class aggregates |
| parent | Only their linked child's data | Any peer data, class aggregates |

Access control must be enforced at the query layer (server-side scope), not just in the UI.
A wali kelas who changes the URL should not see another class's data.

---

## 9. Out of Scope for Phase 11

- **Teacher salary / payroll** — not in current data model; belongs to a future HR module.
- **Student behavioral/character assessment (Penilaian Sikap)** — qualitative data not yet captured in FLOZ.
- **Dapodik direct sync / API integration** — Dapodik has no public OAuth API for third-party apps;
  export-then-upload workflow is the realistic path. Do not build a live Dapodik connector.
- **Rapor Pendidikan (Platform Kemendikdasmen) upload** — this is a government platform; FLOZ can export
  the underlying data but cannot auto-upload to the platform.
- **Financial/BOS (Bantuan Operasional Sekolah) reporting** — entirely separate domain; not in FLOZ scope.
- **Push notifications for analytics events** — already scoped to a different phase (real-time expansion).
- **Custom report builder (drag-and-drop)** — Phase 11 delivers fixed templates only; custom builder is V2.
- **Inter-school benchmarking** — SDN Kelapadua IV is single-school deployment; no multi-school comparison.
- **Predictive / AI-generated insights** — no ML/AI inference; all analytics are direct DB aggregations.

---

## Research Sources

- [Format Laporan Bulanan SD — Dapodik.co.id](https://www.dapodik.co.id/2021/06/format-laporan-bulanan-jenjan-sekolah.html)
- [Laporan Kehadiran Siswa per Semester — KantorKita](https://www.kantorkita.co.id/laporan-kehadiran-siswa-per-kelas-semester-tahun-ajaran-2024-2025-format-lengkap-dan-mudah-diedit/)
- [Panduan Dapodik 2026 — pauddasmen.id PDF](https://obj.pauddasmen.id/dapodik/Panduan_Lengkap_Aplikasi_Dapodik_versi_2026.pdf)
- [KKTP / KKM Kurikulum Merdeka — TribunPontianak](https://pontianak.tribunnews.com/2024/12/23/2-model-penetapan-kkm-kurikulum-merdeka-ketahui-fungsi-dari-kkm-2025)
- [Kriteria Kenaikan Kelas SD — SDN 198 Mekarjaya](https://sdn198mekarjaya.sch.id/kriteria-ketuntasan-kenaikan-kelas-dan-kelulusan-sd-negeri-198-mekarjaya-tahun-2024-2025/)
- [Aplikasi Absensi Siswa Excel 2025/2026 — gurumerangkum.com](https://www.gurumerangkum.com/2025/07/aplikasi-absensi-kelas-berbasis-excel.html)
- [Dashboard Kepala Sekolah — SIDIGS](https://sidigs.com/sms)
- [Rapor Pendidikan platform — Kemendikdasmen](https://pskp.kemendikdasmen.go.id/rapor-pendidikan)
- [Permendikbudristek No. 21/2022 — standar penilaian (via Phase 7 research)]
- [Dinas Pendidikan Kabupaten Tangerang — disdik.tangerangkab.go.id](https://disdik.tangerangkab.go.id/)
