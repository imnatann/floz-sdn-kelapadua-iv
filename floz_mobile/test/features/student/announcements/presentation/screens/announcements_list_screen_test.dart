import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/student/announcements/domain/entities/announcement.dart';
import 'package:floz_mobile/features/student/announcements/domain/repositories/announcement_repository.dart';
import 'package:floz_mobile/features/student/announcements/presentation/screens/announcements_list_screen.dart';
import 'package:floz_mobile/features/student/announcements/providers/announcement_providers.dart';

class _MockRepo extends Mock implements AnnouncementRepository {}

const _fixture = [
  AnnouncementSummary(
    id: 1,
    title: 'Libur Hari Raya',
    excerpt: 'Sekolah libur pada tanggal 10-12 April',
    type: 'info',
    isPinned: false,
  ),
  AnnouncementSummary(
    id: 2,
    title: 'Pengumuman Ujian',
    excerpt: 'Ujian semester akan dilaksanakan bulan depan',
    type: 'warning',
    isPinned: true,
  ),
];

void main() {
  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [announcementRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows list with title + excerpt on data', (tester) async {
    when(() => repo.fetchList(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(_fixture));

    await tester.pumpWidget(wrap(const AnnouncementsListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Libur Hari Raya'), findsOneWidget);
    expect(find.text('Sekolah libur pada tanggal 10-12 April'), findsOneWidget);
    expect(find.text('Pengumuman Ujian'), findsOneWidget);
    expect(find.text('Ujian semester akan dilaksanakan bulan depan'), findsOneWidget);
  });

  testWidgets('shows empty state', (tester) async {
    when(() => repo.fetchList(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(<AnnouncementSummary>[]));

    await tester.pumpWidget(wrap(const AnnouncementsListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada pengumuman'), findsOneWidget);
  });

  testWidgets('shows error with retry', (tester) async {
    when(() => repo.fetchList(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const FailureResult(NetworkFailure('offline')));

    await tester.pumpWidget(wrap(const AnnouncementsListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('offline'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
