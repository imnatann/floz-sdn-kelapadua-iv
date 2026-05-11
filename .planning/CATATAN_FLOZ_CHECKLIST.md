# Catatan FLOZ — Checklist Perbaikan

Sumber: `~/Downloads/Catatan floz.docx` (text + 3 screenshots, 13MB)

## Daftar Keluhan (11 items)

| # | Keluhan | Kategori | Effort |
|---|---------|----------|--------|
| 1 | Admin gabisa bikin jadwal untuk kelas baru | Bug | S |
| 2 | Ulangan harian bisa lebih dari 1 (saat ini hanya 1) | Feature | M |
| 3 | Buat Ulangan harian harusnya dibuat fitur seperti buat tugas (UH baru bisa ditambah) | Feature | M |
| 4 | Guru harusnya bisa liat detail nilai siswa di mata pelajaran dia | Feature | M |
| 5 | Data siswa paling bawah (layout issue di salah satu page) | UI/UX | S |
| 6 | Siswa/teacher/admin belum bisa ganti password — selalu default | Feature | S-M |
| 7 | Fitur input nilai untuk guru tidak berfungsi. Saran: per-student detail nilai tugas+ulangan, bisa diubah, terkoneksi dengan nama tugas | Bug + Feature | L |
| 8 | Tanggal pertemuan (display/input issue) | Bug | S |
| 9 | Ranking ga ngurut (sort logic bug) | Bug | S |
| 10 | Admin bikin kelas baru → kelas baru tidak muncul di edit mata pelajaran | Bug | S |
| 11 | Setiap mata pelajaran harusnya punya guru pengampu spesifik per kelas (no checkbox, satu mapel ke satu guru per kelas) | Architectural change | L |

## Prioritisasi Saran

**Quick wins (S, dikerjakan dulu):**
- #1, #5, #8, #9, #10

**Medium fixes (M, sesi berikutnya):**
- #2, #3 (UH multiple — bisa di-bundle jadi 1 fitur)
- #4 (Guru lihat detail nilai)
- #6 (Password change — auth feature)

**Big design decisions (L, butuh diskusi):**
- #7 (Total redesign grade input — connect ke task name)
- #11 (Mapel-guru linkage architecture — affects DB schema + workflows)
