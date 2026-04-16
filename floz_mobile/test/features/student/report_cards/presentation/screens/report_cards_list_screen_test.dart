import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/student/report_cards/domain/entities/report_card.dart';
import 'package:floz_mobile/features/student/report_cards/domain/repositories/report_card_repository.dart';
import 'package:floz_mobile/features/student/report_cards/presentation/screens/report_cards_list_screen.dart';
import 'package:floz_mobile/features/student/report_cards/providers/report_card_providers.dart';

class _MockRepo extends Mock implements ReportCardRepository {}

const _fixture = [
  ReportCardSummary(
    id: 1,
    semesterName: 'Semester 1',
    academicYear: '2024/2025',
    averageScore: 87.5,
    rank: 3,
  ),
  ReportCardSummary(
    id: 2,
    semesterName: 'Semester 2',
    academicYear: '2023/2024',
    averageScore: 82.0,
  ),
];

void main() {
  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [reportCardRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows list with semester and average score on data', (tester) async {
    when(() => repo.fetchList(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(_fixture));

    await tester.pumpWidget(wrap(const ReportCardsListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Semester 1'), findsOneWidget);
    expect(find.text('87.5'), findsOneWidget);
    expect(find.text('Semester 2'), findsOneWidget);
    expect(find.text('82.0'), findsOneWidget);
  });

  testWidgets('shows empty state when list is empty', (tester) async {
    when(() => repo.fetchList(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(<ReportCardSummary>[]));

    await tester.pumpWidget(wrap(const ReportCardsListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada rapor'), findsOneWidget);
  });

  testWidgets('shows error with retry on failure', (tester) async {
    when(() => repo.fetchList(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const FailureResult(NetworkFailure('koneksi gagal')));

    await tester.pumpWidget(wrap(const ReportCardsListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('koneksi gagal'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
