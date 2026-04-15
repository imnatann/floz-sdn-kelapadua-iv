# 📋 Use Case Document — FLOZ LMS SDN Kelapa Dua IV

> **Diagram visual tersedia di:** [UseCase_Overview.drawio](./UseCase_Overview.drawio)  
> Buka dengan **draw.io** (VS Code extension atau [app.diagrams.net](https://app.diagrams.net))

---

## 1. Aktor

| No | Aktor | Deskripsi |
|----|-------|-----------|
| 1 | **Admin** | Administrator sekolah — mengelola data master, konfigurasi, pengumuman, dan audit |
| 2 | **Guru** | Tenaga pengajar — mengelola pertemuan, tugas, ujian, absensi, penilaian, dan rapor |

---

## 2. Daftar Use Case

### 2.1 Autentikasi
| ID | Use Case | Aktor |
|----|----------|-------|
| UC-A01 | Login | Admin, Guru |
| UC-A02 | Logout | Admin, Guru |

### 2.2 Dashboard
| ID | Use Case | Aktor |
|----|----------|-------|
| UC-D01 | Dashboard Admin | Admin |
| UC-D02 | Dashboard Guru | Guru |

### 2.3 Manajemen Siswa
| ID | Use Case | Aktor |
|----|----------|-------|
| UC-S01 | Lihat Daftar Siswa | Admin |
| UC-S02 | Tambah Siswa | Admin |
| UC-S03 | Edit Data Siswa | Admin |
| UC-S04 | Hapus Siswa | Admin |
| UC-S05 | Import Siswa (Excel/CSV) | Admin |
| UC-S06 | Download Template Import | Admin |
| UC-S07 | Download Kartu Siswa | Admin |

### 2.4 Manajemen Guru/Staff
| ID | Use Case | Aktor |
|----|----------|-------|
| UC-T01 | Lihat Daftar Staff | Admin |
| UC-T02 | Tambah Staff | Admin |
| UC-T03 | Edit Data Staff | Admin |
| UC-T04 | Hapus Staff | Admin |

### 2.5 Manajemen Akademik
| ID | Use Case | Aktor |
|----|----------|-------|
| UC-K01 | CRUD Kelas | Admin |
| UC-K02 | CRUD Mata Pelajaran | Admin |
| UC-K03 | CRUD Penugasan Mengajar | Admin |
| UC-K04 | Auto-Generate 16 Pertemuan | Sistem (<<include>> dari UC-K03) |

### 2.6 Jadwal Pelajaran
| ID | Use Case | Aktor |
|----|----------|-------|
| UC-J01 | Lihat Jadwal | Admin, Guru |
| UC-J02 | Buat Jadwal | Admin |
| UC-J03 | Hapus Jadwal | Admin |

### 2.7 Pertemuan & Materi
| ID | Use Case | Aktor |
|----|----------|-------|
| UC-P01 | Lihat Daftar Pertemuan | Guru |
| UC-P02 | Edit Detail Pertemuan | Guru |
| UC-P03 | Upload Materi | Guru |
| UC-P04 | Lock/Unlock Pertemuan | Guru |

### 2.8 Tugas & Penilaian Tugas
| ID | Use Case | Aktor |
|----|----------|-------|
| UC-TG01 | Lihat Daftar Tugas | Guru |
| UC-TG02 | Buat Tugas | Guru |
| UC-TG03 | Hapus Tugas | Guru |
| UC-TG04 | Lihat Submission Siswa | Guru |
| UC-TG05 | Input Nilai Tugas (Batch) | Guru |

### 2.9 Ujian & Penilaian Ujian
| ID | Use Case | Aktor |
|----|----------|-------|
| UC-UJ01 | Lihat Daftar Ujian | Guru |
| UC-UJ02 | Buat Ujian | Guru |
| UC-UJ03 | Hapus Ujian | Guru |
| UC-UJ04 | Input Nilai Ujian (Batch) | Guru |

### 2.10 Absensi
| ID | Use Case | Aktor |
|----|----------|-------|
| UC-AB01 | Lihat Rekap Absensi | Admin, Guru |
| UC-AB02 | Input Absensi | Admin, Guru |
| UC-AB03 | Edit Absensi | Guru |

### 2.11 Penilaian Akhir & Rapor
| ID | Use Case | Aktor |
|----|----------|-------|
| UC-N01 | Lihat Rekap Nilai | Guru |
| UC-N02 | Input Nilai Batch (Harian/UTS/UAS) | Guru |
| UC-N03 | Generate Rapor | Guru (Wali Kelas) |
| UC-N04 | Publish Rapor | Guru (Wali Kelas) |
| UC-N05 | Download PDF Rapor | Guru |

### 2.12 Audit Log
| ID | Use Case | Aktor |
|----|----------|-------|
| UC-AL01 | Lihat Audit Log | Admin |

---

## 3. Ringkasan

| Modul | Jumlah UC |
|-------|-----------|
| Autentikasi | 2 |
| Dashboard | 2 |
| Manajemen Siswa | 7 |
| Manajemen Guru/Staff | 4 |
| Manajemen Akademik | 4 |
| Jadwal Pelajaran | 3 |
| Pertemuan & Materi | 4 |
| Tugas & Penilaian Tugas | 5 |
| Ujian & Penilaian Ujian | 4 |
| Absensi | 3 |
| Penilaian Akhir & Rapor | 5 |
| Audit Log | 1 |
| **Total** | **44** |
