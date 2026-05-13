# Catatan FLOZ (Audit Round 2) — Checklist Perbaikan

Sumber: `~/Downloads/Catatan Floz (1).docx` (text + 1 screenshot Excel format)

## Daftar Keluhan Auditor (8 items)

| # | Keluhan | Severity | Effort |
|---|---------|----------|--------|
| A1 | Jadwal yang sudah diinput tidak bisa dihapus/diedit (perlu untuk reschedule) | High (functional gap) | M |
| A2 | Fitur reset password belum ada (ambiguous — current state: user-self change ada di `14bbd54`; auditor mungkin maksud admin-reset-untuk-user, atau forgot-password) | Medium | M |
| A3 | Daftar tugas/nilai harus bisa filter per mata pelajaran. **Wali kelas tidak boleh ubah nilai kecuali mapel yang dia ajar** | **High — auth** | M |
| A4 | Guru random bisa CRUD tugas/ulangan di pelajaran yang tidak dia ajar | **CRITICAL — auth** | M |
| A5 | Siswa masih bisa input nilai | **CRITICAL — auth** | S |
| A6 | Absen harusnya per mapel (per meeting/TA), bukan per hari. Hanya guru pengampu mapel yang absen mapelnya | Architectural | L |
| A7 | Excel export nilai per mapel — format spesifik (lihat image1). Guru view mapelnya saja, wali view semua | Feature | M |
| A8 | Yang bisa input absen di flow web = hanya wali kelas (per-class attendance) | High — auth | S |

## Catatan disambiguasi

- **#A6 vs #A8**: Tidak kontradiksi. A6 = mobile/per-TA flow (guru pengampu absen pertemuan mapelnya). A8 = web/per-class flow (hanya wali kelas yang authorized utk daily class attendance).
- **#A2 vs commit `14bbd54`**: Phase 8.1 sudah implement password change (self). Auditor mungkin maksud: admin-reset-password-untuk-other-user, atau forgot-password email flow. Perlu konfirmasi.
- **#A7 Excel format**: Image1 (4.9MB) menunjukkan format kolom spesifik. Saat ini Excel export sudah ada via `/analytics/export/attendance` (Phase 11), tapi konten dan kolom mungkin tidak match dengan format yang auditor minta.

## Priority Fix Order

**🚨 CRITICAL (security/auth, fix immediately):**
- A5 — siswa bisa input nilai → 403 enforcement
- A4 — guru CRUD tugas mapel orang lain → policy check teacher_id matches TeachingAssignment

**⚠️ HIGH (auth + UX gaps):**
- A3 — wali kelas grade modification gating
- A1 — schedule edit/delete (functional gap)
- A8 — web attendance scoped to wali kelas only

**📋 MEDIUM/PLAN:**
- A2 — clarify scope (admin-reset vs forgot-password)
- A6 — architectural shift to per-mapel attendance (already done backend mobile; web reshape needed)
- A7 — Excel template match auditor's format
