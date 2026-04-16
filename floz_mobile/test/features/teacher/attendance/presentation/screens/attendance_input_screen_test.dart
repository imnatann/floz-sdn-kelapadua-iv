import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/teacher/attendance/domain/entities/attendance_roster.dart';
import 'package:floz_mobile/features/teacher/attendance/domain/repositories/attendance_repository.dart';
import 'package:floz_mobile/features/teacher/attendance/presentation/screens/attendance_input_screen.dart';
import 'package:floz_mobile/features/teacher/attendance/providers/attendance_providers.dart';

class _MockRepo extends Mock implements AttendanceRepository {}

const _fixture = AttendanceRoster(
  meeting: MeetingInfo(id: 1, meetingNumber: 3, title: 'Pertemuan 3'),
  classInfo: ClassInfo(id: 1, name: 'Kelas 4A'),
  subject: SubjectInfo(id: 1, name: 'Matematika'),
  students: [
    StudentAttendance(id: 1, name: 'Ahmad', nis: '24001', status: null),
    StudentAttendance(id: 2, name: 'Budi', nis: '24002', status: 'hadir'),
  ],
);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    // Provide a no-op stub for submitAttendance to avoid MissingStubError
    // if the controller happens to be created.
    when(() => repo.submitAttendance(any(), any()))
        .thenAnswer((_) async => const Success(_fixture));
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows student list with status toggles', (tester) async {
    when(() => repo.fetchRoster(any()))
        .thenAnswer((_) async => const Success(_fixture));

    await tester.pumpWidget(wrap(const AttendanceInputScreen(meetingId: 1)));
    await tester.pumpAndSettle();

    // Both student names appear
    expect(find.text('Ahmad'), findsOneWidget);
    expect(find.text('Budi'), findsOneWidget);

    // NIS values appear
    expect(find.text('24001'), findsOneWidget);
    expect(find.text('24002'), findsOneWidget);

    // 'H' chip for Budi (status: 'hadir') should be selected (active green)
    // We can verify the chip widgets are rendered. There are 4 chips per student
    // so 8 'H','S','I','A' labels total (2 students × 4 chips).
    // Find all text widgets with label 'H' — there should be 2 (one per student).
    expect(find.text('H'), findsNWidgets(2));
    expect(find.text('S'), findsNWidgets(2));
    expect(find.text('I'), findsNWidgets(2));
    expect(find.text('A'), findsNWidgets(2));

    // AppBar subtitle includes subject and class
    expect(find.text('Matematika - Kelas 4A'), findsOneWidget);
  });

  testWidgets('shows error state on roster load failure', (tester) async {
    when(() => repo.fetchRoster(any())).thenAnswer(
      (_) async => const FailureResult(NetworkFailure('Tidak ada koneksi')),
    );

    await tester.pumpWidget(wrap(const AttendanceInputScreen(meetingId: 1)));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada koneksi'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('Simpan button disabled when not all students have status',
      (tester) async {
    when(() => repo.fetchRoster(any()))
        .thenAnswer((_) async => const Success(_fixture));

    await tester.pumpWidget(wrap(const AttendanceInputScreen(meetingId: 1)));
    await tester.pumpAndSettle();

    // Ahmad (id: 1) has null status → not all students have status
    // Button should be disabled (onPressed == null)
    final buttonFinder = find.widgetWithText(ElevatedButton, 'Simpan Absensi');
    expect(buttonFinder, findsOneWidget);

    final button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNull);
  });
}
