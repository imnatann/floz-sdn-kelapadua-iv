# FLOZ Project Milestones & Screening

Document ini berisi hasil screening fitur, role, dan halaman yang ada dalam project FLOZ.
Tujuannya adalah untuk memberikan gambaran jelas mengenai *scope* project dan memudahkan tracking progress development.

---

## 1. User Roles & Permissions

Sistem menggunakan Role-based Access Control (RBAC) sederhana yang didefinisikan dalam `App\Enums\UserRole`.

| Role | Level | Deskripsi |
| :--- | :--- | :--- |
| **Super Admin** (`super_admin`) | Platform | Administrator utama aplikasi (SaaS Owner). Mengelola Tenant/Sekolah. |
| **School Admin** (`school_admin`) | Tenant | Administrator sekolah. Mengelola seluruh data sekolah (Guru, Siswa, Mapel, dll). |
| **Teacher** (`teacher`) | Tenant | Guru pengajar. Mengelola nilai, absensi, dan data kelas yang diampu. |
| **Student** (`student`) | Tenant | Siswa. Melihat nilai, jadwal, dan pengumuman. |
| **Parent** (`parent`) | Tenant | Orang tua siswa. Memantau perkembangan akademik anak. |

---

## 2. Platform Features (Admin Area)

Fitur yang tersedia untuk **Super Admin** di domain `admin.floz.id`.

### 📌 Dashboard
-   **URL**: `/platform/dashboard`
-   **Fitur**: Overview statistik platform usage.

### 📌 Tenant Management
-   **URL**: `/platform/tenants`
-   **Fitur**:
    -   List semua sekolah (Tenant)
    -   Create Tenant baru (Register Sekolah)
    -   Edit data Tenant
    -   Delete Tenant

---

## 3. Tenant Features (School Area)

Fitur yang tersedia untuk **School Admin**, **Teacher**, **Student**, & **Parent** di domain `school.floz.id`.

### 📌 Dashboard
-   **URL**: `/tenant/dashboard`
-   **Role**: All
-   **Fitur**: Ringkasan data sekolah, statistik siswa/guru, pengumuman terbaru.

### 📌 Student Management (Kesiswaan)
-   **URL**: `/tenant/students`
-   **Role**: School Admin
-   **Fitur**:
    -   List Data Siswa (Search & Filter)
    -   Create/Edit Siswa
    -   **Import Siswa** (via Excel)
    -   Download Template Import

### 📌 Academic Management (Akademik)
#### Classes (Kelas)
-   **URL**: `/tenant/classes`
-   **Role**: School Admin
-   **Fitur**: Manage Data Kelas & Wali Kelas.

#### Subjects (Mata Pelajaran)
-   **URL**: `/tenant/subjects`
-   **Role**: School Admin
-   **Fitur**: Manage Data Mata Pelajaran.

#### Teaching Assignments (Penugasan Guru)
-   **URL**: `/tenant/teaching-assignments`
-   **Role**: School Admin
-   **Fitur**: Assign Guru ke Kelas & Mapel tertentu.

### 📌 Staff Management (Kepegawaian)
-   **URL**: `/tenant/staff`
-   **Role**: School Admin
-   **Fitur**: Manage Data Guru & Staff (NIP, Status, dll).

### 📌 Grading System (Penilaian)
#### Grades Input
-   **URL**: `/tenant/grades`
-   **Role**: Teacher
-   **Fitur**:
    -   Input Nilai per Kelas/Mapel
    -   **Batch Input**: Input nilai massal untuk efisiensi.

#### Report Cards (Rapor)
-   **URL**: `/tenant/report-cards`
-   **Role**: School Admin, Teacher (Wali Kelas)
-   **Fitur**:
    -   Generate Rapor
    -   Preview Rapor
    -   Publish Rapor (agar bisa dilihat siswa/ortu)
    -   **Download PDF**: Cetak rapor fisik.

### 📌 Attendance (Absensi)
-   **URL**: `/tenant/attendance`
-   **Role**: Teacher, School Admin
-   **Fitur**: Input & Rekap Absensi Harian.

### 📌 Communication (Informasi)
#### Announcements
-   **URL**: `/tenant/announcements`
-   **Role**: School Admin
-   **Fitur**: Buat pengumuman sekolah.

### 📌 System Status
#### Subscription
-   **URL**: `/tenant/subscription/expired`
-   **Fitur**: Page block ketika masa aktif sekolah habis.

---

## 4. Frontend Page Structure (Vue/Inertia)

Mapping file Vue component ke fitur.

```text
resources/js/Pages/
├── Auth/                   # Login Page
├── Platform/               # Super Admin Area
│   ├── Dashboard.vue
│   └── Tenants/            # CRUD Tenants
├── Tenant/                 # School Area
│   ├── Dashboard.vue
│   ├── Students/           # Student Management
│   ├── Staff/              # Teacher Management
│   ├── Classes/            # Class Management
│   ├── Subjects/           # Subject Management
│   ├── TeachingAssignments/# Teacher Assignment
│   ├── Grades/             # Grade Input & Batch
│   ├── ReportCards/        # Report Generation & PDF
│   ├── Attendance/         # Attendance
│   ├── Announcements/      # Announcements
│   └── Subscription/       # Expired Page
├── Docs.vue                # Documentation Page
└── Welcome.vue             # Landing Page
```
