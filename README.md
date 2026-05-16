<p align="center">
  <img src="screenshots/landing.png" alt="FLOZ LMS" width="100%">
</p>

<h1 align="center">FLOZ LMS — SDN Kelapadua IV</h1>

<p align="center">
  <strong>Sistem informasi akademik dedicated untuk SDN Kelapadua IV</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Laravel_12-FF2D20?style=for-the-badge&logo=laravel&logoColor=white" alt="Laravel">
  <img src="https://img.shields.io/badge/Vue_3-4FC08D?style=for-the-badge&logo=vuedotjs&logoColor=white" alt="Vue.js">
  <img src="https://img.shields.io/badge/PostgreSQL_16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/Inertia.js-9553E9?style=for-the-badge&logo=inertia&logoColor=white" alt="Inertia">
  <img src="https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white" alt="Tailwind">
</p>

---

## ✨ Overview

Repo ini adalah adaptasi single-school dari framework **FLOZ LMS** (yang awalnya multi-tenant SaaS) untuk dipakai oleh **SDN Kelapadua IV**. Satu sekolah, satu database, satu instance — tidak ada konsep tenant/subdomain. Original framework readme tetap disimpan di [`FLOZ_README.md`](FLOZ_README.md) sebagai konteks historis.

---

## 🚀 Fitur Utama

### 👥 Role-Based Access Control
| Role | Kapabilitas |
|------|-------------|
| **School Admin** | Mengelola guru, siswa, kelas, mapel, tahun ajaran, penugasan |
| **Teacher** | Pertemuan, materi, tugas, absensi, input nilai, rapor |
| **Student** | Lihat materi, kumpul tugas, lihat nilai/rapor, jadwal |
| **Parent** | Pantau perkembangan akademik anak *(planned)* |

### 📚 Course Management (Pertemuan System)
- Tiap Teaching Assignment otomatis ter-generate jadi 16 pertemuan (M1–M14 + UTS + UAS).
- Per pertemuan: upload file/link/teks materi, lock/unlock visibility, attach tugas/quiz.

### 📝 Tugas & Ujian
- Manual assignment dengan file upload + grading manual oleh guru.
- Quiz engine (pilihan ganda, benar/salah, esai) dengan auto-grading untuk soal objektif.

### 📊 Manajemen Akademik
- CRUD Kelas, Mata Pelajaran, Tahun Akademik, Semester.
- Teaching Assignment matrix (Guru × Mapel × Kelas).
- Schedule management dengan conflict detection.
- Gradebook untuk Kurikulum 13 / Merdeka.

### 📄 Rapor (Report Card)
- PDF rapor auto-generate per Student × Semester (template SD).
- School identity (nama, alamat, dsb.) di-pull dari `config/school.php`.
- Import siswa massal via Excel/CSV.

### 📢 Pengumuman & Notifikasi
- Rich-text editor + pin pengumuman + cover image.
- Real-time notifikasi via **Laravel Reverb** (WebSocket).
- Targeting per role.

### 🔍 Audit Logging
- Full activity logging untuk operasi Create/Update/Delete dengan user attribution.

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Backend** | Laravel 12 (PHP 8.2+) |
| **Frontend** | Vue 3 + Inertia.js |
| **Styling** | Tailwind CSS |
| **Database** | PostgreSQL 16 (single connection) |
| **Real-time** | Laravel Reverb (WebSocket) |
| **API Docs** | Swagger / OpenAPI (`/docs`) |
| **Mobile** | Flutter via REST API (`/api/v1`) |

---

## ⚡ Quick Start

### Prasyarat
- PHP 8.2+ dengan ekstensi `pgsql`
- PostgreSQL 16+
- Node.js 18+ & NPM
- Composer 2+

### Instalasi

```bash
# 1. Clone
git clone https://github.com/imnatann/floz-sdn-kelapadua-iv.git
cd floz-sdn-kelapadua-iv

# 2. Install dependencies
cd src && composer install && npm install && cd ..

# 3. Environment
cp src/.env.example src/.env
cd src && php artisan key:generate

# 4. Database (atur kredensial PostgreSQL di src/.env)
php artisan migrate --seed

# 5. Build frontend
npm run build
```

### Menjalankan Lokal

Butuh 4 terminal:

```bash
# Terminal 1 — App server
cd src && php artisan serve

# Terminal 2 — Reverb (WebSocket)
cd src && php artisan reverb:start

# Terminal 3 — Queue worker
cd src && php artisan queue:listen

# Terminal 4 — Vite dev
cd src && npm run dev
```

### Akses

| URL | Keterangan |
|-----|-----------|
| `http://localhost:8000` | Aplikasi web |
| `http://localhost:8000/docs` | API documentation (Swagger) |

---

## 📁 Project Structure

```
src/
├── app/
│   ├── Http/Controllers/   # Web + API controllers
│   ├── Models/             # Eloquent models (flat namespace)
│   ├── Notifications/
│   └── Services/
├── config/
│   ├── school.php          # Identitas sekolah (name, address, etc.)
│   └── ...
├── database/
│   ├── migrations/
│   └── seeders/
├── resources/js/
│   ├── Pages/              # Inertia pages (flat by feature)
│   ├── Layouts/            # AppLayout, DocsLayout
│   └── Components/         # Reusable components
└── routes/
    ├── web.php             # Inertia + auth routes
    ├── api.php             # Mobile JSON API (/api/v1)
    └── channels.php        # Broadcast channel auth
```

---

## 📄 License

MIT — lihat [LICENSE](LICENSE).

---

<p align="center">
  Dibangun untuk SDN Kelapadua IV ❤️
</p>
