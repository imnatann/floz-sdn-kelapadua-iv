# Demo Data Report — FLOZ LMS (SDN Kelapadua IV)

**Date seeded:** 2026-05-09 17:00 WIB
**Branch:** `chore/remove-tenant-leftovers`
**Approach:** API-driven via HTTP POST to `/api/v1` and Inertia web routes; observers/audit logs/validation all triggered live.

---

## 🔑 Demo Credentials

All accounts use password **`password123`**.

### Admin (web)
- **Email:** `admin@floz.test`
- **Role:** `school_admin`
- **Login:** http://127.0.0.1:8765/login

### Teachers (web + mobile)
| # | Name | Email | NIP | Role |
|---|------|-------|-----|------|
| 1 | Hj. Siti Aminah, S.Pd      | siti.aminah@sdkelapadua4.sch.id | 196801011990032001 | wali kelas 1A |
| 2 | Drs. Ahmad Faisal          | ahmad.faisal@sdkelapadua4.sch.id | 197003151995011002 | wali kelas 2A |
| 3 | Dewi Lestari, S.Pd         | dewi.lestari@sdkelapadua4.sch.id | 197805201998022003 | wali kelas 3A |
| 4 | Bambang Setiawan, M.Pd     | bambang.s@sdkelapadua4.sch.id   | 198209142005021004 | wali kelas 4A |
| 5 | Rina Marlina, S.Pd         | rina.marlina@sdkelapadua4.sch.id| 198506252009032005 | wali kelas 5A |
| 6 | Hendra Wijaya, S.Pd        | hendra.w@sdkelapadua4.sch.id    | 198811302012061006 | wali kelas 6A |
| 7 | Ust. Yusuf Ramadhan        | yusuf.r@sdkelapadua4.sch.id     | 197512151999051007 | guru PAI |
| 8 | Ms. Linda Permata, BA      | linda.p@sdkelapadua4.sch.id     | 199003202015042008 | guru spesialis |
| 9 | Pak Joko Susilo            | joko.s@sdkelapadua4.sch.id      | 198701102011011009 | guru spesialis |
| 10| Ibu Dr. Mariam Salim       | mariam.s@sdkelapadua4.sch.id    | 197204182001062010 | guru spesialis |

### Students (web + mobile)
- 90 siswa. Email pattern: `<NIS>@siswa.sekolah.id`
- NIS dimulai dari **24001** sampai **24090** (15 siswa per kelas, urutan kelas 1A → 6A)
- Contoh login: `24001@siswa.sekolah.id` / `password123`

---

## 📊 Final DB State

```
Users:                101  (1 admin + 10 teachers + 90 students)
AcademicYears:        2    (active: 1)   → 2025/2026 active, 2026/2027 future
Semesters:            4    (active: 1)   → 1 Ganjil 2025/2026 active
Subjects:             10
Teachers:             10
SchoolClasses:        6    (Kelas 1A – 6A, semua dengan wali kelas)
TeachingAssignments:  60
Students:             90   (15 per kelas × 6 kelas)
Meetings (auto-gen):  960  ← TeachingAssignment::booted() observer fires
Attendance:           270  (3 meetings × 6 kelas × 15 siswa)
Grade entries:        900  ← storeBatch auto-generates ReportCard which back-fills all subjects
ReportCards:          90   ← auto-synced after grade batch input
Announcements:        6
Notifications:        ~450 ← NewAnnouncementNotification + GradePostedNotification
AuditLogs:            ~4089 ← Auditable trait fired on every create
```

---

## 🌊 API Workflow Triggered

Setiap entitas dibuat lewat HTTP POST ke routes Inertia, yang berarti **semua observer, validation, policy, audit log, dan downstream side-effect** ikut ter-trigger:

### Wave 1 — Academic Years (`POST /academic-years`)
- 2 AY dibuat. Validasi `unique:academic_years,name` aktif (Phase 8 W-07).
- AY 2025/2026 di-activate via `POST /academic-years/{id}/activate` → Auditable trait log + atomic deactivation other AYs.

### Wave 2 — Semesters (`POST /academic-years/{ay}/semesters`)
- 4 semester (Ganjil + Genap × 2 AY).
- Ganjil 2025/2026 di-activate via `POST /semesters/{id}/activate` → atomic per-AY scope deactivation.

### Wave 3 — Subjects (`POST /subjects`)
- 10 mata pelajaran SD: PAI, PKN, BI, MTK, IPA, IPS, SBK, PJOK, BING, BLAMP.
- KKM 65-70 per subject. Auditable log fired.

### Wave 4 — Teachers (`POST /staff`)
- 10 guru. NIP unique constraint validated. Auditable trait fired.
- ⚠️ **Catatan:** `TeacherController::store` belum auto-create User account. Akun User-nya saya bootstrap pakai Tinker setelah API seed selesai (lihat bagian "Manual Bootstrap" di bawah).

### Wave 5 — Classes (`POST /classes`)
- 6 kelas dengan `homeroom_teacher_id` pre-assigned ke teacher 1-6.
- `academic_year_id` mengikuti AY aktif.

### Wave 6 — Teaching Assignments (`POST /teaching-assignments`)
- 60 TA = (6 core subjects + 4 specialty subjects) × 6 classes.
- Core (PAI/PKN/BI/MTK/IPA/IPS) — PAI ke specialist, lainnya ke wali kelas.
- Specialty (SBK/PJOK/BING/BLAMP) — rotasi antara teacher 8-10.
- **`TeachingAssignment::booted()` observer fires** → 16 Meeting auto-created per TA. Total 960 meetings (60 TA × 16 meetings).

### Wave 7 — Students (`POST /students` dengan `create_account: true`)
- 90 siswa, 15 per kelas. NIS unique. Email auto-derived dari NIS.
- **Auto-create User account** (via StudentController) → User-Student linkage via email.
- Auditable trait fired untuk Student dan User.

### Wave 8 — Announcements (`POST /announcements`)
- 6 announcement dengan campuran type (info, event) dan target_audience (all/students/teachers).
- 1 dipinned (Selamat Datang).
- **Auto-fan-out notification:** AnnouncementController loop active users target audience → `notifications` table populated (~280 rows).

### Wave 9 — Attendance (`POST /attendance/{class}`)
- 3 meeting × 6 kelas × 15 siswa = 270 attendance records.
- Status distribution: ~85% hadir, 5% sakit, 3% izin, 2% alpha (realistic).
- `Auditable` log fired untuk setiap Attendance.

### Wave 10 — Grades (`POST /grades/batch`)
- BI/MTK/IPA × 6 kelas × 15 siswa = 270 batch entries.
- `GradeController::storeBatch` triggers:
  - **`GradeCalculationService::calculateSD`** untuk hitung final_score + predicate
  - **`GradePostedNotification`** dikirim ke setiap student (~270 notif)
  - **`ReportCardService::generate`** auto-create ReportCard → 90 ReportCards
  - **`ReportCardService::calculateRankings`** rerun untuk semua kelas
- Bonus: report_card.generate() back-fills empty Grade rows untuk semua active subjects per student → grade entries jadi 900 (90 × 10 subjects).

---

## 🛠️ Bugs Fixed Selama Seeding

Dua bug pre-existing surfaced + diperbaiki:

### Bug 1: `GradeController::storeBatch` calls `calculateRankings` with wrong arity
**File:** `src/app/Http/Controllers/GradeController.php:196`
**Issue:** Memanggil `$this->reportCardService->calculateRankings($classId, $semId)` — tapi service signature butuh 3 arg termasuk `$reportType`. 500 error.
**Fix:** Tambah `'final'` sebagai 3rd arg untuk both `generate()` dan `calculateRankings()` calls.

### Bug 2: `AnnouncementController::store` — `DB` class not imported
**File:** `src/app/Http/Controllers/AnnouncementController.php:10`
**Issue:** Method pakai `DB::table('notifications')->insert()` tapi `use Illuminate\Support\Facades\DB;` missing → Class not found 500.
**Fix:** Tambah import.

Both bugs would have surfaced di production juga. Bagus diketahui sekarang.

---

## ⚠️ Manual Bootstrap (Documented Exceptions)

API-driven seeding mostly worked, dengan 2 exception yang harus dilakukan via Tinker:

1. **Admin user (1 record):** Login butuh user yang sudah ada. Tidak ada `/register` endpoint untuk admin (single-school deployment, admin di-provision manual). Created via tinker:
   ```php
   User::create(['email'=>'admin@floz.test','password'=>Hash::make('password123'),'role'=>'school_admin','is_active'=>true,'name'=>'Admin Sekolah']);
   ```

2. **Teacher User accounts (10 records):** `TeacherController::store` belum auto-create User account (cuma create row Teacher). Untuk testing mobile login dari sisi guru, saya bootstrap User account via tinker:
   ```php
   foreach (Teacher::all() as $t) {
     User::create(['email'=>$t->email, 'password'=>Hash::make('password123'), 'role'=>'teacher', 'is_active'=>true, 'name'=>$t->name]);
   }
   ```

**Recommended Phase 12.5+ improvement:** Modify `TeacherController::store` to optionally create User account (mirip pattern di `StudentController` dengan flag `create_account`).

---

## 🚀 Quick Start untuk Testing/Demo

### 1. Login web admin
- URL: http://127.0.0.1:8765/login
- Email: `admin@floz.test`
- Password: `password123`
- Akses: full sidebar — Dashboard, Kelas, Siswa, Analitik, Tahun Ajaran, Kenaikan Kelas, dll

### 2. Login web teacher (wali kelas)
- Email: `siti.aminah@sdkelapadua4.sch.id` (wali kelas 1A)
- Password: `password123`
- Akses: dashboard teacher, scoped analytics (Phase 12)

### 3. Login web student
- Email: `24001@siswa.sekolah.id` (siswa pertama Kelas 1A)
- Password: `password123`
- Akses: student dashboard, lihat nilai/jadwal/announcement

### 4. Mobile app (Flutter)
- Sama dengan credentials di atas
- API base URL: configure di Flutter `lib/core/network/api_endpoints.dart`
- Hanya `teacher` dan `student` role boleh login mobile (admin diblok di `AuthService`)

### 5. Test workflow Phase 7 (Year Transition)
- Login admin → Sidebar > **Kenaikan Kelas**
- Step 1: Source AY = `2025/2026`, Target AY = `2026/2027`
- Step 2-4 walkthrough preview
- Step 5: Type "TERAPKAN" untuk commit (akan re-point semua siswa ke kelas grade+1, kelas 6A → graduated)

### 6. Test Analytics (Phase 11/12)
- Login admin → Sidebar > **Analitik** (4 widget) atau **Laporan** (3 chart + W7 teacher workload)
- Login teacher → sidebar yang sama tapi data scoped per kelas
- Excel export: `/analytics/reports` → "Export Excel"

---

## 📁 Generated Files

| File | Purpose |
|------|---------|
| `/tmp/floz-e2e/scripts/api-seed-demo.mjs` | Main API seeder (waves 1-10) |
| `/tmp/floz-e2e/scripts/api-seed-patch.mjs` | Patch for waves 8 + 10 (after bug fixes) |
| `/tmp/floz-e2e/seed-result.json` | Initial run stats |
| `/tmp/floz-e2e/seed-patch-result.json` | Patch run stats |
| `/tmp/seed-output.log` | Full seed log |
| `/tmp/floz_pre_demo_seed.sql` | Pre-reset DB backup (496KB) |

---

## 🗂️ Backup & Rollback

Backup pre-reset tersimpan di `/tmp/floz_pre_demo_seed.sql`. Untuk restore (full revert):

```bash
PGPASSWORD=$DB_PASS /Library/PostgreSQL/18/bin/dropdb -U $DB_USER -h $DB_HOST floz_sdn_kelapadua_iv
PGPASSWORD=$DB_PASS /Library/PostgreSQL/18/bin/createdb -U $DB_USER -h $DB_HOST floz_sdn_kelapadua_iv
PGPASSWORD=$DB_PASS /Library/PostgreSQL/18/bin/psql -U $DB_USER -h $DB_HOST -d floz_sdn_kelapadua_iv < /tmp/floz_pre_demo_seed.sql
```

(Backup berisi state pre-Phase-12-deploy + 16 dirty AYs; biasanya tidak perlu restore.)

---

## 📋 Audit Trail

Auditable trait fires on `created/updated/deleted` for: `Student`, `Teacher`, `SchoolClass`, `Subject`, `TeachingAssignment`, `Grade`, `Attendance`, `ReportCard`, `Announcement`, `User`, `AcademicYear`, `Semester`.

Total: **~4,089 audit log rows** dari seeding session ini. Bukti workflow ter-trigger penuh.

Cek di: http://127.0.0.1:8765/audit-logs (admin only).
