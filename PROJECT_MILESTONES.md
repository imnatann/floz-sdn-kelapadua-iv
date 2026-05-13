# FLOZ Project Milestones & Screening — SDN Kelapadua IV

Dokumen ini berisi screening fitur, role, dan halaman dalam project FLOZ LMS edisi single-school
untuk SDN Kelapadua IV. Tujuannya: gambaran scope project + tracking progress development.

---

## 1. User Roles & Permissions

Sistem memakai Role-based Access Control (RBAC) sederhana yang didefinisikan di `App\Enums\UserRole`.

| Role | Deskripsi |
| :--- | :--- |
| **School Admin** (`school_admin`) | Administrator sekolah. Mengelola seluruh data sekolah (Guru, Siswa, Mapel, Kelas, dll). |
| **Teacher** (`teacher`) | Guru pengajar. Mengelola nilai, absensi, dan data kelas yang diampu. |
| **Student** (`student`) | Siswa. Melihat nilai, jadwal, dan pengumuman. |
| **Parent** (`parent`) | Orang tua siswa. Memantau perkembangan akademik anak. |

> Catatan: peran `super_admin` masih tersisa di enum sebagai sisa dari framework asli (multi-tenant SaaS),
> tetapi tidak relevan untuk deployment single-school dan tidak punya UI.

---

## 2. Fitur Utama

### 📌 Dashboard
-   **URL**: `/dashboard`
-   **Role**: All
-   **Fitur**: Ringkasan data sekolah, statistik siswa/guru, pengumuman terbaru.

### 📌 Student Management (Kesiswaan)
-   **URL**: `/students`
-   **Role**: School Admin
-   **Fitur**:
    -   List Data Siswa (Search & Filter)
    -   Create/Edit Siswa
    -   **Import Siswa** (via Excel)
    -   Download Template Import

### 📌 Academic Management (Akademik)

#### Classes (Kelas)
-   **URL**: `/classes`
-   **Role**: School Admin
-   **Fitur**: Manage Data Kelas & Wali Kelas.

#### Subjects (Mata Pelajaran)
-   **URL**: `/subjects`
-   **Role**: School Admin
-   **Fitur**: Manage Data Mata Pelajaran.

#### Teaching Assignments (Penugasan Guru)
-   **URL**: `/teaching-assignments`
-   **Role**: School Admin
-   **Fitur**: Assign Guru ke Kelas & Mapel tertentu.

### 📌 Staff Management (Kepegawaian)
-   **URL**: `/staff`
-   **Role**: School Admin
-   **Fitur**: Manage Data Guru & Staff (NIP, Status, dll).

### 📌 Grading System (Penilaian)

#### Grades Input
-   **URL**: `/grades`
-   **Role**: Teacher
-   **Fitur**:
    -   Input Nilai per Kelas/Mapel
    -   **Batch Input**: Input nilai massal untuk efisiensi.

#### Report Cards (Rapor)
-   **URL**: `/report-cards`
-   **Role**: School Admin, Teacher (Wali Kelas)
-   **Fitur**:
    -   Generate Rapor
    -   Preview Rapor
    -   Publish Rapor (agar bisa dilihat siswa/ortu)
    -   **Download PDF**: Cetak rapor fisik.

### 📌 Attendance (Absensi)
-   **URL**: `/attendance`
-   **Role**: Teacher, School Admin
-   **Fitur**: Input & Rekap Absensi Harian.

### 📌 Communication (Informasi)

#### Announcements
-   **URL**: `/announcements`
-   **Role**: School Admin
-   **Fitur**: Buat pengumuman sekolah (rich-text + pin + cover image), broadcast real-time via Reverb.

#### Notifications
-   **URL**: `/notifications`
-   **Role**: All
-   **Fitur**: Inbox notifikasi user (announcement, nilai, absensi, dll).

### 📌 Audit Logs
-   **URL**: `/audit-logs`
-   **Role**: School Admin
-   **Fitur**: Riwayat Create/Update/Delete operasi krusial untuk pelacakan.

---

## 3. Frontend Page Structure (Vue/Inertia)

Mapping file Vue component ke fitur.

```text
resources/js/Pages/
├── Auth/                   # Login Page
├── Dashboard/              # Admin / Teacher / Student dashboards
├── Students/               # Student Management
├── Staff/                  # Teacher Management
├── Classes/                # Class Management
├── Subjects/               # Subject Management
├── TeachingAssignments/    # Teacher Assignment
├── Schedules/              # Weekly schedule per class
├── Courses/                # Course (TA expansion: meetings + materials)
├── Materials/              # Material viewer
├── Meetings/               # Meeting detail
├── Grades/                 # Grade Input & Batch
├── ReportCards/            # Report Generation & PDF
├── Attendance/             # Attendance
├── Tasks/                  # Tugas (online)
├── Exams/                  # Ujian
├── OfflineAssignments/     # Tugas offline (file upload + quiz)
├── Announcements/          # Announcements
├── AuditLogs/              # Audit log viewer
├── Notifications/          # Notification inbox
├── Docs.vue                # Documentation Page
└── Welcome.vue             # Landing Page
```
