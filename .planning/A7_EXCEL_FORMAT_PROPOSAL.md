# A7 — Excel Attendance Recap: Format Proposal

## 1. Current State

**File:** `src/app/Exports/AttendanceRecapExport.php` + `src/app/Exports/Sheets/ClassAttendanceSheet.php`

**Structure:**
- One Excel workbook per export.
- One sheet per active class in the selected semester, tab named after the class (truncated to 31 chars).
- Each sheet has a single header row (bold) followed by one data row per active student.

**Columns (left to right):**

| Col | Heading       | Source                                  |
|-----|---------------|-----------------------------------------|
| A   | No            | Row index (1-based)                     |
| B   | NIS           | `students.nis`                          |
| C   | Nama Siswa    | `students.name`                         |
| D   | Hadir         | COUNT(status='present') per semester    |
| E   | Sakit         | COUNT(status='sick')                    |
| F   | Izin          | COUNT(status='permit')                  |
| G   | Alpha         | COUNT(status='absent')                  |
| H   | % Kehadiran   | hadir/(hadir+sakit+izin+alpha)*100, 1dp |

**Styling:** Header row bold. No borders, no merged cells, no color, no totals row.

**Scope:** Aggregate per student per semester (no per-meeting breakdown in rows).

---

## 2. Auditor's Expected Format (from image1.jpeg)

The screenshot shows an Excel file with:

- **Sheet tabs:** `mapel 1`, `mapel 2`, `dst` (i.e., one sheet per **subject/mapel**, not per class)
- **Row 1:** Column headers — B1: `nilai tugas 1`, C1: `nilai tugas 2`, D1: `dst` (these are task/meeting columns, expanding rightward)
- **Column A:** Student names (`nama`) — one student per row, starting at row 2
- **Orientation:** Rows = students, Columns = individual meetings/tasks (wide/pivoted layout)
- The image appears to be a **grade** or per-meeting attendance sheet, not an aggregate recap

**Inferred auditor structure:**

| Row\Col | A         | B              | C              | D    | ... |
|---------|-----------|----------------|----------------|------|-----|
| 1       | (blank)   | nilai tugas 1  | nilai tugas 2  | dst  | ... |
| 2       | nama siswa| [value]        | [value]        |      |     |
| 3       | nama siswa| ...            |                |      |     |

- Each column after A = one meeting/pertemuan
- Each row = one student
- Sheet = per subject (mapel)

---

## 3. Side-by-Side Diff

| Dimension        | Current Export                        | Auditor Format                          |
|------------------|---------------------------------------|-----------------------------------------|
| Sheet tab        | Per class (e.g. "Kelas 4A")           | Per subject/mapel                       |
| Row content      | One student = one row (aggregate)     | One student = one row (per-meeting cols)|
| Column layout    | Fixed 8 cols: No,NIS,Nama,H,S,I,A,%  | Dynamic: Nama + N meeting columns       |
| Meeting detail   | None (totals only)                    | One column per meeting/task             |
| Data type        | Attendance counts + % attendance      | Possibly scores (nilai) or H/S/I/A per meeting |
| NIS column       | Present (col B)                       | Not visible in screenshot               |
| % Kehadiran col  | Present (col H)                       | Not visible in screenshot               |
| Totals row       | None                                  | Not visible, unclear                    |
| Font             | Default                               | Times New Roman, size 11               |
| Borders/styling  | Bold header only                      | Appears plain (no visible borders)      |

**Key structural conflict:** Current = wide aggregate (8 fixed cols). Auditor = tall pivoted (N dynamic cols per meeting).

---

## 4. Proposed Changes (5 concrete)

### P1 — Pivot to per-meeting columns
Replace the fixed H/S/I/A aggregate columns with one column per `meeting_number` recorded for the class+semester. Each cell = status value for that student on that meeting (H/S/I/A or blank if not recorded). Add totals columns (H total, S total, I total, A total, %) at the far right.

**Impact:** Breaking structural change. Requires `WithColumnWidths` and `WithEvents` concerns. Sheet width grows proportionally to meeting count.

### P2 — Sheet tab = per subject (mapel)
Change `AttendanceRecapExport::sheets()` to group by `TeachingAssignment` (subject × class combination) rather than by class. Tab name: `{subject_name} - {class_name}`.

**Impact:** Moderate refactor. The number of sheets multiplies (classes × subjects taught). May need sheet-count guard for large schools.

### P3 — Add class/semester header rows above the data
Insert 3 rows above the student list: school name, class name + semester, export date. Use merged cells A1:lastCol. Matches common Dinas format convention.

**Impact:** Low risk; add `WithTitle` and `AfterSheet` event to inject header rows.

### P4 — Use Times New Roman 11pt font
The auditor's screenshot uses Times New Roman 11. Apply globally via `styles()` on the worksheet default font style.

**Impact:** Cosmetic only. Low risk.

### P5 — Add NIS in column A, name in column B (swap order)
Auditor shows name in column A. Current has No/NIS/Nama. Align to: A=Nama, B=NIS (or drop NIS if auditor format omits it). Confirm with school.

**Impact:** Minor column reorder. No logic change.

---

## 5. Estimated Effort + Risk

| Change | Effort  | Risk  | Notes                                              |
|--------|---------|-------|----------------------------------------------------|
| P1     | Large   | High  | Pivot completely changes data shape; needs testing |
| P2     | Medium  | Med   | Route change + multiple sheets; check memory       |
| P3     | Small   | Low   | Pure formatting                                    |
| P4     | Trivial | Low   | One font setting                                   |
| P5     | Small   | Low   | Column reorder only                                |

Total estimate (all 5): ~3-4 hours backend + 1 hour regression testing.

---

## 6. Open Questions for User

1. **Is the auditor image showing attendance or grades?** The column headers say `nilai tugas` (task scores), not H/S/I/A. If the auditor wants **grades** per meeting in this sheet (not attendance status), the entire export approach differs. This is the most critical question.

2. **Is NIS required in the auditor format?** It is not visible in the screenshot. Confirm whether to keep it (col B) or drop it.

3. **One sheet per subject, or one sheet per class?** Current = per class. Auditor tabs show `mapel 1 / mapel 2`. Does the school want separate attendance per subject, or one consolidated attendance sheet per class?

4. **What are the exact column headers for meeting columns?** The screenshot shows `nilai tugas 1`, `nilai tugas 2`. Should attendance columns be labeled `Pertemuan 1`, `Tgl 2024-08-01`, or something else?

5. **Is there a Dinas-issued official template file?** If yes, please share the `.xlsx` file directly — the photo is low-resolution and some columns are cut off. The official template eliminates all ambiguity.
