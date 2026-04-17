import 'package:flutter_test/flutter_test.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/features/shared/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:floz_mobile/features/shared/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:floz_mobile/features/shared/notifications/domain/entities/notification_item.dart';
import 'package:floz_mobile/features/shared/notifications/domain/entities/notifications_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements NotificationsRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late NotificationsRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = NotificationsRepositoryImpl(remote: remote);
  });

  test('fetch returns Success with page', () async {
    when(() => remote.fetch()).thenAnswer((_) async => NotificationsPage(
          items: [
            NotificationItem(
              id: '1',
              type: 'grade',
              title: 'Nilai',
              body: 'Matematika: 85',
              icon: 'star',
              createdAt: DateTime.parse('2026-04-18T08:00:00Z'),
            ),
          ],
          currentPage: 1,
          lastPage: 1,
          total: 1,
          unreadCount: 1,
        ));
    final r = await repo.fetch();
    expect(r, isA<Success<NotificationsPage>>());
    expect((r as Success).data.unreadCount, 1);
  });

  test('fetch returns NetworkFailure on NetworkException', () async {
    when(() => remote.fetch()).thenThrow(const NetworkException('offline'));
    final r = await repo.fetch();
    expect(r, isA<FailureResult<NotificationsPage>>());
    expect((r as FailureResult).failure, isA<NetworkFailure>());
  });

  test('markAsRead returns Success', () async {
    when(() => remote.markAsRead('abc')).thenAnswer((_) async {});
    final r = await repo.markAsRead('abc');
    expect(r, isA<Success<void>>());
  });

  test('markAllAsRead returns Success with count', () async {
    when(() => remote.markAllAsRead()).thenAnswer((_) async => 7);
    final r = await repo.markAllAsRead();
    expect(r, isA<Success<int>>());
    expect((r as Success).data, 7);
  });
}
