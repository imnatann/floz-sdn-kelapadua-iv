import '../domain/schedule_models.dart';
import 'schedule_api.dart';

class ScheduleRepository {
  final ScheduleApi _api;

  ScheduleRepository(this._api);

  Future<List<WeeklySchedule>> getWeeklySchedule() async {
    final data = await _api.fetchWeeklySchedule();
    return data.map((e) => WeeklySchedule.fromJson(e)).toList();
  }
}
