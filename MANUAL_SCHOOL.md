# Panduan Administrator Sekolah

Panduan ini untuk **Admin Sekolah** atau **Operator** yang mengelola data SDN Kelapadua IV di FLOZ LMS.

## Akses Aplikasi
1. Buka URL aplikasi sekolah (default lokal: `http://localhost:8000`).
2. Login dengan email dan password admin sekolah.

## Fitur Utama

### 1. Manajemen Data Siswa
- **Tambah Manual**: Menu **Data Siswa** > **Tambah Siswa**.
- **Import Excel**:
  - Klik **Import Excel**.
  - Download Template CSV.
  - Isi data siswa sesuai format.
  - Upload kembali file tersebut.

### 2. Manajemen Kelas
- Pastikan kelas sudah dibuat sebelum menginput siswa.

### 3. Input Nilai
- Masuk ke menu **Nilai**.
- Pilih Kelas dan Mata Pelajaran.
- Input nilai Harian, UTS, dan UAS.
- Sistem otomatis menghitung Nilai Akhir.

### 4. Cetak Rapor
- Masuk ke menu **Rapor**.
- Pilih tombol **Generate Rapor** untuk membuat rapor baru (misal akhir semester).
- Klik icon **PDF** pada siswa untuk mendownload rapor.
- Format rapor mengikuti jenjang yang diset di `config/school.php` (default: SD).
