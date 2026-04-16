import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/core/storage/cache_box.dart';
import 'package:floz_mobile/features/student/schedule/data/datasources/schedule_remote_datasource.dart';
import 'package:floz_mobile/features/student/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:floz_mobile/features/student/schedule/domain/entities/weekly_schedule.dart';

class _MockRemote extends Mock implements ScheduleRemoteDataSource {}
class _MockCache extends Mock implements CacheBox<dynamic> {}

WeeklySchedule _fixture() => const WeeklySchedule(
      days: [
        ScheduleDay(day: 1, dayName: 'Senin', items: [
          ScheduleEntry(
            id: 'uuid-1',
            startTime: '07:00',
            endTime: '08:30',
            subject: 'Matematika',
            teacher: 'Bu Ani',
          ),
        ]),
      ],
    );

List<dynamic> _fixtureJson() => [
      {
        'day': 1,
        'day_name': 'Senin',
        'items': [
          {
            'id': 'uuid-1',
            'start_time': '07:00',
            'end_time': '08:30',
            'subject': 'Matematika',
            'teacher': 'Bu Ani',
          },
        ],
      },
    ];

void main() {
  late _MockRemote remote;
  late _MockCache cache;
  late ScheduleRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    cache = _MockCache();
    repo = ScheduleRepositoryImpl(remote: remote, cache: cache);
  });

  test('returns Success from remote and writes cache on happy path', () async {
    when(() => remote.fetch()).thenAnswer((_) async => _fixture());
    when(() => cache.put(any(), any())).thenAnswer((_) async {});

    final result = await repo.fetch();

    expect(result, isA<Success<WeeklySchedule>>());
    verify(() => cache.put('main', any())).called(1);
  });

  test('returns stale Success from cache on NetworkException', () async {
    when(() => remote.fetch()).thenThrow(const NetworkException('offline'));
    when(() => cache.getStale(any())).thenAnswer((_) async => _fixtureJson());

    final result = await repo.fetch();

    expect(result, isA<Success<WeeklySchedule>>());
    expect((result as Success<WeeklySchedule>).stale, isTrue);
  });

  test('returns NetworkFailure when remote fails and cache empty', () async {
    when(() => remote.fetch()).thenThrow(const NetworkException('offline'));
    when(() => cache.getStale(any())).thenAnswer((_) async => null);

    final result = await repo.fetch();

    expect(result, isA<FailureResult<WeeklySchedule>>());
    expect((result as FailureResult).failure, isA<NetworkFailure>());
  });
}
