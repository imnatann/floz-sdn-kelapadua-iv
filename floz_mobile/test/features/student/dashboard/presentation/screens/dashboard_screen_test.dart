import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/student/dashboard/domain/entities/dashboard.dart';
import 'package:floz_mobile/features/student/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:floz_mobile/features/student/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:floz_mobile/features/student/dashboard/providers/dashboard_providers.dart';

class _MockRepo extends Mock implements DashboardRepository {}

const _fixture = StudentDashboard(
  student: StudentDashboardProfile(
    id: 1,
    name: 'Ahmad',
    className: '4A',
    homeroomTeacher: 'Bu Ani',
  ),
  stats: DashboardStats(attendancePercentage: 90),
  todaysSchedules: [],
  recentAnnouncements: [],
);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [dashboardRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows loading then data on happy path', (tester) async {
    when(() => repo.fetch(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(_fixture));

    await tester.pumpWidget(wrap(const DashboardScreen()));

    // Loading visible first
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Halo, Ahmad'), findsOneWidget);
    expect(find.text('Kelas: 4A'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('Tidak ada jadwal hari ini.'), findsOneWidget);
    expect(find.text('Belum ada pengumuman.'), findsOneWidget);
  });

  testWidgets('shows error state with retry on failure', (tester) async {
    when(() => repo.fetch(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const FailureResult(NetworkFailure('offline')));

    await tester.pumpWidget(wrap(const DashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('offline'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
