import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/student/assignments/domain/entities/assignment.dart';
import 'package:floz_mobile/features/student/assignments/domain/repositories/assignment_repository.dart';
import 'package:floz_mobile/features/student/assignments/presentation/screens/assignments_list_screen.dart';
import 'package:floz_mobile/features/student/assignments/providers/assignment_providers.dart';

class _MockRepo extends Mock implements AssignmentRepository {}

const _fixture = [
  AssignmentSummary(
    id: 1,
    title: 'Soal Latihan Bab 3',
    description: 'Kerjakan soal latihan',
    subject: 'Matematika',
    teacher: 'Bu Siti',
    type: 'quiz',
  ),
  AssignmentSummary(
    id: 2,
    title: 'Karangan Bebas',
    description: 'Tulis karangan',
    subject: 'Bahasa Indonesia',
    teacher: 'Pak Budi',
    type: 'essay',
  ),
];

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        assignmentRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows assignment list with title and subject on data',
      (tester) async {
    when(
      () => repo.fetchList(
        status: any(named: 'status'),
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer((_) async => const Success(_fixture));

    await tester.pumpWidget(wrap(const AssignmentsListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Soal Latihan Bab 3'), findsOneWidget);
    expect(find.text('Matematika'), findsOneWidget);
    expect(find.text('Karangan Bebas'), findsOneWidget);
    expect(find.text('Bahasa Indonesia'), findsOneWidget);
  });

  testWidgets('shows empty state when no assignments', (tester) async {
    when(
      () => repo.fetchList(
        status: any(named: 'status'),
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer((_) async => const Success(<AssignmentSummary>[]));

    await tester.pumpWidget(wrap(const AssignmentsListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada tugas'), findsOneWidget);
  });

  testWidgets('shows error state with retry button on failure', (tester) async {
    when(
      () => repo.fetchList(
        status: any(named: 'status'),
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer(
        (_) async => const FailureResult(NetworkFailure('Tidak ada koneksi')));

    await tester.pumpWidget(wrap(const AssignmentsListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada koneksi'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
