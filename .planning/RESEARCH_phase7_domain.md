# Phase 7 Domain Research — Indonesian SD School-Year Transition

> Research date: 2026-05-08 | Scope: SDN Kelapadua IV, Kelas 1–6

---

## 1. Calendar

**Academic year:** starts mid-July, ends mid-June the following year.

- **Semester 1:** ~14 July → 19 December
- **Semester 2:** ~5 January → 19 June
- **Penilaian Akhir Tahun (PAT) / Kenaikan Kelas exam:** 2–5 June (±1 week by region)
- **Rapor distribution:** ~19 June
- **New academic year orientation (MPLS):** first week of July
- **Dapodik rombel deadline:** 31 August (operators must complete class setup by this date)

Key implication for FLOZ: the transition window is **mid-June → mid-July**. Admin work (assigning new classes, wali kelas, importing new Grade 1 students) must complete before MPLS week. Dapodik sync deadline is 31 August but school operations start earlier.

---

## 2. Promotion Rules (Kenaikan Kelas)

**Regulatory basis:** Permendikbudristek No. 21 Tahun 2022 (Standar Penilaian Pendidikan); prior reference SE Mendikbud No. 1/2021.

**Standard criteria (Kurikulum 2013 / legacy):**
1. Completes all learning programs across both semesters.
2. No more than **2 mata pelajaran below KKM** (Kriteria Ketuntasan Minimal — school-set passing threshold, typically 60–75).
3. If one semester fails a subject: average of sem 1 + sem 2 must meet average KKM.
4. **Attendance:** must attend ≥ 85% of effective school days (max 15% absence without excuse).
5. Acceptable behavior/character assessment (Penilaian Sikap).

**Kurikulum Merdeka (current):**
- No automatic tinggal kelas by default. Retention is reserved for extreme cases (many competencies unmet, serious behavior issues).
- Decision rests with **satuan pendidikan** (the school), led by kepala sekolah with input from dewan guru (teacher council).
- "Capaian Pembelajaran" (CP) replaces KKM as the benchmark.

**Decision authority:** Rapat Dewan Guru (teacher council meeting), chaired by Kepala Sekolah. Guru kelas submits recommendation; dewan guru ratifies. Documented in Berita Acara Rapat Kenaikan Kelas.

---

## 3. Retention (Tinggal Kelas)

- Under K-13: retention possible if >2 subjects below KKM or attendance <85%.
- Under Kurikulum Merdeka: virtually eliminated as standard practice. Retention only via school-level extraordinary decision.
- **Social stigma:** high. Students retained feel shame; parents often resist. Schools avoid it where possible.
- **Frequency:** rare at SD level (<2% nationally in K-13 era; effectively near-zero under Merdeka Curriculum).
- FLOZ implication: the system must support marking a student as "Mengulang" (repeat grade) even if the UI defaults to promotion. This is a minority path requiring explicit admin confirmation.

---

## 4. Graduation (Kelulusan Kelas 6)

**Exam landscape (2025/2026):**
- **ANBK** (Asesmen Nasional Berbasis Komputer) — diagnostic/mapping tool only; does NOT determine graduation.
- **Ujian Sekolah / Sumatif Akhir Jenjang (SAJ):** school-administered, ~11–23 May 2026. This is the determining assessment.
- **TKA SD** (Tes Kompetensi Akademik): April 2026 — mapping, not graduation gate.
- Graduation is decided by **kepala sekolah** based on SAJ results + full learning portfolio.

**Document flow:**
1. **SK Kelulusan** — school decree listing all graduating students.
2. **SKL (Surat Keterangan Lulus)** — issued immediately after graduation announcement (~late May); used for SMP registration.
3. **Ijazah** — formal certificate; blangko (blank forms) requested from Dinas Pendidikan, printed/signed by kepala sekolah. Issued ~June–July.
4. **Rapor Kelas 6** — final report card, distributed alongside graduation.

**Downstream:** Graduates enroll in SMP (junior high). SKL is the key document for SMP PPDB (Penerimaan Peserta Didik Baru) registration.

FLOZ implication: Kelas 6 students are **removed from active enrollment**, not promoted. They become alumni. The system needs a "Lulus/Tamat" status, not a kenaikan kelas action.

---

## 5. Student Mutation (Mutasi Siswa)

**Pindah Keluar (transfer out):**
- Parent requests transfer → school issues **Surat Keterangan Pindah Sekolah** + copy of rapor.
- Dinas Pendidikan countersigns (1 working day, free).
- Student's enrollment record must be closed with status "Mutasi Keluar" in both school SIS and Dapodik.

**Pindah Masuk (transfer in):**
- Parent submits: surat pindah from origin school, copy of rapor, family documents.
- School issues surat keterangan siap menerima.
- Student assigned to appropriate grade/class.
- Must be entered into Dapodik within the semester.

**Drop out:** extremely rare at SD level. Recorded as "Putus Sekolah" in Dapodik.

**Timing:** transfers can happen mid-year at any time, but schools often discourage mid-semester transfers for administrative reasons. Most common: between academic years (June–July).

**FLOZ edge case:** a student who transferred OUT mid-year must not appear in the kenaikan kelas wizard. A student who transferred IN mid-year should appear but may have an incomplete grade history.

---

## 6. Class Persistence Model

**Indonesian practice:** classes (rombel) are **year-scoped, not persistent rooms**.

- "Kelas 1A 2025/2026" and "Kelas 1A 2026/2027" are entirely separate entities in Dapodik.
- The label "1A" is a human-readable name, not a persistent container.
- Each new academic year: admin creates new rombel for each grade level + section, then populates them.
- Wali kelas (homeroom teacher) is assigned per rombel per year. No automatic carry-over. Common practice: wali kelas follows their class up (e.g., a teacher handles 1A then 2A the next year), but this is discretionary — kepala sekolah decides.

**FLOZ recommendation:** implement **year-scoped rombel**. Each `tahun_ajaran` has its own set of rombel records. Promotion = creating new rombel in the new tahun_ajaran and assigning students + wali kelas. Previous-year rombel become read-only historical records.

---

## 7. Sister-System Patterns (Dapodik et al.)

**Dapodik (government SIS):**
- **Dapodik 2025:** had "Menu Aksi → Naik Kelas" — one-click bulk promotion. All students in the selected rombel auto-advance. Widely used.
- **Dapodik 2026:** menu aksi removed for Merdeka Curriculum schools. Now fully manual:
  1. Create new rombel manually (tingkat, kurikulum, nama, ruang kelas).
  2. Open anggota rombel, select source rombel from previous semester.
  3. Drag all students to new rombel → they get status "Naik Kelas".
  4. Students who repeat: add to rombel first, then change status to "Mengulang."
- **Validation:** Dapodik local validation flags students without a rombel assignment.
- **Deadline pressure:** 31 August cutoff drives urgency. Operators report high anxiety around this process.

**Key pattern observed:** even when bulk promotion existed, exception handling (tinggal kelas students) required individual overrides. FLOZ should mirror this: bulk-promote is default, per-student override is the exception.

---

## 8. Wizard UX Recommendations

Recommended 5-step wizard for FLOZ "Transisi Tahun Ajaran":

**Step 1 — Konfirmasi Tahun Ajaran Baru**
- Admin sets new tahun_ajaran name (e.g., "2026/2027") and semester 1 dates.
- System shows: "Ini akan membuat tahun ajaran baru. Data tahun sebelumnya tidak akan berubah."

**Step 2 — Preview Kenaikan Kelas**
- System shows each active rombel (ex: Kelas 1A, 1B, 2A…) with student count.
- Shows proposed destination class (1A → 2A, etc.).
- Flags students needing review: attendance <85%, incomplete data, mutasi status.
- Kelas 6 shown separately under "Kelulusan."

**Step 3 — Review Per-Siswa Exceptions**
- List of flagged students. Admin marks each: Naik Kelas / Mengulang / Mutasi Keluar / Lulus.
- Default = Naik Kelas (matches Kurikulum Merdeka expectation).

**Step 4 — Atur Rombel Baru**
- System pre-creates rombel with same labels (e.g., "Kelas 2A 2026/2027").
- Admin can rename, merge, or split rombel.
- Admin assigns wali kelas per rombel (no auto-carry: must be explicit selection).
- New Kelas 1 rombel created separately for incoming students (PPDB flow).

**Step 5 — Konfirmasi dan Jalankan**
- Summary: X students promoted, Y marked mengulang, Z graduated, W transferred out.
- "Dry run" preview (no data written yet).
- Explicit "Konfirmasi & Terapkan" button.
- System writes transition, logs audit trail, locks action.

---

## 9. Critical Safety Features

1. **Dry-run preview** — show full impact before committing. Admin must see counts and exceptions before any write occurs.

2. **Undo window** — 48-hour reversal period after transition is applied. Only kepala sekolah or operator role can trigger. After 48h, transition is locked (rapor data for new year may have started accumulating).

3. **Audit trail** — log: who ran the transition, when, from which IP/device, what each student's status change was. Immutable. Accessible to kepala sekolah.

4. **Per-student override** — even after bulk promotion runs, admin can re-open individual student records and change status (e.g., if a student's retention was decided late). Must re-validate rombel assignment.

5. **Historical data lock** — previous year's rapor, absensi, nilai records become read-only after transition completes. No accidental overwrites.

6. **Kelas 6 separation** — system must prevent accidentally "promoting" kelas 6 students to kelas 7 (which doesn't exist in SD). Graduation path is explicitly distinct from promotion path.

---

## 10. Edge Cases List

| Edge Case | Risk | Handling |
|-----------|------|----------|
| Student transferred in mid-year (pindah masuk) with incomplete grade history | Wizard may not know their full performance | Flag for manual review; do not auto-promote without admin confirmation |
| Student transferred out mid-year but still in system | Gets promoted to non-existent enrollment | Must be marked Mutasi Keluar before transition runs; wizard should pre-check |
| Kelas 6 student who failed SAJ (extraordinarily rare) | Must repeat kelas 6 | Requires Mengulang status + kepala sekolah decree; wizard must allow this |
| School reduces rombel count (e.g., 1A+1B merge into single 2A) | Students need redistribution | Wizard must allow admin to manually assign students to destination rombel |
| New wali kelas not yet hired | Rombel exists but has no wali kelas | Allow saving incomplete rombel; flag as "belum ada wali kelas"; block sync to Dapodik until resolved |
| Student with long illness (medical leave) below 85% attendance | May trigger retention flag | Admin must provide keterangan dokter to override; wizard flags but allows override with documentation note |
| Multi-grade class (kelas rangkap) common in small rural SD | 1 teacher handles 2 grades | Rombel model must allow one wali kelas assigned to multiple rombel |
| Student repeating for second consecutive year | Extremely rare; may indicate special needs | System should flag: "Siswa ini sudah pernah mengulang." Escalate to kepala sekolah |
| Transition wizard run twice by mistake | Duplicate rombel, double student assignments | Idempotency check: system should detect if new-year rombel already exist and warn |
| PPDB intake for Kelas 1 not yet complete during transition | Wizard runs before new students enrolled | Kelas 1 rombel creation must support "kosong dulu" (empty) with students added later via PPDB flow |

---

## 11. Recommended Defaults for FLOZ

| Decision | Recommended Default | Rationale |
|----------|--------------------|-----------|
| Promotion status for all students | Naik Kelas | Kurikulum Merdeka default; matches Dapodik expectation |
| Kelas 6 default | Lulus | Graduation is the normal path; retention is extraordinary |
| Wali kelas carry-over | None (must re-assign) | Dapodik 2026 requires explicit assignment; prevents stale data |
| Rombel labels | Same as previous year (e.g., "2A") | Reduces admin confusion; can be renamed |
| Undo window | 48 hours | Balances safety with operational continuity |
| Who can run wizard | Operator + Kepala Sekolah roles only | Prevents accidental trigger by regular teacher |
| Dry-run default | Always show preview first | No writes without admin seeing full impact summary |
| Students to flag for review | Attendance <85%, status=Mutasi, status=Mengulang in prior year | Conservative: flag rather than silently promote |

---

## Research Sources

- [Kalender Pendidikan 2025/2026 — Brain Academy](https://www.brainacademy.id/blog/kalender-pendidikan-sd-smp-sma)
- [Kriteria Kenaikan Kelas SD — PusatDapodik](https://pusatdapodik.com/kriteria-kenaikan-kelas-sd-smp-sma-dan-smk-yang-wajib-dipahami-guru/)
- [Permendikbudristek No. 21/2022 — Pojok Satu](https://www.pojoksatu.id/edugov/1085968363/aturan-baru-kriteria-kenaikan-kelas-dan-kelulusan-siswa-ini-standar-penilian-pendidikan-berdasarkan-permendikbudristek-21)
- [Kurikulum Merdeka: Tidak Naik Kelas — Kompas.com](https://www.kompas.com/edu/read/2024/04/02/152936471/sistem-tidak-ada-siswa-tinggal-kelas-di-kurikulum-merdeka-dinilai-turunkan-motivasi-belajar)
- [Cara Membuat Rombel dan Naik Kelas Dapodik 2026 — Teknobie.id](https://tekno.utamapos.com/cara-membuat-rombel-dan-menaikkan-kelas-di-dapodik-2026/)
- [Dapodik 2026: Rombel Hilang, Menu Aksi Dihapus — emka.web.id](https://emka.web.id/2026/01/rombel-hilang-di-dapodik-2026-b-tenang-gini-cara-mudah-mengatasinya-tanpa-menu-aksi.html)
- [Mutasi Siswa SD — Disdik Natuna](https://disdikbud.natunakab.go.id/mutasi-siswa/)
- [Kelulusan Kelas 6 / SAJ 2025/2026 — Kelingan.id](https://kelingan.id/jadwal-ujian-sekolah-2026-sd-smp-dan-sma-berdasarkan-kalender-pendidikan/)
- [SKL dan Ijazah 2026 — Mastiokdr.com](https://mastiokdr.com/surat-edaran-pengumuman-kelulusan-penerbitan-skl-ijazah-dan-transkrip-nilai-tahun-2026-bagi-murid-lulusan-tahun-pelajaran-2025-2026)
- [TKA SD 2026 bukan penentu kelulusan — Kemendikdasmen](https://www.kemendikdasmen.go.id/siaran-pers/14544-tka-sd-dan-smp-2026-digelar-april-kemendikdasmen-pemetaan-mu)
