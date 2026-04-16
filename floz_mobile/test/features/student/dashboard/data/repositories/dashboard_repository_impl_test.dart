import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/core/storage/cache_box.dart';
import 'package:floz_mobile/features/student/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:floz_mobile/features/student/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:floz_mobile/features/student/dashboard/domain/entities/dashboard.dart';

class _MockRemote extends Mock implements DashboardRemoteDataSource {}
class _MockCache extends Mock implements CacheBox<dynamic> {}

StudentDashboard _fixture() => const StudentDashboard(
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

Map<String, dynamic> _fixtureJson() => {
      'student': {'id': 1, 'name': 'Ahmad', 'class': '4A', 'homeroom_teacher': 'Bu Ani'},
      'stats': {'attendance_percentage': 90},
      'todays_schedules': [],
      'recent_announcements': [],
    };

void main() {
  late _MockRemote remote;
  late _MockCache cache;
  late DashboardRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    cache = _MockCache();
    repo = DashboardRepositoryImpl(remote: remote, cache: cache);
  });

  group('fetch', () {
    test('returns Success from remote and writes cache on happy path', () async {
      when(() => remote.fetch()).thenAnswer((_) async => _fixture());
      when(() => cache.put(any(), any())).thenAnswer((_) async {});

      final result = await repo.fetch();

      expect(result, isA<Success<StudentDashboard>>());
      verify(() => cache.put('main', any())).called(1);
    });

    test('returns stale Success from cache when remote throws NetworkException', () async {
      when(() => remote.fetch()).thenThrow(const NetworkException('offline'));
      when(() => cache.getStale(any())).thenAnswer((_) async => _fixtureJson());

      final result = await repo.fetch();

      expect(result, isA<Success<StudentDashboard>>());
      expect((result as Success<StudentDashboard>).stale, isTrue);
    });

    test('returns NetworkFailure when remote throws and cache is empty', () async {
      when(() => remote.fetch()).thenThrow(const NetworkException('offline'));
      when(() => cache.getStale(any())).thenAnswer((_) async => null);

      final result = await repo.fetch();

      expect(result, isA<FailureResult<StudentDashboard>>());
      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });

    test('returns AuthFailure on 401', () async {
      when(() => remote.fetch()).thenThrow(const UnauthorizedException('expired'));

      final result = await repo.fetch();

      expect((result as FailureResult).failure, isA<AuthFailure>());
    });

    test('returns ServerFailure on 500', () async {
      when(() => remote.fetch()).thenThrow(const ServerException('boom'));

      final result = await repo.fetch();

      expect((result as FailureResult).failure, isA<ServerFailure>());
    });
  });
}
