import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/teacher/grades_input/domain/entities/grade_roster.dart';
import 'package:floz_mobile/features/teacher/grades_input/domain/repositories/grade_input_repository.dart';
import 'package:floz_mobile/features/teacher/grades_input/presentation/screens/grade_input_screen.dart';
import 'package:floz_mobile/features/teacher/grades_input/providers/grade_input_providers.dart';

class _MockRepo extends Mock implements GradeInputRepository {}

const _roster = GradeRoster(
  taId: 1,
  subjectName: 'Matematika',
  className: 'Kelas 6A',
  students: [
    StudentGrade(id: 1, name: 'Ahmad Fauzi', nis: '24001'),
    StudentGrade(id: 2, name: 'Budi Santoso', nis: '24002', midTest: 75.0),
  ],
);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    // Default stub for submitGrades to avoid MissingStubError
    when(() => repo.submitGrades(any(), any()))
        .thenAnswer((_) async => const Success(_roster));
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        gradeInputRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(home: child),
    );
  }

  const screen = GradeInputScreen(
    taId: 1,
    subjectName: 'Matematika',
    className: 'Kelas 6A',
  );

  testWidgets('shows student list with score inputs on data', (tester) async {
    when(() => repo.fetchRoster(any()))
        .thenAnswer((_) async => const Success(_roster));

    await tester.pumpWidget(wrap(screen));
    await tester.pumpAndSettle();

    // Both student names appear
    expect(find.text('Ahmad Fauzi'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);

    // NIS values appear
    expect(find.text('24001'), findsOneWidget);
    expect(find.text('24002'), findsOneWidget);

    // AppBar shows subject + class name
    expect(find.text('Matematika'), findsOneWidget);
    expect(find.text('Kelas 6A'), findsOneWidget);

    // Tab chips present
    expect(find.text('Harian'), findsOneWidget);
    expect(find.text('UTS'), findsOneWidget);
    expect(find.text('UAS'), findsOneWidget);
  });

  testWidgets('shows error state on roster load failure', (tester) async {
    when(() => repo.fetchRoster(any())).thenAnswer(
      (_) async =>
          const FailureResult(NetworkFailure('Tidak ada koneksi internet')),
    );

    await tester.pumpWidget(wrap(screen));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada koneksi internet'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('submit button exists and is tappable when data loaded',
      (tester) async {
    when(() => repo.fetchRoster(any()))
        .thenAnswer((_) async => const Success(_roster));

    await tester.pumpWidget(wrap(screen));
    await tester.pumpAndSettle();

    // Submit button exists
    final buttonFinder = find.widgetWithText(ElevatedButton, 'Simpan Nilai');
    expect(buttonFinder, findsOneWidget);

    // Button is tappable (onPressed is not null)
    final button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNotNull);

    // Tap it — should not throw
    await tester.tap(buttonFinder);
    await tester.pump();
  });
}
