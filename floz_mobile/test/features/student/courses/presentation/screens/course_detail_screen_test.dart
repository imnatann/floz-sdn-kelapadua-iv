import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/student/courses/domain/entities/meeting_summary.dart';
import 'package:floz_mobile/features/student/courses/domain/repositories/courses_repository.dart';
import 'package:floz_mobile/features/student/courses/presentation/screens/course_detail_screen.dart';
import 'package:floz_mobile/features/student/courses/providers/courses_providers.dart';
import 'package:mocktail/mocktail.dart';

class _FakeRepo extends Mock implements CoursesRepository {}

void main() {
  late _FakeRepo repo;

  setUp(() {
    repo = _FakeRepo();
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [coursesRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        home: CourseDetailScreen(
          taId: 1,
          subjectName: 'Matematika',
          className: 'Kelas 4A',
        ),
      ),
    );
  }

  testWidgets('shows meeting list with material counts', (tester) async {
    when(() => repo.fetchMeetings(1)).thenAnswer(
      (_) async => Success(
        const CourseMeetings(
          course: CourseInfo(
            id: 1,
            subjectName: 'Matematika',
            teacherName: 'Bu Siti',
            className: 'Kelas 4A',
          ),
          meetings: [
            MeetingSummary(
              id: 10,
              meetingNumber: 1,
              title: 'Pertemuan 1',
              isLocked: false,
              materialCount: 2,
            ),
            MeetingSummary(
              id: 11,
              meetingNumber: 15,
              title: 'UTS',
              isLocked: true,
              materialCount: 0,
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Pertemuan 1'), findsOneWidget);
    expect(find.text('UTS'), findsWidgets);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('locked meeting shows Belum dibuka label', (tester) async {
    when(() => repo.fetchMeetings(1)).thenAnswer(
      (_) async => Success(
        const CourseMeetings(
          course: CourseInfo(
            id: 1,
            subjectName: 'Matematika',
            teacherName: 'Bu Siti',
            className: 'Kelas 4A',
          ),
          meetings: [
            MeetingSummary(
              id: 11,
              meetingNumber: 15,
              title: 'UTS',
              isLocked: true,
              materialCount: 0,
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Belum dibuka'), findsOneWidget);
  });

  testWidgets('shows error state with retry on failure', (tester) async {
    when(() => repo.fetchMeetings(1)).thenAnswer(
      (_) async => const FailureResult(NetworkFailure('offline')),
    );

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.textContaining('offline'), findsWidgets);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
