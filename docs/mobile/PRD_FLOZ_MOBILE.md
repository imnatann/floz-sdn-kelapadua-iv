# PRD - FLOZ Mobile App (Flutter)

> **Versi**: 1.0.0  
> **Tanggal**: 19 Februari 2026  
> **Status**: Draft — Menunggu Review  
> **Platform Target**: Android & iOS  
> **Framework**: Flutter (Dart)

---

## 1. Ringkasan Eksekutif

FLOZ Mobile adalah aplikasi pendamping (companion app) dari FLOZ LMS Web — platform SaaS manajemen rapor siswa K-12 di Indonesia. Aplikasi mobile difokuskan untuk **3 role utama**: **Student**, **Teacher**, dan **Parent** — memberikan akses cepat ke fitur yang paling sering digunakan di mana pun dan kapan pun.

> [!IMPORTANT]
> Aplikasi mobile ini BUKAN replika penuh web app. Fitur administratif berat (Tenant Management, Subscription Billing, Audit Logs) tetap di web. Mobile fokus pada **consumption & quick-action**.

### Tujuan Utama
1. **Siswa**: Cek nilai, jadwal, tugas, dan rapor dengan cepat
2. **Guru**: Input nilai, kelola tugas, cek absensi secara mobile-friendly
3. **Orang Tua**: Pantau perkembangan akademik anak secara real-time

---

## 2. Tech Stack

| Layer | Teknologi | Keterangan |
|:------|:----------|:-----------|
| **Framework** | Flutter 3.x (Dart) | Cross-platform Android & iOS |
| **State Management** | Riverpod 2.x | Scalable, testable state management |
| **Navigation** | GoRouter | Declarative routing dengan deep linking |
| **HTTP Client** | Dio + Retrofit | API calls dengan interceptor & code generation |
| **Local Storage** | Hive / SharedPreferences | Cache & offline preferences |
| **Push Notification** | Firebase Cloud Messaging (FCM) | Notifikasi real-time |
| **Auth** | Laravel Sanctum Token (Bearer) | Konsisten dengan existing web auth |
| **Image Loading** | CachedNetworkImage | Caching gambar profil & attachment |
| **Charts** | fl_chart | Grafik performa akademik |
| **PDF Viewer** | flutter_pdfview | Preview rapor langsung di app |
| **File Picker** | file_picker | Upload tugas |
| **Form Validation** | reactive_forms | Form handling yang robust |
| **Testing** | flutter_test + integration_test + Mockito | Unit, widget, & integration test |

---

## 3. Arsitektur

### 3.1 Arsitektur Tinggi (High-Level)

```
┌──────────────────────────────────────────────────────┐
│                   FLOZ Mobile App                     │
│  ┌────────┐  ┌──────────┐  ┌───────────────────────┐ │
│  │  UI    │──│ Provider  │──│  Repository Layer     │ │
│  │ Layer  │  │ (Riverpod)│  │  (Domain Abstraction) │ │
│  └────────┘  └──────────┘  └───────────────────────┘ │
│                                     │                 │
│                          ┌──────────┴─────────┐      │
│                          │   Data Sources      │      │
│                          │  ┌───────┐ ┌──────┐ │      │
│                          │  │Remote │ │Local │ │      │
│                          │  │(API)  │ │(Hive)│ │      │
│                          │  └───────┘ └──────┘ │      │
│                          └─────────────────────┘      │
└──────────────────────────────────────────────────────┘
                           │
                    HTTPS (Bearer Token)
                           │
┌──────────────────────────────────────────────────────┐
│              FLOZ Backend (Laravel 12)                │
│  ┌──────────────────┐   ┌──────────────────────────┐ │
│  │ API v1 (JSON)    │   │ Multi-Tenant Middleware   │ │
│  │ /api/v1/mobile/* │   │ (IdentifyTenant +        │ │
│  └──────────────────┘   │  Sanctum Auth)           │ │
│                         └──────────────────────────┘ │
│  ┌────────────┐  ┌──────────┐  ┌──────────────────┐ │
│  │ PostgreSQL │  │  Redis   │  │ MinIO (Storage)   │ │
│  └────────────┘  └──────────┘  └──────────────────┘ │
└──────────────────────────────────────────────────────┘
```

### 3.2 Folder Structure (Flutter)

```
floz_mobile/
├── lib/
│   ├── main.dart
│   ├── app.dart                         # MaterialApp + theme config
│   │
│   ├── core/
│   │   ├── constants/                    # API urls, keys, enums
│   │   ├── theme/                        # AppTheme, colors, typography
│   │   ├── network/                      # Dio client, interceptors
│   │   ├── storage/                      # Hive boxes, SharedPrefs
│   │   ├── utils/                        # Formatters, validators
│   │   └── router/                       # GoRouter configuration
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/                     # AuthRepository, AuthApi
│   │   │   ├── domain/                   # AuthState, UserModel
│   │   │   ├── presentation/             # LoginScreen, widgets
│   │   │   └── providers/                # authProvider, userProvider
│   │   │
│   │   ├── dashboard/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   ├── presentation/
│   │   │   │   ├── student_dashboard_screen.dart
│   │   │   │   ├── teacher_dashboard_screen.dart
│   │   │   │   └── parent_dashboard_screen.dart
│   │   │   └── providers/
│   │   │
│   │   ├── grades/                       # Lihat & input nilai
│   │   ├── schedule/                     # Jadwal pelajaran
│   │   ├── assignments/                  # Tugas (submit & review)
│   │   ├── attendance/                   # Absensi
│   │   ├── report_cards/                 # Rapor (view & download PDF)
│   │   ├── courses/                      # Kursus & Materi Pertemuan
│   │   ├── announcements/                # Pengumuman
│   │   ├── notifications/                # Push & in-app notifikasi
│   │   └── profile/                      # Profil user
│   │
│   └── shared/
│       ├── widgets/                      # Reusable components
│       │   ├── floz_card.dart
│       │   ├── floz_button.dart
│       │   ├── floz_badge.dart
│       │   ├── floz_stat_card.dart
│       │   ├── floz_empty_state.dart
│       │   ├── floz_loading.dart
│       │   └── floz_bottom_nav.dart
│       ├── models/                       # Shared data models
│       └── extensions/                   # Dart extensions
│
├── test/                                 # Unit & widget tests
├── integration_test/                     # Integration tests
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
│       └── SpaceGrotesk/
├── pubspec.yaml
└── analysis_options.yaml
```

---

## 4. Fitur Per Role

### 4.1 🎓 Student (Siswa)

| # | Fitur | Prioritas | Deskripsi |
|:--|:------|:----------|:----------|
| S1 | **Dashboard** | P0 | Greeting personal, stats kehadiran, jadwal hari ini, pengumuman terbaru |
| S2 | **Jadwal** | P0 | Jadwal mingguan per hari, dengan detail guru & jam |
| S3 | **Nilai** | P0 | Lihat nilai per mata pelajaran per semester |
| S4 | **Rapor** | P0 | Preview rapor digital + download PDF |
| S5 | **Tugas** | P0 | Daftar tugas, detail soal, submit jawaban + upload file |
| S6 | **Kursus** | P1 | Lihat materi per pertemuan (meeting materials) |
| S7 | **Pengumuman** | P1 | Feed pengumuman sekolah |
| S8 | **Profil** | P1 | Lihat data diri, foto, info kelas |
| S9 | **Notifikasi** | P1 | Push notif untuk tugas baru, nilai dipublish, pengumuman |

### 4.2 👨‍🏫 Teacher (Guru)

| # | Fitur | Prioritas | Deskripsi |
|:--|:------|:----------|:----------|
| T1 | **Dashboard** | P0 | Stats mengajar, jumlah kelas, jadwal hari ini |
| T2 | **Input Nilai** | P0 | Batch input nilai per kelas/mapel dengan validation KKM |
| T3 | **Jadwal** | P0 | Jadwal mengajar mingguan |
| T4 | **Tugas** | P0 | Buat tugas, upload file, lihat submission siswa, koreksi & beri nilai |
| T5 | **Absensi** | P0 | Input absensi harian per kelas |
| T6 | **Kursus** | P1 | Kelola materi per pertemuan |
| T7 | **Rapor** | P1 | Preview rapor kelas |
| T8 | **Pengumuman** | P2 | Lihat pengumuman (buat tetap di web) |
| T9 | **Notifikasi** | P1 | Push notif untuk submission murid baru |

### 4.3 👨‍👩‍👧 Parent (Orang Tua)

| # | Fitur | Prioritas | Deskripsi |
|:--|:------|:----------|:----------|
| P1 | **Dashboard** | P0 | Overview anak: kehadiran, jadwal, nilai terbaru |
| P2 | **Nilai Anak** | P0 | Lihat semua nilai anak per semester |
| P3 | **Rapor Anak** | P0 | Preview + download rapor anak |
| P4 | **Kehadiran** | P1 | Rekap kehadiran anak |
| P5 | **Jadwal Anak** | P1 | Jadwal pelajaran anak |
| P6 | **Pengumuman** | P1 | Pengumuman sekolah |
| P7 | **Notifikasi** | P0 | Push notif saat nilai dipublish, absensi dicatat |

---

## 5. Screen Map & Navigation

### 5.1 Bottom Navigation

```
┌──────────────────────────────────────────────┐
│                                              │
│              [Active Screen]                 │
│                                              │
├──────┬────────┬──────────┬─────────┬─────────┤
│ Home │ Jadwal │  Tugas   │  Nilai  │  Profil │
│  🏠  │  📅   │   📝     │   📊    │   👤   │
└──────┴────────┴──────────┴─────────┴─────────┘
```

> [!NOTE]
> Bottom nav ditampilkan untuk semua role. Tab yang muncul menyesuaikan role:
> - **Student**: Home, Jadwal, Tugas, Nilai, Profil
> - **Teacher**: Home, Jadwal, Tugas, Nilai (Input), Profil
> - **Parent**: Home, Jadwal Anak, Nilai Anak, Rapor, Profil

### 5.2 Screen Inventory

```
Auth Screens:
├── SplashScreen                    → Branding + auto-login check
├── TenantSelectionScreen           → Pilih / cari sekolah
├── LoginScreen                     → Email + password

Main Screens (Student):
├── StudentDashboardScreen          → Welcome, stats, jadwal hari ini
├── ScheduleScreen                  → Tab per hari, list jadwal
├── GradesListScreen                → List mapel + rata-rata per mapel
│   └── GradeDetailScreen           → Detail nilai per komponen
├── AssignmentsListScreen           → Tab (Belum/Selesai), deadline
│   └── AssignmentDetailScreen      → Detail soal + form submit
├── ReportCardsListScreen           → List rapor per semester
│   └── ReportCardViewScreen        → Preview rapor / download PDF
├── CoursesListScreen               → List mata pelajaran
│   └── CourseDetailScreen          → Per pertemuan + materi
├── AnnouncementsListScreen         → Feed pengumuman
│   └── AnnouncementDetailScreen    → Detail lengkap
├── NotificationsScreen             → List notifikasi
└── ProfileScreen                   → Data diri, info kelas, logout

Main Screens (Teacher):
├── TeacherDashboardScreen          → Stats, jadwal hari ini
├── ScheduleScreen                  → Jadwal mengajar
├── GradeInputScreen                → Pilih kelas + mapel
│   └── BatchGradeInputScreen       → Form input nilai batch
├── AssignmentsListScreen           → List tugas yang dibuat
│   ├── CreateAssignmentScreen      → Form buat tugas baru
│   └── AssignmentReviewScreen      → List submission + koreksi
│       └── CorrectionScreen        → Detail submission + nilai
├── AttendanceScreen                → Pilih kelas → input absensi
├── CourseManageScreen              → Kelola materi pertemuan
└── ProfileScreen                   → Data diri, logout

Main Screens (Parent):
├── ParentDashboardScreen           → Overview anak, stats
├── ChildScheduleScreen             → Jadwal anak
├── ChildGradesScreen               → Nilai anak per mapel
├── ChildReportCardScreen           → Rapor anak
├── ChildAttendanceScreen           → Rekap kehadiran anak
├── AnnouncementsListScreen         → Pengumuman sekolah
└── ProfileScreen                   → Data diri, logout
```

---

## 6. API Endpoints (Backend - Perlu Dibuat)

Saat ini backend FLOZ menggunakan Inertia.js (server-side rendering), sehingga belum tersedia REST API khusus mobile. Berikut endpoint yang perlu dibuat:

### 6.1 Auth

| Method | Endpoint | Deskripsi |
|:-------|:---------|:----------|
| `GET` | `/api/v1/tenants/search?q={query}` | Cari sekolah/tenant |
| `POST` | `/api/v1/auth/login` | Login → Sanctum token |
| `POST` | `/api/v1/auth/logout` | Revoke token |
| `GET` | `/api/v1/auth/me` | Profil user yang login |

### 6.2 Dashboard

| Method | Endpoint | Deskripsi |
|:-------|:---------|:----------|
| `GET` | `/api/v1/dashboard` | Dashboard data sesuai role |

### 6.3 Schedule

| Method | Endpoint | Deskripsi |
|:-------|:---------|:----------|
| `GET` | `/api/v1/schedules` | Jadwal user (student/teacher) |
| `GET` | `/api/v1/schedules/today` | Jadwal hari ini |

### 6.4 Grades

| Method | Endpoint | Deskripsi |
|:-------|:---------|:----------|
| `GET` | `/api/v1/grades` | Nilai user (student) / per kelas (teacher) |
| `GET` | `/api/v1/grades/{subjectId}` | Detail nilai per mapel |
| `POST` | `/api/v1/grades/batch` | Batch input nilai (teacher only) |

### 6.5 Assignments

| Method | Endpoint | Deskripsi |
|:-------|:---------|:----------|
| `GET` | `/api/v1/assignments` | List tugas |
| `GET` | `/api/v1/assignments/{id}` | Detail tugas |
| `POST` | `/api/v1/assignments` | Buat tugas (teacher) |
| `PUT` | `/api/v1/assignments/{id}` | Edit tugas (teacher) |
| `DELETE` | `/api/v1/assignments/{id}` | Hapus tugas (teacher) |
| `POST` | `/api/v1/assignments/{id}/submit` | Submit jawaban (student) |
| `GET` | `/api/v1/assignments/{id}/submissions` | List submission (teacher) |
| `POST` | `/api/v1/assignments/{id}/submissions/{subId}/grade` | Koreksi (teacher) |

### 6.6 Report Cards

| Method | Endpoint | Deskripsi |
|:-------|:---------|:----------|
| `GET` | `/api/v1/report-cards` | List rapor |
| `GET` | `/api/v1/report-cards/{id}` | Detail rapor |
| `GET` | `/api/v1/report-cards/{id}/pdf` | Download PDF |

### 6.7 Attendance

| Method | Endpoint | Deskripsi |
|:-------|:---------|:----------|
| `GET` | `/api/v1/attendance` | Rekap kehadiran |
| `POST` | `/api/v1/attendance` | Input absensi (teacher) |

### 6.8 Courses & Meetings

| Method | Endpoint | Deskripsi |
|:-------|:---------|:----------|
| `GET` | `/api/v1/courses` | List mata pelajaran / kursus |
| `GET` | `/api/v1/courses/{id}` | Detail kursus + pertemuan |
| `GET` | `/api/v1/courses/{id}/meetings/{meetingId}` | Detail pertemuan + materi |

### 6.9 Announcements

| Method | Endpoint | Deskripsi |
|:-------|:---------|:----------|
| `GET` | `/api/v1/announcements` | List pengumuman |
| `GET` | `/api/v1/announcements/{id}` | Detail pengumuman |

### 6.10 Notifications

| Method | Endpoint | Deskripsi |
|:-------|:---------|:----------|
| `GET` | `/api/v1/notifications` | List notifikasi |
| `POST` | `/api/v1/notifications/mark-all-read` | Tandai semua dibaca |
| `POST` | `/api/v1/notifications/{id}/mark-read` | Tandai satu dibaca |
| `POST` | `/api/v1/devices` | Register FCM token |

---

## 7. Authentication Flow

```
┌──────────┐     ┌─────────────────┐     ┌──────────────┐
│  Splash  │────▶│  Tenant Search  │────▶│    Login      │
│  Screen  │     │  (Cari Sekolah) │     │ (Email+Pass)  │
└──────────┘     └─────────────────┘     └──────┬───────┘
                                                │
                                    POST /api/v1/auth/login
                                    Body: { tenant_slug, email, password }
                                                │
                                         ┌──────▼───────┐
                                         │  Store Token  │
                                         │  + User Data  │
                                         │  (Hive/SP)    │
                                         └──────┬───────┘
                                                │
                                    ┌───────────┼────────────┐
                                    │           │            │
                              role=student  role=teacher  role=parent
                                    │           │            │
                              ┌─────▼──┐  ┌────▼────┐ ┌────▼─────┐
                              │Student │  │Teacher  │ │Parent    │
                              │Dashbrd │  │Dashbrd  │ │Dashboard │
                              └────────┘  └─────────┘ └──────────┘
```

**Token Strategy:**
- Login menggunakan Laravel Sanctum → return Bearer token
- Token disimpan di Hive (encrypted local storage)
- Setiap API request menggunakan `Authorization: Bearer {token}`
- Auto-logout jika token expired (401 response)
- Refresh token via re-login (Sanctum tidak support refresh token built-in)

---

## 8. Offline Capability

| Fitur | Offline Mode |
|:------|:-------------|
| Dashboard | ✅ Cache data terakhir |
| Jadwal | ✅ Full offline (di-cache saat pertama load) |
| Nilai | ✅ View cached, ❌ input perlu online |
| Rapor | ✅ PDF yang sudah didownload |
| Tugas | ✅ View cached, ❌ submit perlu online |
| Pengumuman | ✅ Cache list terbaru |
| Notifikasi | ❌ Perlu online |

---

## 9. Push Notification Strategy

### 9.1 Trigger Events

| Event | Target | Priority |
|:------|:-------|:---------|
| Tugas baru dibuat | Student | High |
| Mendekati deadline tugas | Student | Medium |
| Nilai dipublish | Student + Parent | High |
| Rapor dipublish | Student + Parent | High |
| Pengumuman baru | All | Medium |
| Submission masuk | Teacher | Medium |
| Kehadiran dicatat (izin/alpha) | Parent | High |

### 9.2 Implementation
- Gunakan **Firebase Cloud Messaging (FCM)**
- Backend mengirim notification via Firebase Admin SDK (PHP)
- Mobile register FCM token via `POST /api/v1/devices`
- Support **topic-based** (per class, per school) dan **individual** notification

---

## 10. Security

1. **SSL/TLS** — Semua komunikasi via HTTPS
2. **Token-based Auth** — Laravel Sanctum Bearer Token
3. **Certificate Pinning** — Opsional untuk production
4. **Tenant Isolation** — Setiap request menyertakan `X-Tenant-Slug` header
5. **Input Validation** — Validasi di client + server
6. **Secure Storage** — Gunakan flutter_secure_storage untuk token
7. **Rate Limiting** — Backend rate limit per user/tenant
8. **No Sensitive Data Logging** — Pastikan log tidak mengandung token/password

---

## 11. Milestone & Timeline

### Phase 1 — Foundation (Minggu 1-2)
- [x] PRD & Style Guide ← **Kamu ada di sini**
- [ ] Setup Flutter project + folder structure
- [ ] Setup core layer (theme, network, storage, router)
- [ ] Setup backend API routes (`/api/v1/mobile/*`)
- [ ] Implement Auth feature (login, logout, auto-login)

### Phase 2 — Core Student Features (Minggu 3-4)
- [ ] Student Dashboard
- [ ] Schedule screen
- [ ] Grades list & detail
- [ ] Report card viewer + PDF download
- [ ] Announcements

### Phase 3 — Core Teacher Features (Minggu 5-6)
- [ ] Teacher Dashboard
- [ ] Batch grade input
- [ ] Attendance input
- [ ] Assignment management (CRUD + review submissions)

### Phase 4 — Advanced Features (Minggu 7-8)
- [ ] Assignment submission flow (Student)
- [ ] Course & meeting materials
- [ ] Parent features (child monitoring)
- [ ] Push notifications (FCM)

### Phase 5 — Polish & Launch (Minggu 9-10)
- [ ] Offline caching
- [ ] Error handling & retry logic
- [ ] Testing (unit + integration)
- [ ] UI polish & micro-animations
- [ ] App store preparation (icon, screenshots, listing)
- [ ] Beta testing

---

## 12. KPI & Success Metrics

| Metric | Target |
|:-------|:-------|
| Login-to-dashboard time | < 2 detik |
| App crash rate | < 0.5% |
| Daily Active Users (DAU) | > 40% dari total registered |
| Push notification open rate | > 30% |
| App store rating | ≥ 4.5 ★ |
| PDF download time | < 3 detik |
| Offline load time | < 500ms |

---

## 13. Glossary

| Istilah | Definisi |
|:--------|:---------|
| **Tenant** | Sekolah yang terdaftar di platform FLOZ |
| **KKM** | Kriteria Ketuntasan Minimal — batas nilai minimum kelulusan |
| **KI-3 / KI-4** | Kompetensi Inti Pengetahuan / Keterampilan (SMP/SMA) |
| **NISN** | Nomor Induk Siswa Nasional |
| **NIS** | Nomor Induk Siswa (lokal sekolah) |
| **Predikat** | Kategori capaian (A/B/C/D) berdasarkan skor akhir |
| **Pertemuan** | Meeting — unit materi pembelajaran per sesi kelas |
| **Rapor** | Report card — kartu hasil studi per semester |
| **Wali Kelas** | Homeroom teacher yang bertanggung jawab atas suatu kelas |
