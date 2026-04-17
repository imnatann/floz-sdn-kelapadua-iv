import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/datasources/courses_remote_datasource.dart';
import '../data/repositories/courses_repository_impl.dart';
import '../domain/entities/course.dart';
import '../domain/entities/meeting_detail.dart';
import '../domain/entities/meeting_summary.dart';
import '../domain/repositories/courses_repository.dart';

final coursesRemoteProvider = Provider<CoursesRemoteDataSource>((ref) {
  return CoursesRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return CoursesRepositoryImpl(remote: ref.watch(coursesRemoteProvider));
});

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final repo = ref.watch(coursesRepositoryProvider);
  final result = await repo.fetchCourses();
  return switch (result) {
    Success(:final data) => data,
    FailureResult(:final failure) => throw failure,
  };
});

final courseMeetingsProvider =
    FutureProvider.family<CourseMeetings, int>((ref, taId) async {
  final repo = ref.watch(coursesRepositoryProvider);
  final result = await repo.fetchMeetings(taId);
  return switch (result) {
    Success(:final data) => data,
    FailureResult(:final failure) => throw failure,
  };
});

final meetingDetailProvider =
    FutureProvider.family<MeetingDetail, int>((ref, meetingId) async {
  final repo = ref.watch(coursesRepositoryProvider);
  final result = await repo.fetchMeetingDetail(meetingId);
  return switch (result) {
    Success(:final data) => data,
    FailureResult(:final failure) => throw failure,
  };
});
