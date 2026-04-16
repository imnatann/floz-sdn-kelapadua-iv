import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/core/storage/cache_box.dart';
import 'package:floz_mobile/features/student/grades/data/datasources/grade_remote_datasource.dart';
import 'package:floz_mobile/features/student/grades/data/repositories/grade_repository_impl.dart';
import 'package:floz_mobile/features/student/grades/domain/entities/student_grades.dart';

class _MockRemote extends Mock implements GradeRemoteDataSource {}
class _MockCache extends Mock implements CacheBox<dynamic> {}

List<SubjectGradeSummary> _listFixture() => const [
      SubjectGradeSummary(subjectId: 1, subjectName: 'Matematika', average: 85, gradeCount: 2, kkm: 75),
    ];

List<Map<String, dynamic>> _listFixtureJson() => [
      {'subject_id': 1, 'subject_name': 'Matematika', 'average': 85, 'grade_count': 2, 'kkm': 75},
    ];

SubjectGradeInfo _detailFixture() => const SubjectGradeInfo(
      subjectId: 1,
      subjectName: 'Matematika',
      kkm: 75,
      grades: [
        GradeDetail(id: 1, dailyTestAvg: 80, midTest: 85, finalTest: 90, finalScore: 85, predicate: 'A', semester: 'Ganjil'),
      ],
    );

void main() {
  late _MockRemote remote;
  late _MockCache cache;
  late GradeRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    cache = _MockCache();
    repo = GradeRepositoryImpl(remote: remote, cache: cache);
  });

  group('fetchList', () {
    test('returns Success from remote + writes cache', () async {
      when(() => remote.fetchList()).thenAnswer((_) async => _listFixture());
      when(() => cache.put(any(), any())).thenAnswer((_) async {});

      final result = await repo.fetchList();

      expect(result, isA<Success<List<SubjectGradeSummary>>>());
      verify(() => cache.put('list', any())).called(1);
    });

    test('returns stale Success on NetworkException', () async {
      when(() => remote.fetchList()).thenThrow(const NetworkException('offline'));
      when(() => cache.getStale(any())).thenAnswer((_) async => _listFixtureJson());

      final result = await repo.fetchList();

      expect(result, isA<Success<List<SubjectGradeSummary>>>());
      expect((result as Success).stale, isTrue);
    });

    test('returns NetworkFailure when offline + cache empty', () async {
      when(() => remote.fetchList()).thenThrow(const NetworkException('offline'));
      when(() => cache.getStale(any())).thenAnswer((_) async => null);

      final result = await repo.fetchList();

      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });
  });

  group('fetchDetail', () {
    test('returns Success from remote (no cache)', () async {
      when(() => remote.fetchDetail(any())).thenAnswer((_) async => _detailFixture());

      final result = await repo.fetchDetail(1);

      expect(result, isA<Success<SubjectGradeInfo>>());
    });

    test('returns NetworkFailure on error', () async {
      when(() => remote.fetchDetail(any())).thenThrow(const NetworkException('offline'));

      final result = await repo.fetchDetail(1);

      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });
  });
}
