# Backend Product Specification & Testing Flows
## Project: FLOZ LMS - SDN KELAPA DUA IV (Single-School)

Dokumen ini merinci spesifikasi fungsional backend, alur data (data flow), dan skenario pengujian (testing scenarios) untuk mempermudah QA/SDET, khususnya dalam otomatisasi testing API/Endpoint backend menggunakan TestSprite.

---

## 1. Arsitektur & Teknologi Backend
- **Framework:** Laravel 12 (PHP 8.2+) dengan arsitektur *Monolith Single-Database*.
- **API & State Management:** Menggunakan stack *Inertia.js*. Permintaan ke server umumnya berupa `GET` untuk page render, dan `POST/PUT/DELETE` yang mengembalikan JSON/Redirect Inertia.
- **Autentikasi:** Session-based (Laravel default cookie/session auth) untuk Web/Inertia.
- **Real-time:** Laravel Reverb (WebSockets) untuk broadcast event.

---

## 2. Roles, Permissions & Alur Autentikasi

### 2.1. Roles (Peran Pengguna)
Sistem memiliki 4 entitas pengguna utama yang dibedakan dengan kolom `role` (atau relasi):
1. **Admin / School Admin (`admin`)**: Akses penuh ke Master Data.
2. **Teacher (`teacher`)**: Akses ke manajemen kelas yang diajarkan, absensi, tugas, nilai.
3. **Student (`student`)**: Mengakses materi, mengumpulkan tugas, dan melihat rapor.
4. **Parent (`parent`)**: Melihat histori absensi dan nilai anak.

### 2.2. Autentikasi (Auth Flows)
- **POST `/login`**: 
  - **Payload:** `email`, `password`.
  - **Validasi:** Cek kredensial di tabel `users`.
  - **Success Response:** 302 Redirect ke `/dashboard`.
  - **Validation Error:** 422 Unprocessable Entity (Email/Password salah).
- **POST `/logout`**: 
  - Membersihkan session pengguna.
  - **Success Response:** 302 Redirect ke `/login`.

---

## 3. Core Modules & Endpoints (Alur CRUD & Logika Bisnis)

### 3.1. Manajemen Pengguna & Master Data
Modul ini hanya dapat diakses oleh **Admin**.
#### A. Siswa (Students)
- **GET `/students`**: Menampilkan daftar siswa (Paginasi, Pencarian).
- **POST `/students`**: Tambah siswa tunggal.
  - **Payload Validations:** `nisn` (unique), `name`, `email` (unique), `password`, `class_id`, `gender`.
- **POST `/students/import`**: Bulk import siswa via Excel/CSV.
  - **Validasi:** Validasi ekstensi `.xlsx`, `.csv`. Pengecekan duplikasi NISN.
- **PUT `/students/{id}`** & **DELETE `/students/{id}`**: Update / Soft Delete data siswa.

#### B. Guru / Staff (Teachers)
- **GET `/staff`**: Menampilkan daftar kepsek, guru, admin.
- **POST `/staff`**: Menambahkan staff baru.
  - **Payload Validations:** `nip`/`nuptk` (unique), `name`, `role`.

#### C. Tahun Akademik & Kelas (Academic Years & Classes)
- **POST `/academic-years`**: Menambahkan tahun ajaran (ex: "2024/2025 - Ganjil"). Status `is_active` hanya boleh satu yang `true`.
- **POST `/classes`**: Menambahkan Rombongan Belajar. 
  - **Payload:** `name`, `level`, `homeroom_teacher_id` (Wali Kelas).

#### D. Mata Pelajaran (Subjects)
- **POST `/subjects`**: 
  - **Payload:** `code` (unique), `name`, `type` (Muatan Nasional, Muatan Lokal).

---

### 3.2. Penugasan Mengajar (Teaching Assignments)
Modul untuk menghubungkan Guru, Mata Pelajaran, dan Kelas.
- **Endpoint:** `/teaching-assignments`
- **Alur Bisnis:**
  1. Admin memilih `teacher_id`, `subject_id`, `class_id`, dan `academic_year_id`.
  2. **Validasi Kritis:** Mencegah satu kelas memiliki 2 guru untuk mata pelajaran yang sama di semester yang sama (Unique constraint check).
  3. **Trigger Otomatis:** Ketika di-create, sistem akan melakukan *auto-generate* 16 Pertemuan (Meetings) untuk penugasan ini secara otomatis di *background/observer*.

---

### 3.3. Manajemen Pertemuan & Modul (Class & Meetings)
Setiap "Teaching Assignment" memiliki 16 Sesi (Meetings) yang digenerate otomatis.
- **Endpoint:** `/meetings/{id}`
- **Alur Bisnis (Akses: Teacher):**
  1. Guru membuka halaman detail kelas (Teaching Assignment).
  2. Guru memilih salah satu Sesi (Meeting 1 - 16).
  3. Guru dapat mengubah `title`, `description`, `date`, `status` (Draft -> Published).
  4. Guru dapat menambahkan materi (Video/File) via `/module-materials`.
- **Test Scenarios:** 
  - Pastikan guru A *TIDAK BISA* mengubah (PUT/PATCH) meeting milik guru B (403 Forbidden).

---

### 3.4. Tugas & Pengumpulan (Assignments & Submissions)
- **Endpoint Pengumpulan Siswa:** `/tasks/{task_id}/submissions`
- **Alur Bisnis:**
  1. Guru membuat Tugas tipe Essay / Multiple Choice per Pertemuan.
  2. Siswa *login*, melihat notifikasi, mengakses halaman tugas.
  3. Siswa mengirim jawaban (POST Submission) upload file/teks.
  4. **Validasi:** Siswa tidak bisa submit melebihi `due_date`. Siswa tidak bisa submit dua kali (kecuali diizinkan *resubmit*).
  5. Guru menginput nilai `score` pada setiap *submission* murid melalui `/tasks/{task}/scores` (Batch grading).

---

### 3.5. Absensi (Attendance)
Modul untuk pencatatan absensi harian.
- **Endpoint:** `/attendance` (GET, POST)
- **Alur Bisnis (Akses: Teacher/Admin):**
  1. Guru memilih Kelas dan Pertemuan.
  2. Guru menandai status (Hadir, Sakit, Izin, Alpha) untuk setiap siswa di kelas tersebut.
  3. **Validasi:** Mencegah input duplikat (Sistem hanya memperbolehkan 1 rekam absen per siswa, per kelas, per meeting / tanggal). 
     - *Catatan:* Peraturan `unique constraint` di tabel `attendances` mencakup `class_id`, `student_id`, `meeting_id`, `date`.

---

### 3.6. Sistem Penilaian (Grading) & Rapor (Report Cards)
- **Endpoint:** `/grading` & `/report-cards`
- **Alur Bisnis:**
  1. Guru menginput nilai Harian, UTS, dan UAS dalam format Batch (Satu tabel grid, disubmit sekaligus).
  2. Nilai dikalkulasi sesuai bobot algoritma: `(Nilai Harian * 30%) + (UTS * 30%) + (UAS * 40%)`.
  3. Wali Kelas memvalidasi rekap absen, nilai akademik, dan ekstrakurikuler.
  4. Wali Kelas mem-publish Rapor.
  5. Orang Tua/Siswa dapat mengunduh PDF Rapor di akhir semester.

---

### 3.7. Pengumuman & Real-time (Announcements)
- **Endpoint:** `/announcements`
- **Alur Bisnis:**
  1. Admin membuat pengumuman (bisa *pinned* / broadcast).
  2. Saat di-*save*, Laravel Event `AnnouncementCreated` di-trigger.
  3. Melalui **Laravel Reverb**, pesan disiarkan (broadcast) melalui channel WebSockets.
  4. Klien (Browser/Vue) menangkap event dan menampilkan Popover Toast Notifikasi tanpa perlu me-refresh halaman.

---

## 4. Panduan Eksekusi Testing (Terutama untuk TestSprite AI)

Untuk membuat *Automation Tests* (Unit/Feature Test di Pest/PHPUnit) di backend, ikuti aturan / *constraints* berikut:

### 4.1. Kondisi Data Setup (Seeding)
- Pastikan selalu memanggil `RolesAndPermissionsSeeder` jika menggunakan spatie/laravel-permission.
- Pastikan membuat `User` dengan role yang spesifik menggunakan Model Factory.

### 4.2. Positive Test Cases yang Wajib Ada
1. **Login & Session Validation:** Autentikasi berhasil dan menerima Session Cookie.
2. **Access Control (Authorization):** 
   - Guru men-GET data kelas miliknya -> `200 OK`.
   - Admin membuat siswa baru -> `201/302 OK`.
3. **Data Constraint Check:**
   - Menyimpan *Attendance* harus terekam secara atomic untuk satu kelas.
   - Pengecekan kalkulasi matematika di *Grading* (Jika Harian 80, UTS 80, UAS 80 = Total 80).
4. **Auto-generation:** Saat *TeachingAssignment* dibuat, assert jumlah *Meeting* = 16.

### 4.3. Negative Test Cases (Validation Errors)
1. **Unregistered Email / Wrong Password:** -> Assert redirect session berisikan *error messages*.
2. **Unauthorized Access (403 Forbidden):**
   - Siswa mengakses endpoint `/staff` atau `/teaching-assignments`.
   - Guru mencoba mengedit nilai pada kelas milik guru lain.
3. **Duplicate Input (422 / 500 Constraint Error):**
   - Mengisi presensi kehadiran yang sama di tanggal dan sesi yang sama untuk siswa yang sama.
   - Memasukkan NISN siswa yang sudah ada di database saat Create/Import.
4. **Invalid Dates / Overlap:**
   - Men-submit tugas melewati `due_date`.

### 4.4. Cara Menjalankan Test (Lokal)
```bash
# Menjalankan seluruh testing Pest/PHPUnit
php artisan test

# Menjalankan spesifik test file
php artisan test tests/Feature/AttendanceTest.php
```

---
*Dokumen ini merupakan sumber kebenaran utama (Single Source of Truth) atas alur logika backend aplikasi LMS SDN Kelapa Dua IV untuk keperluan pengembangan, validasi, dan skenario Quality Assurance.*
