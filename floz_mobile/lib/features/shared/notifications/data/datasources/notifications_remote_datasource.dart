import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/notifications_page.dart';
import '../models/notifications_page_dto.dart';

abstract class NotificationsRemoteDataSource {
  Future<NotificationsPage> fetch();
  Future<void> markAsRead(String id);
  Future<int> markAllAsRead();
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final ApiClient _client;
  const NotificationsRemoteDataSourceImpl(this._client);

  @override
  Future<NotificationsPage> fetch() async {
    final res = await _client.get(ApiEndpoints.notifications);
    return NotificationsPageDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> markAsRead(String id) async {
    await _client.post(ApiEndpoints.notificationRead(id));
  }

  @override
  Future<int> markAllAsRead() async {
    final res = await _client.post(ApiEndpoints.notificationsReadAll);
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return (data['marked'] as num?)?.toInt() ?? 0;
  }
}
