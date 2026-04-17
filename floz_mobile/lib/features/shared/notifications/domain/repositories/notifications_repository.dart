import '../../../../../core/error/result.dart';
import '../entities/notifications_page.dart';

abstract class NotificationsRepository {
  Future<Result<NotificationsPage>> fetch();
  Future<Result<void>> markAsRead(String id);
  Future<Result<int>> markAllAsRead();
}
