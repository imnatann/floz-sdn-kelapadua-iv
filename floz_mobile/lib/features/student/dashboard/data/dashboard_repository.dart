import '../domain/dashboard_models.dart';
import 'dashboard_api.dart';

class DashboardRepository {
  final DashboardApi _api;

  DashboardRepository(this._api);

  Future<StudentDashboardData> getStudentDashboard() async {
    final data = await _api.fetchDashboardData();
    return StudentDashboardData.fromJson(data);
  }
}
