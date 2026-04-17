import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/recap_remote_datasource.dart';
import '../data/repositories/recap_repository_impl.dart';
import '../domain/entities/attendance_recap.dart';
import '../domain/entities/grade_recap.dart';
import '../domain/repositories/recap_repository.dart';

final recapRemoteDataSourceProvider = Provider<RecapRemoteDataSource>((ref) {
  return RecapRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final recapRepositoryProvider = Provider<RecapRepository>((ref) {
  return RecapRepositoryImpl(remote: ref.watch(recapRemoteDataSourceProvider));
});

final attendanceRecapProvider =
    FutureProvider.family<AttendanceRecap, int>((ref, taId) async {
  final result = await ref.read(recapRepositoryProvider).fetchAttendanceRecap(taId);
  switch (result) {
    case Success(:final data):
      return data;
    case FailureResult(:final failure):
      throw failure;
  }
});

final gradeRecapProvider =
    FutureProvider.family<GradeRecap, int>((ref, taId) async {
  final result = await ref.read(recapRepositoryProvider).fetchGradeRecap(taId);
  switch (result) {
    case Success(:final data):
      return data;
    case FailureResult(:final failure):
      throw failure;
  }
});
