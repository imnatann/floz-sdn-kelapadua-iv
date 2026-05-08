# Completed: Student Assignment Submission

**Date:** 2026-05-08
**Branch:** chore/remove-tenant-leftovers

---

## Tasks Completed

| # | Task | Status |
|---|------|--------|
| 1 | Backend — FormRequest + Route | Done (merged with Task 2) |
| 2 | Backend — Service business logic | Done |
| 3 | Mobile — Datasource + Repository + Domain interface | Done |
| 4 | Mobile — Provider + Submit Screen UI | Done |
| 5 | Manual curl smoke test + final regression | Done |

---

## Tests Added (all passing)

### Backend (Pest)
9 new tests in `src/tests/Feature/Api/V1/Student/AssignmentSubmissionTest.php`:
- `it rejects unauthenticated submit`
- `it rejects teacher role on submit`
- `it returns 422 when both answer_text and answer_link are missing`
- `it returns 422 when answer_link is not a URL`
- `it returns 404 when assignment not in student class`
- `it creates submission and returns 201 with correct structure`
- `it returns status submitted (not graded) immediately after submit`
- `it flags is_late true when submitted after due_date`
- `it returns 409 when student submits twice`

### Mobile (Flutter/mocktail)
6 new tests:

**Datasource** (`test/features/student/assignments/data/datasources/assignment_submission_datasource_test.dart`):
- `submitAssignment posts to correct endpoint and returns SubmissionResult`
- `submitAssignment with both text and link succeeds`

**Widget** (`test/features/student/assignments/presentation/screens/assignment_submit_screen_test.dart`):
- `shows text field, link field, and submit button`
- `shows error snackbar when both fields empty`
- `calls repository submit on success and pops`
- `shows failure snackbar on server error`

---

## Commits

| SHA | Message |
|-----|---------|
| `913d00d` | `feat(api/v1): implement student assignment submission endpoint` |
| `ce11236` | `feat(mobile/assignments): data layer for submission POST` |
| `5c42e25` | `feat(mobile/assignments): submit screen + detail screen integration` |

---

## Regression Status

- **Pest:** 240 passed, 0 failed (final run)
- **Flutter test:** 122 passed, 0 failed
- **Flutter analyze:** 2 pre-existing warnings only (not in files touched)

---

## Manual Curl Smoke Test

```
POST /api/v1/student/assignments/1/submit
Authorization: Bearer 48|hmgxKJosBB5HCKvUQnfPA7B1uv4pxF3TsxBhAdmu60c3b5c0

Body: {"answer_text":"Test answer from curl","answer_link":"https://example.com"}
Response 201: {"data":{"submission_id":1,"status":"submitted","submitted_at":"2026-05-08T07:03:31.000000Z","is_late":true}}

Duplicate:
Body: {"answer_text":"Second attempt"}
Response 409: {"message":"Tugas sudah dikumpulkan.","code":"HTTP_ERROR"}
```

---

## Deviations

See `DEVIATIONS_assignment_submission.md` for full details.

1. **D1** — Used mocktail (not mockito) — project standard; equivalent tests.
2. **D2** — Tasks 1+2 committed together (stub would have broken test run).
3. **D3** — Pre-existing AcademicYear test failures confirmed unrelated.
