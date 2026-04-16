import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/features/teacher/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:floz_mobile/features/teacher/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:floz_mobile/features/teacher/attendance/domain/entities/attendance_roster.dart';

class _MockRemote extends Mock implements AttendanceRemoteDataSource {}

AttendanceRoster _fixture() => const AttendanceRoster(
      meeting: MeetingInfo(id: 1, meetingNumber: 1, title: 'Pertemuan 1'),
      classInfo: ClassInfo(id: 1, name: 'Kelas 4A'),
      subject: SubjectInfo(id: 1, name: 'Matematika'),
      students: [
        StudentAttendance(id: 1, name: 'Ahmad', nis: '24001', status: null),
      ],
    );

void main() {
  late _MockRemote remote;
  late AttendanceRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = AttendanceRepositoryImpl(remote: remote);
  });

  group('fetchRoster', () {
    test('returns Success on happy path', () async {
      when(() => remote.fetchRoster(any())).thenAnswer((_) async => _fixture());
      final result = await repo.fetchRoster(1);
      expect(result, isA<Success<AttendanceRoster>>());
    });

    test('returns NetworkFailure on network error', () async {
      when(() => remote.fetchRoster(any())).thenThrow(const NetworkException('offline'));
      final result = await repo.fetchRoster(1);
      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });
  });

  group('submitAttendance', () {
    test('returns Success with updated roster on happy path', () async {
      when(() => remote.submitAttendance(any(), any()))
          .thenAnswer((_) async => _fixture());
      final result = await repo.submitAttendance(1, [
        {'student_id': 1, 'status': 'hadir', 'note': null},
      ]);
      expect(result, isA<Success<AttendanceRoster>>());
    });

    test('returns ServerFailure on server error', () async {
      when(() => remote.submitAttendance(any(), any()))
          .thenThrow(const ServerException('boom', statusCode: 500));
      final result = await repo.submitAttendance(1, []);
      expect((result as FailureResult).failure, isA<ServerFailure>());
    });
  });
}
