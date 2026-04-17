import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/attendance_recap.dart';
import '../../domain/entities/grade_recap.dart';
import '../models/attendance_recap_dto.dart';
import '../models/grade_recap_dto.dart';

abstract class RecapRemoteDataSource {
  Future<AttendanceRecap> fetchAttendanceRecap(int taId);
  Future<GradeRecap> fetchGradeRecap(int taId);
}

class RecapRemoteDataSourceImpl implements RecapRemoteDataSource {
  final ApiClient _client;
  RecapRemoteDataSourceImpl(this._client);

  @override
  Future<AttendanceRecap> fetchAttendanceRecap(int taId) async {
    final res = await _client.get(ApiEndpoints.teacherAttendanceRecap(taId));
    final body = res.data as Map<String, dynamic>;
    return AttendanceRecapDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<GradeRecap> fetchGradeRecap(int taId) async {
    final res = await _client.get(ApiEndpoints.teacherGradeRecap(taId));
    final body = res.data as Map<String, dynamic>;
    return GradeRecapDto.fromJson(body['data'] as Map<String, dynamic>);
  }
}
