import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/core/storage/cache_box.dart';
import 'package:floz_mobile/features/student/announcements/data/datasources/announcement_remote_datasource.dart';
import 'package:floz_mobile/features/student/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:floz_mobile/features/student/announcements/domain/entities/announcement.dart';

class _MockRemote extends Mock implements AnnouncementRemoteDataSource {}

class _MockCache extends Mock implements CacheBox<dynamic> {}

List<AnnouncementSummary> _listFixture() => const [
      AnnouncementSummary(
        id: 1,
        title: 'Libur Nasional',
        excerpt: 'Sekolah libur besok',
        type: 'general',
        isPinned: true,
      ),
    ];

List<Map<String, dynamic>> _listFixtureJson() => [
      {
        'id': 1,
        'title': 'Libur Nasional',
        'excerpt': 'Sekolah libur besok',
        'type': 'general',
        'is_pinned': true,
        'cover_image_url': null,
        'created_at': null,
      },
    ];

AnnouncementDetail _detailFixture() => const AnnouncementDetail(
      id: 1,
      title: 'Libur Nasional',
      content: 'Sekolah libur besok karena peringatan hari kemerdekaan.',
      type: 'general',
      isPinned: true,
    );

void main() {
  late _MockRemote remote;
  late _MockCache cache;
  late AnnouncementRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    cache = _MockCache();
    repo = AnnouncementRepositoryImpl(remote: remote, cache: cache);
  });

  group('fetchList', () {
    test('returns Success from remote + writes cache', () async {
      when(() => cache.get(any())).thenAnswer((_) async => null);
      when(() => remote.fetchList()).thenAnswer((_) async => _listFixture());
      when(() => cache.put(any(), any())).thenAnswer((_) async {});

      final result = await repo.fetchList();

      expect(result, isA<Success<List<AnnouncementSummary>>>());
      verify(() => cache.put('list', any())).called(1);
    });

    test('returns stale Success on NetworkException', () async {
      when(() => cache.get(any())).thenAnswer((_) async => null);
      when(() => remote.fetchList())
          .thenThrow(const NetworkException('offline'));
      when(() => cache.getStale(any()))
          .thenAnswer((_) async => _listFixtureJson());

      final result = await repo.fetchList();

      expect(result, isA<Success<List<AnnouncementSummary>>>());
      expect((result as Success).stale, isTrue);
    });

    test('returns NetworkFailure when offline + cache empty', () async {
      when(() => cache.get(any())).thenAnswer((_) async => null);
      when(() => remote.fetchList())
          .thenThrow(const NetworkException('offline'));
      when(() => cache.getStale(any())).thenAnswer((_) async => null);

      final result = await repo.fetchList();

      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });

    test('returns fresh cache without hitting remote', () async {
      when(() => cache.get(any()))
          .thenAnswer((_) async => _listFixtureJson());

      final result = await repo.fetchList();

      expect(result, isA<Success<List<AnnouncementSummary>>>());
      verifyNever(() => remote.fetchList());
    });

    test('bypasses cache on forceRefresh', () async {
      when(() => cache.get(any()))
          .thenAnswer((_) async => _listFixtureJson());
      when(() => remote.fetchList()).thenAnswer((_) async => _listFixture());
      when(() => cache.put(any(), any())).thenAnswer((_) async {});

      final result = await repo.fetchList(forceRefresh: true);

      verify(() => remote.fetchList()).called(1);
      expect(result, isA<Success<List<AnnouncementSummary>>>());
    });
  });

  group('fetchDetail', () {
    test('returns Success from remote (no cache)', () async {
      when(() => remote.fetchDetail(any()))
          .thenAnswer((_) async => _detailFixture());

      final result = await repo.fetchDetail(1);

      expect(result, isA<Success<AnnouncementDetail>>());
    });

    test('returns NetworkFailure on error', () async {
      when(() => remote.fetchDetail(any()))
          .thenThrow(const NetworkException('offline'));

      final result = await repo.fetchDetail(1);

      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });
  });
}
