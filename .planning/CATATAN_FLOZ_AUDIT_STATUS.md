# Catatan FLOZ — Audit Round 2 Status (2026-05-12)

Session: ~35 min. 3 commits. Baseline 361 tests — regression: 0.

---

## Per-Item Status

| # | Keluhan | Status | Keterangan |
|---|---------|--------|------------|
| A1 | Jadwal tidak bisa diedit/dihapus | FIXED (partial) | `ScheduleController::update` + `PUT /schedules/{schedule}` route added (commit `6534893`). Backend done. Vue `Schedules/Index.vue` belum ditambah form edit — UI gap, tapi backend sudah siap. |
| A2 | Reset password ambiguity | CLARIFIED | Commit `14bbd54` sudah implement self-change password untuk semua role. Jika auditor maksud **admin-reset-password-for-other-user**: belum ada. Rekomendasi: tambah `POST /admin/users/{id}/reset-password` + tombol di halaman manajemen user. Scope: ~S effort. |
| A3 | Wali kelas tidak boleh ubah nilai mapel yang dia tidak ajar | FIXED | `GradeController::storeBatch` kini checks TA `(teacher_id, class_id, subject_id)` setelah `Gate::authorize('create')`. Commit `7df40c9`. `GradePolicy::update` sudah benar sebelumnya. |
| A4 | Guru random bisa CRUD tugas/ulangan mapel orang lain | FIXED | `TaskController` + `ExamController`: `authorizeManage()` dipanggil di `store`, `storeScores`, `destroy` — wajib punya TA untuk class+subject tersebut. Commit `7df40c9`. |
| A5 | Siswa bisa input nilai | FIXED | Tertutup oleh fix A4: `authorizeManage()` hanya allow admin + teacher dengan TA. Student (tidak `isTeacher()`) dapat 403. `GradePolicy::create` juga sudah block student sebelumnya. Commit `7df40c9`. |
| A6 | Absensi per mapel/pertemuan (mobile flow) | PLAN ONLY | Arsitektural. Backend mobile sudah per-TA/Meeting. Web flow saat ini per-class (daily). Perubahan butuh: (1) model Meeting ter-link ke TeachingAssignment juga untuk web, (2) UI Create/Edit Attendance pilih TA dulu, (3) migrasi data lama. Estimasi L effort, ~1 sprint. |
| A7 | Excel export format match auditor | PLAN ONLY | Export `/analytics/export/attendance` sudah ada tapi format kolom kemungkinan tidak match. Butuh: compare image1.jpeg auditor dengan output sekarang → buat `AttendanceRecapExport` baru dengan format spesifik. Estimasi M effort. |
| A8 | Web attendance hanya wali kelas | FIXED | `AttendanceController::create/store/edit/update` sekarang memanggil `authorizeHomeroomOrAdmin()` — cek `homeroom_teacher_id === teacher->id`. Non-homeroom teacher + student → 403. Commit `407947a`. |

---

## Commits

| Hash | Description |
|------|-------------|
| `7df40c9` | fix(auth/tasks-exams): enforce TA ownership before create/score/delete (A3, A4, A5) |
| `407947a` | fix(auth/attendance): restrict web attendance input to wali kelas only (A8) |
| `6534893` | feat(schedules): add update route and controller method (A1 backend) |

---

## Next Phase Items

### A1 — Schedule edit UI (S effort)
- Backend route + controller done.
- Need: edit button + modal in `resources/js/Pages/Schedules/Index.vue` sending `PUT /schedules/{id}`.

### A2 — Admin reset password for other users (S effort)
- Add `POST /admin/users/{id}/reset-password` → generate new random password, notify via email or display once.
- Add button in user management page (admin only).

### A6 — Per-mapel web attendance (L effort, ~1 sprint)
- Web attendance currently daily/class-scoped. Mobile is per-TA/Meeting.
- Plan: add TA selector to `Attendance/Create.vue`, link `Attendance` records to `meeting_id` (FK to `meetings` table), scope `AttendanceController::create` to require TA selection.
- No migration allowed now — defer to dedicated phase.

### A7 — Excel format match (M effort)
- Review auditor's image1.jpeg format expectations.
- Update or create new `AttendanceRecapExport` class matching column layout.
- Add per-mapel sheet for teacher view; all-mapel for wali kelas view.

---

## Biggest Gap Remaining

**A6** — web attendance is fundamentally daily/class-scoped while mobile is per-TA/meeting. Aligning them is an architectural change requiring schema work (migration) and UI redesign. Cannot be done inline.
