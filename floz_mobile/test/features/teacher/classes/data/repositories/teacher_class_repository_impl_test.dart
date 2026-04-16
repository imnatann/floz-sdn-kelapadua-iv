import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/core/storage/cache_box.dart';
import 'package:floz_mobile/features/teacher/classes/data/datasources/teacher_class_remote_data_source.dart';
import 'package:floz_mobile/features/teacher/classes/data/repositories/teacher_class_repository_impl.dart';
import 'package:floz_mobile/features/teacher/classes/domain/entities/class_meetings.dart';
import 'package:floz_mobile/features/teacher/classes/domain/entities/teaching_assignment_summary.dart';

class _MockRemote extends Mock implements TeacherClassRemoteDataSource {}

class _MockCache extends Mock implements CacheBox<dynamic> {}

List<TeachingAssignmentSummary> _listFixture() => const [
      TeachingAssignmentSummary(
        id: 1,
        subjectName: 'Matematika',
        className: '6A',
        academicYear: '2024/2025',
        studentCount: 28,
        meetingCount: 16,
      ),
    ];

List<Map<String, dynamic>> _listFixtureJson() => [
      {
        'id': 1,
        'subject_name': 'Matematika',
        'class_name': '6A',
        'academic_year': '2024/2025',
        'student_count': 28,
        'meeting_count': 16,
      },
    ];

ClassMeetings _meetingsFixture() => const ClassMeetings(
      taId: 1,
      subjectName: 'Matematika',
      className: '6A',
      meetings: [
        MeetingSummary(
          id: 10,
          meetingNumber: 1,
          title: 'Bilangan Bulat',
          isLocked: false,
          materialCount: 2,
          assignmentCount: 1,
        ),
      ],
    );

void main() {
  late _MockRemote remote;
  late _MockCache cache;
  late TeacherClassRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    cache = _MockCache();
    repo = TeacherClassRepositoryImpl(remote: remote, cache: cache);
  });

  group('fetchList', () {
    test('returns Success from remote + writes cache', () async {
      when(() => remote.fetchList()).thenAnswer((_) async => _listFixture());
      when(() => cache.put(any(), any())).thenAnswer((_) async {});

      final result = await repo.fetchList();

      expect(result, isA<Success<List<TeachingAssignmentSummary>>>());
      verify(() => cache.put('list', any())).called(1);
    });

    test('returns stale Success on NetworkException when cache exists',
        () async {
      when(() => remote.fetchList())
          .thenThrow(const NetworkException('offline'));
      when(() => cache.getStale(any()))
          .thenAnswer((_) async => _listFixtureJson());

      final result = await repo.fetchList();

      expect(result, isA<Success<List<TeachingAssignmentSummary>>>());
      expect((result as Success).stale, isTrue);
    });

    test('returns NetworkFailure when offline + cache empty', () async {
      when(() => remote.fetchList())
          .thenThrow(const NetworkException('offline'));
      when(() => cache.getStale(any())).thenAnswer((_) async => null);

      final result = await repo.fetchList();

      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });
  });

  group('fetchMeetings', () {
    test('returns Success from remote', () async {
      when(() => remote.fetchMeetings(any()))
          .thenAnswer((_) async => _meetingsFixture());

      final result = await repo.fetchMeetings(1);

      expect(result, isA<Success<ClassMeetings>>());
      final data = (result as Success<ClassMeetings>).data;
      expect(data.meetings.length, 1);
      expect(data.subjectName, 'Matematika');
    });

    test('returns NetworkFailure on NetworkException', () async {
      when(() => remote.fetchMeetings(any()))
          .thenThrow(const NetworkException('offline'));

      final result = await repo.fetchMeetings(1);

      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });
  });
}
