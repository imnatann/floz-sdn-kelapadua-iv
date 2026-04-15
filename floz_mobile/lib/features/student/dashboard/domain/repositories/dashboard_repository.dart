import '../../../../../core/error/result.dart';
import '../entities/dashboard.dart';

abstract class DashboardRepository {
  Future<Result<StudentDashboard>> fetch({bool forceRefresh = false});
}
