import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/attendance_remote_datasource.dart';
import '../data/repositories/attendance_repository_impl.dart';
import '../domain/entities/attendance_roster.dart';
import '../domain/repositories/attendance_repository.dart';

final attendanceRemoteProvider = Provider<AttendanceRemoteDataSource>((ref) {
  return AttendanceRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepositoryImpl(remote: ref.watch(attendanceRemoteProvider));
});

/// Loads the attendance roster for a specific meeting.
final attendanceRosterProvider =
    FutureProvider.family<AttendanceRoster, int>((ref, meetingId) async {
  final result = await ref.read(attendanceRepositoryProvider).fetchRoster(meetingId);
  switch (result) {
    case Success(:final data):
      return data;
    case FailureResult(:final failure):
      throw failure;
  }
});

/// Controller for submitting attendance entries.
class AttendanceSubmitController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit({
    required int meetingId,
    required List<Map<String, dynamic>> entries,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(attendanceRepositoryProvider)
        .submitAttendance(meetingId, entries);
    switch (result) {
      case Success():
        // Invalidate the roster so it refreshes with updated data
        ref.invalidate(attendanceRosterProvider(meetingId));
        state = const AsyncData(null);
        return true;
      case FailureResult(:final failure):
        state = AsyncError(failure, StackTrace.current);
        return false;
    }
  }
}

final attendanceSubmitControllerProvider =
    AsyncNotifierProvider<AttendanceSubmitController, void>(
        AttendanceSubmitController.new);
