# Catatan FLOZ — Status Triage (2026-05-09)

Triage session: ~35 min. Code read + fixes applied. 3 commits.

---

## Per-Item Status

| # | Keluhan | Status | Keterangan |
|---|---------|--------|------------|
| 1 | Admin gabisa bikin jadwal untuk kelas baru | RESOLVED | Bukan bug. Kelas baru muncul di picker Jadwal dengan counter "0 Mapel". Modal sudah menampilkan warning amber + link ke halaman Penugasan Guru jika belum ada TA. Admin harus buat Teaching Assignment dulu, baru bisa tambah jadwal. Ini by design dan UI-nya sudah menjelaskan. |
| 2 | Ulangan harian bisa lebih dari 1 | PENDING | Lihat NEXT_PHASE_FEATURES.md #2/#3. Data model sudah support (multiple `exam_type=ulangan_harian`), gap di UI. ~M effort. |
| 3 | Buat UH harusnya ada fitur seperti buat tugas | PENDING | Bundle dengan #2. Lihat NEXT_PHASE_FEATURES.md. |
| 4 | Guru harusnya bisa liat detail nilai siswa di mapel dia | PENDING | Lihat NEXT_PHASE_FEATURES.md #4. Butuh controller baru + policy scoping. ~M effort. |
| 5 | Data siswa paling bawah | RESOLVED | Halaman `/students` (index) normal — filter di atas, tabel di bawah. Halaman `/students/{id}` (show) pakai tabs: tab "Profil" aktif default, tab "Akademik" ada di posisi ke-2. Tidak ada layout bug. Yang dimaksud user kemungkinan tab Akademik tidak terlihat saat pertama buka — ini UX standard tab pattern, bukan bug. |
| 6 | Siswa/teacher/admin belum bisa ganti password | FIXED | Diimplementasi: `ProfileController` (GET/PUT `/profile/password`), halaman `Profile/ChangePassword.vue`, route terdaftar, link "Ganti Password" ditambahkan di user dropdown AppLayout. Berlaku untuk semua role (admin/teacher/student). |
| 7 | Fitur input nilai guru tidak berfungsi | PENDING | Lihat NEXT_PHASE_FEATURES.md #7. Ini L effort — redesign alur input nilai dari batch-grade ke task/exam-based entry. |
| 8 | Tanggal pertemuan (display issue) | FIXED | Bug: `AttendanceController::show` menggunakan `->distinct()` pada 3 kolom `(meeting_number, date, recorded_by)` — jika `recorded_by` berbeda untuk siswa yang sama dalam satu pertemuan, bisa muncul duplikat header kolom pertemuan di tabel absensi. Diperbaiki: ganti ke `->groupBy('meeting_number')` dengan `MIN(date)` dan `MIN(recorded_by)`, menjamin satu baris per pertemuan. |
| 9 | Ranking ga ngurut | FIXED | Bug: `ReportCardController::index` menggunakan `->latest()` (sort by `created_at DESC`), bukan by rank. Rapor ditampilkan dalam urutan dibuat, bukan urutan peringkat. Diperbaiki: ganti ke `->orderByRaw('CASE WHEN rank IS NULL THEN 1 ELSE 0 END')->orderBy('rank')->orderBy('id')` — null rank ke bawah, siswa dengan rank 1 di atas. |
| 10 | Admin bikin kelas baru → kelas baru tidak muncul di edit mata pelajaran | RESOLVED | Bukan bug. `Subjects/Form.vue` tidak punya class selector — mata pelajaran adalah entitas school-wide (bukan per-kelas). Penugasan guru-mapel-kelas diatur di halaman **Penugasan Guru** (`/teaching-assignments`), bukan di edit mata pelajaran. Kedua controller (`TeachingAssignmentController` dan `ScheduleController`) sudah query `SchoolClass::where('status','active')` dan default status kelas baru adalah `active`. Kelas baru akan muncul di dropdown Penugasan Guru segera setelah dibuat. User mungkin mencari fitur ini di tempat yang salah. |
| 11 | Setiap mapel harusnya punya guru pengampu spesifik per kelas | PENDING | Lihat NEXT_PHASE_FEATURES.md #11. Data model sudah support (TeachingAssignment = mapel+kelas+guru), gap di UI Subject edit page. ~L effort. |

---

## Fixes Summary

### Commit 1: fix(attendance): use groupBy to prevent duplicate meeting headers
- **File:** `app/Http/Controllers/AttendanceController.php`
- **Change:** Replace `distinct()` on 3 columns with `groupBy('meeting_number')` + `MIN(date)`

### Commit 2: fix(report-cards): sort index by rank ascending
- **File:** `app/Http/Controllers/ReportCardController.php`
- **Change:** Replace `latest()` with `orderByRaw(...)->orderBy('rank')`

### Commit 3: feat(profile): add password change for all users
- **Files:**
  - `app/Http/Controllers/ProfileController.php` (new)
  - `resources/js/Pages/Profile/ChangePassword.vue` (new)
  - `routes/web.php` — added GET/PUT `/profile/password`
  - `resources/js/Layouts/AppLayout.vue` — added "Ganti Password" link in user dropdown

---

## Pending Items (NEXT_PHASE_FEATURES.md)

- **#2/#3** (UH Multiple) — M effort, next sprint
- **#4** (Guru lihat nilai siswa) — M effort, next sprint
- **#7** (Input nilai redesign) — L effort, needs design discussion
- **#11** (Mapel-guru per kelas UI) — L effort, needs design discussion
