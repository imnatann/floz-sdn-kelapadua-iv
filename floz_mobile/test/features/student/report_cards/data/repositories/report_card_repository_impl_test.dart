import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/core/storage/cache_box.dart';
import 'package:floz_mobile/features/student/report_cards/data/datasources/report_card_remote_datasource.dart';
import 'package:floz_mobile/features/student/report_cards/data/repositories/report_card_repository_impl.dart';
import 'package:floz_mobile/features/student/report_cards/domain/entities/report_card.dart';

class _MockRemote extends Mock implements ReportCardRemoteDataSource {}
class _MockCache extends Mock implements CacheBox<dynamic> {}

List<ReportCardSummary> _listFixture() => [
      ReportCardSummary(
        id: 1,
        semesterName: 'Ganjil',
        academicYear: '2024/2025',
        averageScore: 88.5,
        rank: 5,
        publishedAt: DateTime(2024, 12, 15),
      ),
    ];

List<Map<String, dynamic>> _listFixtureJson() => [
      {
        'id': 1,
        'semester_name': 'Ganjil',
        'academic_year': '2024/2025',
        'average_score': 88.5,
        'rank': 5,
        'published_at': '2024-12-15T00:00:00.000',
      },
    ];

ReportCardDetail _detailFixture() => ReportCardDetail(
      id: 1,
      semesterName: 'Ganjil',
      academicYear: '2024/2025',
      className: '6A',
      averageScore: 88.5,
      totalScore: 531.0,
      rank: 5,
      attendancePresent: 100,
      attendanceSick: 2,
      attendancePermit: 1,
      attendanceAbsent: 0,
    );

void main() {
  late _MockRemote remote;
  late _MockCache cache;
  late ReportCardRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    cache = _MockCache();
    repo = ReportCardRepositoryImpl(remote: remote, cache: cache);
  });

  group('fetchList', () {
    test('returns Success from remote + writes cache', () async {
      when(() => cache.get(any())).thenAnswer((_) async => null);
      when(() => remote.fetchList()).thenAnswer((_) async => _listFixture());
      when(() => cache.put(any(), any())).thenAnswer((_) async {});

      final result = await repo.fetchList();

      expect(result, isA<Success<List<ReportCardSummary>>>());
      verify(() => cache.put('list', any())).called(1);
    });

    test('returns stale Success on NetworkException', () async {
      when(() => cache.get(any())).thenAnswer((_) async => null);
      when(() => remote.fetchList()).thenThrow(const NetworkException('offline'));
      when(() => cache.getStale(any())).thenAnswer((_) async => _listFixtureJson());

      final result = await repo.fetchList();

      expect(result, isA<Success<List<ReportCardSummary>>>());
      expect((result as Success).stale, isTrue);
    });

    test('returns NetworkFailure when offline + cache empty', () async {
      when(() => cache.get(any())).thenAnswer((_) async => null);
      when(() => remote.fetchList()).thenThrow(const NetworkException('offline'));
      when(() => cache.getStale(any())).thenAnswer((_) async => null);

      final result = await repo.fetchList();

      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });

    test('returns fresh cache without hitting remote', () async {
      when(() => cache.get(any())).thenAnswer((_) async => _listFixtureJson());

      final result = await repo.fetchList();

      expect(result, isA<Success<List<ReportCardSummary>>>());
      verifyNever(() => remote.fetchList());
    });

    test('bypasses cache on forceRefresh', () async {
      when(() => cache.get(any())).thenAnswer((_) async => _listFixtureJson());
      when(() => remote.fetchList()).thenAnswer((_) async => _listFixture());
      when(() => cache.put(any(), any())).thenAnswer((_) async {});

      final result = await repo.fetchList(forceRefresh: true);

      verify(() => remote.fetchList()).called(1);
      expect(result, isA<Success<List<ReportCardSummary>>>());
    });
  });

  group('fetchDetail', () {
    test('returns Success from remote (no cache)', () async {
      when(() => remote.fetchDetail(any())).thenAnswer((_) async => _detailFixture());

      final result = await repo.fetchDetail(1);

      expect(result, isA<Success<ReportCardDetail>>());
    });

    test('returns NetworkFailure on error', () async {
      when(() => remote.fetchDetail(any())).thenThrow(const NetworkException('offline'));

      final result = await repo.fetchDetail(1);

      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });
  });
}
