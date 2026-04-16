import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/weekly_schedule.dart';
import '../models/schedule_dto.dart';

abstract class ScheduleRemoteDataSource {
  Future<WeeklySchedule> fetch();
}

class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  final ApiClient _client;
  ScheduleRemoteDataSourceImpl(this._client);

  @override
  Future<WeeklySchedule> fetch() async {
    final res = await _client.get(ApiEndpoints.studentSchedules);
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as List? ?? const [];
    return ScheduleDto.fromJson(data);
  }
}
