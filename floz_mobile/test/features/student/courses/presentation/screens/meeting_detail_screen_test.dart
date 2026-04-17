import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/student/courses/domain/entities/material_item.dart' as mat;
import 'package:floz_mobile/features/student/courses/domain/entities/meeting_detail.dart';
import 'package:floz_mobile/features/student/courses/domain/repositories/courses_repository.dart';
import 'package:floz_mobile/features/student/courses/presentation/screens/meeting_detail_screen.dart';
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
      child: const MaterialApp(home: MeetingDetailScreen(meetingId: 10)),
    );
  }

  testWidgets('shows file material with filename', (tester) async {
    when(() => repo.fetchMeetingDetail(10)).thenAnswer(
      (_) async => Success(
        const MeetingDetail(
          meeting: MeetingHeader(
            id: 10,
            meetingNumber: 1,
            title: 'Pertemuan 1',
            isLocked: false,
            subjectName: 'Matematika',
            className: 'Kelas 4A',
          ),
          materials: [
            mat.MaterialItem(
              id: 1,
              title: 'Slide Bab 1',
              type: mat.MaterialType.file,
              fileName: 'slide.pdf',
              fileSize: 245760,
              fileUrl: 'https://example.test/slide.pdf',
              sortOrder: 1,
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Slide Bab 1'), findsOneWidget);
    expect(find.text('slide.pdf'), findsOneWidget);
  });

  testWidgets('shows link material with url', (tester) async {
    when(() => repo.fetchMeetingDetail(10)).thenAnswer(
      (_) async => Success(
        const MeetingDetail(
          meeting: MeetingHeader(
            id: 10,
            meetingNumber: 1,
            title: 'Pertemuan 1',
            isLocked: false,
            subjectName: 'Matematika',
            className: 'Kelas 4A',
          ),
          materials: [
            mat.MaterialItem(
              id: 2,
              title: 'Video YouTube',
              type: mat.MaterialType.link,
              url: 'https://youtube.com/watch?v=xyz',
              sortOrder: 1,
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Video YouTube'), findsOneWidget);
    expect(find.textContaining('youtube'), findsOneWidget);
  });

  testWidgets('shows empty state when materials is empty', (tester) async {
    when(() => repo.fetchMeetingDetail(10)).thenAnswer(
      (_) async => Success(
        const MeetingDetail(
          meeting: MeetingHeader(
            id: 10,
            meetingNumber: 1,
            title: 'Pertemuan 1',
            isLocked: false,
            subjectName: 'Matematika',
            className: 'Kelas 4A',
          ),
          materials: [],
        ),
      ),
    );

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.textContaining('Belum ada materi'), findsOneWidget);
  });
}
