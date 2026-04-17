import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/shared/notifications/domain/entities/notification_item.dart';
import 'package:floz_mobile/features/shared/notifications/domain/entities/notifications_page.dart';
import 'package:floz_mobile/features/shared/notifications/domain/repositories/notifications_repository.dart';
import 'package:floz_mobile/features/shared/notifications/presentation/screens/notifications_screen.dart';
import 'package:floz_mobile/features/shared/notifications/providers/notifications_providers.dart';
import 'package:mocktail/mocktail.dart';

class _FakeRepo extends Mock implements NotificationsRepository {}

void main() {
  late _FakeRepo repo;

  setUp(() {
    repo = _FakeRepo();
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [notificationsRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: NotificationsScreen()),
    );
  }

  testWidgets('shows list with read/unread distinction', (tester) async {
    when(() => repo.fetch()).thenAnswer((_) async => Success(NotificationsPage(
          items: [
            NotificationItem(
              id: '1',
              type: 'grade',
              title: 'Nilai Baru',
              body: 'Matematika: 85',
              icon: 'star',
              createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
              readAt: null,
            ),
            NotificationItem(
              id: '2',
              type: 'announcement',
              title: 'Pengumuman',
              body: 'Libur besok',
              icon: 'campaign',
              createdAt: DateTime.now().subtract(const Duration(hours: 2)),
              readAt: DateTime.now(),
            ),
          ],
          currentPage: 1,
          lastPage: 1,
          total: 2,
          unreadCount: 1,
        )));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Nilai Baru'), findsOneWidget);
    expect(find.text('Pengumuman'), findsOneWidget);
    expect(find.text('Tandai semua dibaca'), findsOneWidget);
  });

  testWidgets('shows empty state when no notifications', (tester) async {
    when(() => repo.fetch())
        .thenAnswer((_) async => Success(const NotificationsPage(
              items: [],
              currentPage: 1,
              lastPage: 1,
              total: 0,
              unreadCount: 0,
            )));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Belum ada notifikasi.'), findsOneWidget);
    expect(find.text('Tandai semua dibaca'), findsNothing);
  });

  testWidgets('mark-all-as-read button calls repo and refreshes',
      (tester) async {
    when(() => repo.fetch()).thenAnswer((_) async => Success(NotificationsPage(
          items: [
            NotificationItem(
              id: '1',
              type: 'grade',
              title: 'Nilai',
              body: 'X',
              icon: 'star',
              createdAt: DateTime.now(),
            ),
          ],
          currentPage: 1,
          lastPage: 1,
          total: 1,
          unreadCount: 1,
        )));
    when(() => repo.markAllAsRead()).thenAnswer((_) async => const Success(1));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tandai semua dibaca'));
    await tester.pumpAndSettle();

    verify(() => repo.markAllAsRead()).called(1);
  });
}
