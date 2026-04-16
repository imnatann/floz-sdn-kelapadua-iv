import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/teacher/classes/domain/entities/teaching_assignment_summary.dart';
import 'package:floz_mobile/features/teacher/classes/domain/repositories/teacher_class_repository.dart';
import 'package:floz_mobile/features/teacher/classes/presentation/screens/classes_list_screen.dart';
import 'package:floz_mobile/features/teacher/classes/providers/teacher_class_providers.dart';

class _MockRepo extends Mock implements TeacherClassRepository {}

const _fixture = [
  TeachingAssignmentSummary(
    id: 1,
    subjectName: 'Matematika',
    className: 'Kelas 6A',
    academicYear: '2024/2025',
    studentCount: 28,
    meetingCount: 16,
  ),
  TeachingAssignmentSummary(
    id: 2,
    subjectName: 'Bahasa Indonesia',
    className: 'Kelas 5B',
    academicYear: '2024/2025',
    studentCount: 30,
    meetingCount: 14,
  ),
];

void main() {
  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        teacherClassRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows list with subject name and class name on data',
      (tester) async {
    when(() => repo.fetchList())
        .thenAnswer((_) async => const Success(_fixture));

    await tester.pumpWidget(wrap(const ClassesListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Matematika'), findsOneWidget);
    expect(find.text('Kelas 6A'), findsOneWidget);
    expect(find.text('Bahasa Indonesia'), findsOneWidget);
    expect(find.text('Kelas 5B'), findsOneWidget);
  });

  testWidgets('shows empty state when list is empty', (tester) async {
    when(() => repo.fetchList()).thenAnswer(
        (_) async => const Success(<TeachingAssignmentSummary>[]));

    await tester.pumpWidget(wrap(const ClassesListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada kelas yang diampu'), findsOneWidget);
  });

  testWidgets('shows error state with retry on failure', (tester) async {
    when(() => repo.fetchList()).thenAnswer(
        (_) async => const FailureResult(NetworkFailure('Tidak ada koneksi')));

    await tester.pumpWidget(wrap(const ClassesListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada koneksi'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
