# Panduan Administrator Platform (FLOZ LMS)

Panduan ini ditujukan untuk **Super Admin** yang mengelola seluruh platform SaaS.

## Akses Dashboard
1. Buka URL: `http://admin.floz.id:8000` (Local) atau domain production.
2. Login dengan akun super admin.

## Fitur Utama

### 1. Manajemen Tenant (Sekolah)
- **Membuat Tenant Baru**:
  - Masuk ke menu **Tenants**.
  - Klik **Tambah Tenant**.
  - Isi nama sekolah, domain (subdomain), dan pilih paket langganan.
  - Klik **Simpan**. Database sekolah akan otomatis dibuat.

- **Mengelola Tenant**:
  - Anda bisa melihat status langganan, jumlah siswa, dan guru.
  - Untuk menonaktifkan sekolah (misal menunggak pembayaran), gunakan tombol **Suspend**.

### 2. Mengelola Domain
- Pastikan subdomain yang didaftarkan sudah diarahkan ke IP server (A Record) atau CNAME.

### 3. Troubleshooting
- Jika tenant gagal dibuat, cek log di server. Pastikan database user memiliki hak akses `CREATE DATABASE`.
