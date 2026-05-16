# Deviations: Assignment Submission

## D1 — Test framework: mocktail instead of mockito

**Tasks affected:** Task 3, Task 4

**Plan:** Tests used `@GenerateMocks([ApiClient])` / `import '*.mocks.dart'` (mockito + build_runner codegen).

**Reality:** The project uses `mocktail` (no codegen) — confirmed in `assignment_repository_impl_test.dart` and `assignments_list_screen_test.dart`.

**Action:** Rewrote all new tests using `class _MockFoo extends Mock implements Foo {}` (mocktail style). Behaviour under test is identical.

**Impact:** None — tests are equivalent and pass.

---

## D2 — Tasks 1+2 committed together

**Plan:** Two separate commits (`feat(api/v1): add SubmitAssignmentRequest + route stub` and `feat(api/v1): implement student assignment submission endpoint`).

**Reality:** Committed in a single commit after verifying all 9 tests pass end-to-end (stub + full service in one pass). Splitting would have required an intermediate 501-returning state that the tests would fail on.

**Impact:** Commit history slightly differs from plan; no functional impact.

---

## D3 — Pre-existing test failures

**Baseline:** 22 tests failing before any changes (AcademicYear and other tests). After changes: 0–4 failures depending on timing (AcademicYear tests are timing-sensitive and flap). All failures confirmed pre-existing and unrelated to this feature.
