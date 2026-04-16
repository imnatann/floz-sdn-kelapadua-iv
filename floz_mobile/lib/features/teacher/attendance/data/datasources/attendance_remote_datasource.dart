import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/attendance_roster.dart';
import '../models/attendance_dto.dart';

abstract class AttendanceRemoteDataSource {
  Future<AttendanceRoster> fetchRoster(int meetingId);
  Future<AttendanceRoster> submitAttendance(int meetingId, List<Map<String, dynamic>> entries);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final ApiClient _client;
  AttendanceRemoteDataSourceImpl(this._client);

  @override
  Future<AttendanceRoster> fetchRoster(int meetingId) async {
    final res = await _client.get(
      '${ApiEndpoints.teacherMeetings}/$meetingId/attendance',
    );
    final body = res.data as Map<String, dynamic>;
    return AttendanceRosterDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<AttendanceRoster> submitAttendance(
    int meetingId,
    List<Map<String, dynamic>> entries,
  ) async {
    final res = await _client.post(
      '${ApiEndpoints.teacherMeetings}/$meetingId/attendance',
      body: {'entries': entries},
    );
    final body = res.data as Map<String, dynamic>;
    return AttendanceRosterDto.fromJson(body['data'] as Map<String, dynamic>);
  }
}
