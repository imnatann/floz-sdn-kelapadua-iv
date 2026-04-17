import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/features/teacher/recaps/data/datasources/recap_remote_datasource.dart';
import 'package:floz_mobile/features/teacher/recaps/data/repositories/recap_repository_impl.dart';
import 'package:floz_mobile/features/teacher/recaps/domain/entities/attendance_recap.dart';
import 'package:floz_mobile/features/teacher/recaps/domain/entities/grade_recap.dart';

class _MockRemote extends Mock implements RecapRemoteDataSource {}

AttendanceRecap _attendanceFixture() => const AttendanceRecap(
      taInfo: RecapTaInfo(id: 1, subjectName: 'Matematika', className: 'Kelas 4A'),
      students: [
        StudentAttendanceRecap(
          id: 1,
          name: 'Ahmad',
          nis: '24001',
          hadir: 18,
          sakit: 1,
          izin: 0,
          alpha: 1,
          total: 20,
          percentage: 90.0,
        ),
      ],
    );

GradeRecap _gradeFixture() => const GradeRecap(
      taInfo: RecapTaInfo(id: 1, subjectName: 'Matematika', className: 'Kelas 4A'),
      students: [
        StudentGradeRecap(
          id: 1,
          name: 'Ahmad',
          nis: '24001',
          dailyTestAvg: 85.0,
          midTest: 80.0,
          finalTest: 90.0,
          finalScore: 85.0,
          predicate: 'A',
        ),
      ],
    );

void main() {
  late _MockRemote remote;
  late RecapRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = RecapRepositoryImpl(remote: remote);
  });

  group('fetchAttendanceRecap', () {
    test('returns Success on happy path', () async {
      when(() => remote.fetchAttendanceRecap(any()))
          .thenAnswer((_) async => _attendanceFixture());
      final result = await repo.fetchAttendanceRecap(1);
      expect(result, isA<Success<AttendanceRecap>>());
      final data = (result as Success<AttendanceRecap>).data;
      expect(data.taInfo.id, 1);
      expect(data.students.first.name, 'Ahmad');
      expect(data.students.first.hadir, 18);
    });

    test('returns NetworkFailure on network error', () async {
      when(() => remote.fetchAttendanceRecap(any()))
          .thenThrow(const NetworkException('offline'));
      final result = await repo.fetchAttendanceRecap(1);
      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });
  });

  group('fetchGradeRecap', () {
    test('returns Success on happy path', () async {
      when(() => remote.fetchGradeRecap(any()))
          .thenAnswer((_) async => _gradeFixture());
      final result = await repo.fetchGradeRecap(1);
      expect(result, isA<Success<GradeRecap>>());
      final data = (result as Success<GradeRecap>).data;
      expect(data.taInfo.subjectName, 'Matematika');
      expect(data.students.first.finalScore, 85.0);
      expect(data.students.first.predicate, 'A');
    });

    test('returns ServerFailure on server error', () async {
      when(() => remote.fetchGradeRecap(any()))
          .thenThrow(const ServerException('boom', statusCode: 500));
      final result = await repo.fetchGradeRecap(1);
      expect((result as FailureResult).failure, isA<ServerFailure>());
    });
  });
}
