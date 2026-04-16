# Phase 5 — P2.4 Student Report Cards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `Rapor` tab placeholder with working report card view — 3 backend V1 endpoints (list + detail + pdf), mobile feature with list→detail+PDF, Hive cache.

**Architecture:** Same vertical-slice pattern. Backend migrates `Api\MobileReportCardController` → `Api\V1`. Mobile rebuilds `features/student/report_cards` with clean arch. List shows published rapors; detail shows full breakdown; PDF button opens URL in browser/viewer.

**Tech Stack:** Laravel 12, Pest, Flutter 3.11, Riverpod, Dio, Hive, url_launcher, mocktail

---

## Key Decisions

1. **Endpoints:** `GET /api/v1/student/report-cards` (list published only), `GET /api/v1/student/report-cards/{id}` (detail), `GET /api/v1/student/report-cards/{id}/pdf` (pdf URL). All `role:student`.
2. **List shape:** `{data: [{id, semester_name, academic_year, average_score, rank, published_at}]}`
3. **Detail shape:** `{data: {id, semester_name, academic_year, class_name, average_score, total_score, rank, attendance_present/sick/permit/absent, achievements, notes, behavior_notes, homeroom_comment, principal_comment, pdf_url, published_at}}`
4. **PDF:** endpoint returns `{data: {url: "..."}}`. Mobile opens URL via `url_launcher` (already in pubspec). No in-app PDF viewer for now — just launch external browser/system viewer.
5. **Cache TTL:** 1 day for list. Detail always fresh.
6. **Only shows `status=published` report cards** — draft rapors hidden from student.
7. **ReportCardFactory** already exists from P1 T19.

---

## Tasks (7 total, same structure as P2.3)

### Task 1: ReportCardService TDD (test + impl + commit)
- Service: `listForStudent(User)` returns list of published report cards, `detailForStudent(User, int $id)` returns full breakdown, `pdfUrlForStudent(User, int $id)` returns URL string or null
- Test: 5 cases (list happy, list empty, detail happy, detail not found, pdf url)

### Task 2: V1 controller + feature test + route + delete legacy (combined)
- Controller: 3 methods (index, show, pdf)
- Feature test: 5 cases (list, detail, pdf, 401, 403)
- Route: `/student/report-cards`, `/student/report-cards/{id}`, `/student/report-cards/{id}/pdf`
- Delete: `Api\MobileReportCardController`

### Task 3: Delete pre-P1 broken mobile report_cards code

### Task 4: Mobile domain + DTO + datasource + endpoint constants

### Task 5: Repository impl with cache + test (TDD)
- Cache list (1 day TTL, key 'list'), detail + pdf always fresh
- 7 tests

### Task 6: Providers + ReportCardsListScreen + ReportCardDetailScreen + widget test + wire to shell
- List screen: semester badge + average score + rank + date
- Detail screen: attendance section + achievements + notes + comments + PDF download button
- Wire into StudentShell tab 3 (Rapor)

### Task 7: Integration verify + tag `p2.4-report-cards-complete`

---

## Notes for executing agent

- **ReportCard model uses `status` enum (`draft`/`published`)** — NOT `is_published` boolean. Filter by `status = 'published'`.
- **ReportCard relations:** `semester()` → Semester model, `schoolClass()` → SchoolClass model, `student()` → Student model. All confirmed in P1.
- **Semester has `academicYear()` relation** — used for displaying academic year name.
- **PDF opening:** use `url_launcher` package's `launchUrl(Uri.parse(pdfUrl))` to open PDF in system browser. Package already in pubspec at `^6.3.2`. Do NOT use `flutter_pdfview` for now — URL might be external.
- **Same safety rules:** NEVER migrate. Tests use RefreshDatabase. Feature tests `uses(RefreshDatabase::class)`. Unit tests `uses(Tests\TestCase::class, RefreshDatabase::class)`.
- **ReportCardFactory** already exists and includes: student_id, class_id, semester_id, report_type, status (default 'draft'), attendance fields (default 0), pdf_url (nullable).
