import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/core/storage/cache_box.dart';
import 'package:floz_mobile/features/student/assignments/data/datasources/assignment_remote_datasource.dart';
import 'package:floz_mobile/features/student/assignments/data/repositories/assignment_repository_impl.dart';
import 'package:floz_mobile/features/student/assignments/domain/entities/assignment.dart';

class _MockRemote extends Mock implements AssignmentRemoteDataSource {}

class _MockCache extends Mock implements CacheBox<dynamic> {}

List<AssignmentSummary> _listFixture() => const [
      AssignmentSummary(
        id: 1,
        title: 'Tugas Matematika',
        description: 'Kerjakan soal halaman 42',
        subject: 'Matematika',
        teacher: 'Pak Budi',
        type: 'homework',
      ),
    ];

List<Map<String, dynamic>> _listFixtureJson() => [
      {
        'id': 1,
        'title': 'Tugas Matematika',
        'description': 'Kerjakan soal halaman 42',
        'due_date': null,
        'subject': 'Matematika',
        'teacher': 'Pak Budi',
        'type': 'homework',
      },
    ];

AssignmentDetail _detailFixture() => const AssignmentDetail(
      id: 1,
      title: 'Tugas Matematika',
      description: 'Kerjakan soal halaman 42',
      subject: 'Matematika',
      teacher: 'Pak Budi',
      type: 'homework',
      files: [],
      submission: null,
    );

void main() {
  late _MockRemote remote;
  late _MockCache cache;
  late AssignmentRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    cache = _MockCache();
    repo = AssignmentRepositoryImpl(remote: remote, cache: cache);
  });

  group('fetchList (upcoming)', () {
    test('returns Success from remote + writes cache under list_upcoming', () async {
      when(() => cache.get(any())).thenAnswer((_) async => null);
      when(() => remote.fetchList(status: 'upcoming'))
          .thenAnswer((_) async => _listFixture());
      when(() => cache.put(any(), any())).thenAnswer((_) async {});

      final result = await repo.fetchList();

      expect(result, isA<Success<List<AssignmentSummary>>>());
      verify(() => cache.put('list_upcoming', any())).called(1);
    });

    test('returns stale Success on NetworkException', () async {
      when(() => cache.get(any())).thenAnswer((_) async => null);
      when(() => remote.fetchList(status: 'upcoming'))
          .thenThrow(const NetworkException('offline'));
      when(() => cache.getStale(any()))
          .thenAnswer((_) async => _listFixtureJson());

      final result = await repo.fetchList();

      expect(result, isA<Success<List<AssignmentSummary>>>());
      expect((result as Success).stale, isTrue);
    });

    test('returns NetworkFailure when offline + cache empty', () async {
      when(() => cache.get(any())).thenAnswer((_) async => null);
      when(() => remote.fetchList(status: 'upcoming'))
          .thenThrow(const NetworkException('offline'));
      when(() => cache.getStale(any())).thenAnswer((_) async => null);

      final result = await repo.fetchList();

      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });

    test('returns fresh cache without hitting remote', () async {
      when(() => cache.get(any()))
          .thenAnswer((_) async => _listFixtureJson());

      final result = await repo.fetchList();

      expect(result, isA<Success<List<AssignmentSummary>>>());
      verifyNever(() => remote.fetchList(status: any(named: 'status')));
    });

    test('bypasses cache on forceRefresh', () async {
      when(() => cache.get(any()))
          .thenAnswer((_) async => _listFixtureJson());
      when(() => remote.fetchList(status: 'upcoming'))
          .thenAnswer((_) async => _listFixture());
      when(() => cache.put(any(), any())).thenAnswer((_) async {});

      final result = await repo.fetchList(forceRefresh: true);

      verify(() => remote.fetchList(status: 'upcoming')).called(1);
      expect(result, isA<Success<List<AssignmentSummary>>>());
    });

    test('uses separate cache key for completed status', () async {
      when(() => cache.get(any())).thenAnswer((_) async => null);
      when(() => remote.fetchList(status: 'completed'))
          .thenAnswer((_) async => _listFixture());
      when(() => cache.put(any(), any())).thenAnswer((_) async {});

      await repo.fetchList(status: 'completed');

      verify(() => cache.put('list_completed', any())).called(1);
      verifyNever(() => cache.put('list_upcoming', any()));
    });
  });

  group('fetchDetail', () {
    test('returns Success from remote (always fresh, no cache)', () async {
      when(() => remote.fetchDetail(any()))
          .thenAnswer((_) async => _detailFixture());

      final result = await repo.fetchDetail(1);

      expect(result, isA<Success<AssignmentDetail>>());
    });

    test('returns NetworkFailure on error', () async {
      when(() => remote.fetchDetail(any()))
          .thenThrow(const NetworkException('offline'));

      final result = await repo.fetchDetail(1);

      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });
  });
}
