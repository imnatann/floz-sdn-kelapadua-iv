import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/student/grades/domain/entities/student_grades.dart';
import 'package:floz_mobile/features/student/grades/domain/repositories/grade_repository.dart';
import 'package:floz_mobile/features/student/grades/presentation/screens/grades_list_screen.dart';
import 'package:floz_mobile/features/student/grades/providers/grade_providers.dart';

class _MockRepo extends Mock implements GradeRepository {}

const _fixture = [
  SubjectGradeSummary(subjectId: 1, subjectName: 'Matematika', average: 85, gradeCount: 2, kkm: 75),
  SubjectGradeSummary(subjectId: 2, subjectName: 'Bahasa Indonesia', average: 70, gradeCount: 1, kkm: 75),
];

void main() {
  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [gradeRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows subject list with scores', (tester) async {
    when(() => repo.fetchList(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(_fixture));

    await tester.pumpWidget(wrap(const GradesListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Matematika'), findsOneWidget);
    expect(find.text('85'), findsOneWidget);
    expect(find.text('Bahasa Indonesia'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
  });

  testWidgets('shows empty state', (tester) async {
    when(() => repo.fetchList(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(<SubjectGradeSummary>[]));

    await tester.pumpWidget(wrap(const GradesListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada nilai'), findsOneWidget);
  });

  testWidgets('shows error with retry', (tester) async {
    when(() => repo.fetchList(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const FailureResult(NetworkFailure('offline')));

    await tester.pumpWidget(wrap(const GradesListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('offline'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
