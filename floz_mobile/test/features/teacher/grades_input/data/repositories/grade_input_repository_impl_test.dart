import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/features/teacher/grades_input/data/datasources/grade_input_remote_datasource.dart';
import 'package:floz_mobile/features/teacher/grades_input/data/repositories/grade_input_repository_impl.dart';
import 'package:floz_mobile/features/teacher/grades_input/domain/entities/grade_roster.dart';

class _MockRemote extends Mock implements GradeInputRemoteDataSource {}

GradeRoster _fixture() => const GradeRoster(
      taId: 1,
      subjectName: 'Matematika',
      className: 'Kelas 4A',
      students: [
        StudentGrade(id: 1, name: 'Ahmad', nis: '24001'),
      ],
    );

void main() {
  late _MockRemote remote;
  late GradeInputRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = GradeInputRepositoryImpl(remote: remote);
  });

  group('fetchRoster', () {
    test('returns Success on happy path', () async {
      when(() => remote.fetchRoster(any())).thenAnswer((_) async => _fixture());
      final result = await repo.fetchRoster(1);
      expect(result, isA<Success<GradeRoster>>());
    });

    test('returns NetworkFailure on network error', () async {
      when(() => remote.fetchRoster(any()))
          .thenThrow(const NetworkException('offline'));
      final result = await repo.fetchRoster(1);
      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });
  });

  group('submitGrades', () {
    test('returns Success with updated roster on happy path', () async {
      when(() => remote.submitGrades(any(), any()))
          .thenAnswer((_) async => _fixture());
      final result = await repo.submitGrades(1, [
        {'student_id': 1, 'daily_test_avg': 85.0, 'mid_test': 80.0, 'final_test': 90.0},
      ]);
      expect(result, isA<Success<GradeRoster>>());
    });

    test('returns ServerFailure on server error', () async {
      when(() => remote.submitGrades(any(), any()))
          .thenThrow(const ServerException('boom', statusCode: 500));
      final result = await repo.submitGrades(1, []);
      expect((result as FailureResult).failure, isA<ServerFailure>());
    });
  });
}
