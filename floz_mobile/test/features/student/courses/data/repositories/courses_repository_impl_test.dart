import 'package:flutter_test/flutter_test.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/features/student/courses/data/datasources/courses_remote_datasource.dart';
import 'package:floz_mobile/features/student/courses/data/repositories/courses_repository_impl.dart';
import 'package:floz_mobile/features/student/courses/domain/entities/course.dart';
import 'package:floz_mobile/features/student/courses/domain/entities/material_item.dart';
import 'package:floz_mobile/features/student/courses/domain/entities/meeting_detail.dart';
import 'package:floz_mobile/features/student/courses/domain/entities/meeting_summary.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements CoursesRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late CoursesRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = CoursesRepositoryImpl(remote: remote);
  });

  test('fetchCourses returns Success', () async {
    when(() => remote.fetchCourses()).thenAnswer((_) async => const [
          Course(
            id: 1,
            subjectName: 'Matematika',
            teacherName: 'Bu Siti',
            meetingCount: 16,
            materialCount: 4,
          ),
        ]);
    final r = await repo.fetchCourses();
    expect(r, isA<Success<List<Course>>>());
    expect((r as Success).data.first.subjectName, 'Matematika');
  });

  test('fetchMeetings returns Success with course + meetings', () async {
    when(() => remote.fetchMeetings(1)).thenAnswer(
      (_) async => const CourseMeetings(
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
        ],
      ),
    );
    final r = await repo.fetchMeetings(1);
    expect(r, isA<Success<CourseMeetings>>());
    expect((r as Success).data.meetings.first.materialCount, 2);
  });

  test('fetchMeetingDetail returns Success with materials', () async {
    when(() => remote.fetchMeetingDetail(10)).thenAnswer(
      (_) async => const MeetingDetail(
        meeting: MeetingHeader(
          id: 10,
          meetingNumber: 1,
          title: 'Pertemuan 1',
          isLocked: false,
          subjectName: 'Matematika',
          className: 'Kelas 4A',
        ),
        materials: [
          MaterialItem(
            id: 1,
            title: 'Slide',
            type: MaterialType.file,
            fileName: 'slide.pdf',
            sortOrder: 1,
          ),
        ],
      ),
    );
    final r = await repo.fetchMeetingDetail(10);
    expect(r, isA<Success<MeetingDetail>>());
    expect((r as Success).data.materials.first.type, MaterialType.file);
  });

  test('fetchCourses returns NetworkFailure on NetworkException', () async {
    when(() => remote.fetchCourses())
        .thenThrow(const NetworkException('offline'));
    final r = await repo.fetchCourses();
    expect(r, isA<FailureResult<List<Course>>>());
    expect((r as FailureResult).failure, isA<NetworkFailure>());
  });
}
