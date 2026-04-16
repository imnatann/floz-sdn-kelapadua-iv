import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/student/schedule/domain/entities/weekly_schedule.dart';
import 'package:floz_mobile/features/student/schedule/domain/repositories/schedule_repository.dart';
import 'package:floz_mobile/features/student/schedule/presentation/screens/schedule_screen.dart';
import 'package:floz_mobile/features/student/schedule/providers/schedule_providers.dart';

class _MockRepo extends Mock implements ScheduleRepository {}

const _fixture = WeeklySchedule(days: [
  ScheduleDay(
    day: 1,
    dayName: 'Senin',
    items: [
      ScheduleEntry(
        id: 'uuid-1',
        startTime: '07:00',
        endTime: '08:30',
        subject: 'Matematika',
        teacher: 'Bu Ani',
      ),
      ScheduleEntry(
        id: 'uuid-2',
        startTime: '08:30',
        endTime: '10:00',
        subject: 'Bahasa Indonesia',
        teacher: 'Pak Budi',
      ),
    ],
  ),
]);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [scheduleRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows day section header and entries on happy path',
      (tester) async {
    when(() => repo.fetch(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(_fixture));

    await tester.pumpWidget(wrap(const ScheduleScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Senin'), findsOneWidget);
    expect(find.text('2 pelajaran'), findsOneWidget);
    expect(find.text('Matematika'), findsOneWidget);
    expect(find.text('Bahasa Indonesia'), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('Bu Ani'), findsOneWidget);
    expect(find.text('Pak Budi'), findsOneWidget);
  });

  testWidgets('shows empty banner when schedule has no days', (tester) async {
    when(() => repo.fetch(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(WeeklySchedule(days: [])));

    await tester.pumpWidget(wrap(const ScheduleScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada jadwal'), findsOneWidget);
  });

  testWidgets('shows error state with retry on failure', (tester) async {
    when(() => repo.fetch(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer(
            (_) async => const FailureResult(NetworkFailure('offline')));

    await tester.pumpWidget(wrap(const ScheduleScreen()));
    await tester.pumpAndSettle();

    expect(find.text('offline'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
