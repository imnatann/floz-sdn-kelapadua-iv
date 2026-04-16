import '../../../../../core/error/result.dart';
import '../entities/weekly_schedule.dart';

abstract class ScheduleRepository {
  Future<Result<WeeklySchedule>> fetch({bool forceRefresh = false});
}
