# Product Specification Document (PRD)
## Project Name: FLOZ LMS - SDN KELAPA DUA IV

### 1. Pendahuluan
**1.1. Latar Belakang**
Project ini merupakan pengembangan Learning Management System (LMS) khusus yang diadaptasi dari framework FLOZ (yang awalnya multi-tenant) menjadi sistem **Single-School** yang didedikasikan sepenuhnya untuk operasional akademik di **SDN Kelapa Dua IV**. Sistem ini dirancang guna memfasilitasi kebutuhan administrasi sekolah, proses belajar mengajar, serta interaksi antara guru, siswa, dan orang tua dalam satu platform yang terintegrasi.

**1.2. Tujuan**
Menyediakan platform manajemen sekolah yang komprehensif, cepat, dan terisolasi khusus untuk SDN Kelapa Dua IV dengan arsitektur backend berbasis Laravel dan frontend web (Vue/Inertia) serta dukungan untuk aplikasi mobile (Flutter).

---

### 2. Pengguna Sistem (Roles & Permissions)
Sistem menggunakan *Role-Based Access Control* (RBAC) dengan tingkatan sebagai berikut:

1. **School Admin**
   - Administrator utama sekolah.
   - Mengelola seluruh data master: Siswa, Guru/Staff, Mata Pelajaran, Kelas, dan Tahun Akademik.
   - Mengatur penugasan guru (Teaching Assignments).
2. **Teacher (Guru)**
   - Mengelola pembelajaran untuk kelas yang diampu.
   - Mengatur materi pertemuan, tugas, input nilai, dan absensi harian.
   - Wali kelas dapat mencetak dan mempublikasikan rapor.
3. **Student (Siswa)**
   - Mengakses materi pelajaran dan tugas.
   - Mengirim lembar jawaban/tugas.
   - Melihat jadwal pelajaran, nilai, rapor, dan pengumuman.
4. **Parent (Orang Tua)**
   - Memantau perkembangan akademik anak.
   - Melihat riwayat absensi dan nilai rapor.

*(Catatan: Peran Super Admin/Platform SaaS ditiadakan pada scope single-school ini.)*

---

### 3. Fitur Utama (Core Features)

**3.1. Dashboard & Pengumuman**
- **Dashboard Personal:** Ringkasan informasi operasional yang disesuaikan dengan role pengguna.
- **Sistem Pengumuman:** Pembuatan informasi secara real-time via *Laravel Reverb* dengan fitur rich-text dan pin pengumuman.

**3.2. Manajemen Kesiswaan & Kepegawaian**
- **Data Siswa:** CRUD siswa, pencarian, filter, dan fitur Import massal via Excel/CSV.
- **Data Kepegawaian:** Manajemen data staf dan guru beserta status kepegawaian (NIP, dsb).

**3.3. Manajemen Akademik (Kurikulum)**
- **Manajemen Kelas & Mapel:** Pengaturan daftar mata pelajaran dan rombongan belajar (kelas).
- **Penugasan Guru (Teaching Assignments):** Mengaitkan guru dengan mata pelajaran dan kelas spesifik.

**3.4. Sistem Pembelajaran (Course Management)**
- **Struktur Pertemuan:** Setiap mata pelajaran digenerate otomatis menjadi 16 sesi (14 Pertemuan + UTS + UAS).
- **Materi & Tugas:** Guru dapat mengunggah modul/file, tautan, teks instruksi, hingga kuis (pilihan ganda, esai) pada tiap pertemuan.
- **Auto-Grading:** Kuis objektif memiliki fitur penilaian otomatis.

**3.5. Penilaian & Rapor (Grading System)**
- **Input Nilai:** Mendukung input nilai secara batch (massal) untuk efisiensi guru.
- **Rapor (Report Cards):** Pembuatan otomatis dokumen rapor PDF yang disesuaikan dengan format SDN Kelapa Dua IV (termasuk Kurikulum 13 / Merdeka). Publikasi rapor ke portal siswa/orang tua.

**3.6. Absensi (Attendance)**
- **Pencatatan Harian:** Guru dan admin dapat melakukan input serta rekap absensi harian per kelas/mata pelajaran.
- **Riwayat Kehadiran:** Pelacakan data kehadiran secara historikal.

---

### 4. Spesifikasi Teknis (Technical Specification)

**4.1. Teknologi Utama (Tech Stack)**
- **Backend:** Laravel 12 (PHP 8.2+)
- **Frontend Web:** Vue.js 3 + Inertia.js + Tailwind CSS
- **Database:** PostgreSQL 16 (Arsitektur Single Database)
- **Real-time WebSockets:** Laravel Reverb
- **Mobile App (Planned):** Flutter (Berkomunikasi via REST API)
- **Containerization:** Docker & Docker Compose (untuk environment deployment)

**4.2. Arsitektur & Keamanan**
- **Single-School Architecture:** Penghapusan sistem subdomain multi-tenant menjadi satu entitas monolith yang stabil.
- **Autentikasi:** Laravel Sanctum / Session-based authentication.
- **Audit Logging:** Pencatatan aktivitas krusial (Create/Update/Delete) untuk pelacakan perubahan data.

---

### 5. UI/UX Guidelines
- **Modern & Responsive:** Tampilan web dirancang responsif untuk desktop maupun tablet menggunakan Tailwind CSS.
- **UX Guru yang Efisien:** Fungsionalitas "Batch Input" sangat ditekankan pada pengisian rapor dan nilai.
- **Real-Time Feedback:** Notifikasi instan menggunakan WebSockets ketika terdapat pengumuman atau perubahan nilai yang krusial.

---

### 6. Timeline & Milestones Pengembangan
1. **Fase 1: Sistem Inti & Database** ✅
   - *Refactoring* dari Multi-Tenant ke Single-School.
   - Konfigurasi model, relasi, dan database PostgreSQL.
2. **Fase 2: Manajemen Akademik & Kelas**
   - Sinkronisasi data Mata Pelajaran, Guru, dan Siswa.
   - Sistem pertemuan 16 sesi.
3. **Fase 3: Pembelajaran & Penilaian**
   - Fitur upload tugas, kuis, auto-grading, dan input absensi.
   - Pembangkit PDF Rapor.
4. **Fase 4: Real-time & Komunikasi**
   - Integrasi Laravel Reverb untuk notifikasi & pengumuman.
5. **Fase 5: API & Mobile Integration**
   - Pembuatan endpoint RESTful API.
   - Pengembangan Flutter App untuk Siswa & Orang Tua.
