import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/student/courses/domain/entities/course.dart';
import 'package:floz_mobile/features/student/courses/domain/repositories/courses_repository.dart';
import 'package:floz_mobile/features/student/courses/providers/courses_providers.dart';
import 'package:floz_mobile/features/student/dashboard/domain/entities/dashboard.dart';
import 'package:floz_mobile/features/student/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:floz_mobile/features/student/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:floz_mobile/features/student/dashboard/providers/dashboard_providers.dart';

class _MockRepo extends Mock implements DashboardRepository {}

class _MockCoursesRepo extends Mock implements CoursesRepository {}

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
  late _MockCoursesRepo coursesRepo;

  setUp(() {
    repo = _MockRepo();
    coursesRepo = _MockCoursesRepo();
    when(() => coursesRepo.fetchCourses())
        .thenAnswer((_) async => const Success<List<Course>>(<Course>[]));
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(repo),
        coursesRepositoryProvider.overrideWithValue(coursesRepo),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows data after load on happy path', (tester) async {
    when(() => repo.fetch(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(_fixture));

    await tester.pumpWidget(wrap(const DashboardScreen()));
    await tester.pumpAndSettle();

    // Greeting card shows student name prominently
    expect(find.text('Ahmad'), findsOneWidget);
    // Class + homeroom appear as chips in the greeting header
    expect(find.text('Kelas 4A'), findsOneWidget);
    expect(find.text('Bu Ani'), findsOneWidget);
    // Stat card value
    expect(find.text('90%'), findsOneWidget);
    // Empty state banners for schedules + announcements. The list is now
    // taller (Mata Pelajaran Saya section between attendance + jadwal), so
    // the announcement banner may be off-screen and needs scrolling into view.
    expect(find.text('Tidak ada jadwal hari ini.'), findsOneWidget);
    final announcementBanner = find.text('Belum ada pengumuman.');
    await tester.scrollUntilVisible(announcementBanner, 200);
    expect(announcementBanner, findsOneWidget);
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
