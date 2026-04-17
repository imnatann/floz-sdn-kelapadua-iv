import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/teacher/recaps/domain/entities/attendance_recap.dart';
import 'package:floz_mobile/features/teacher/recaps/domain/entities/grade_recap.dart';
import 'package:floz_mobile/features/teacher/recaps/domain/repositories/recap_repository.dart';
import 'package:floz_mobile/features/teacher/recaps/presentation/screens/recap_screen.dart';
import 'package:floz_mobile/features/teacher/recaps/providers/recap_providers.dart';

class _MockRepo extends Mock implements RecapRepository {}

const _attendanceRecap = AttendanceRecap(
  taInfo: RecapTaInfo(id: 1, subjectName: 'Matematika', className: 'Kelas 6A'),
  students: [
    StudentAttendanceRecap(
      id: 1,
      name: 'Ahmad Fauzi',
      nis: '24001',
      hadir: 18,
      sakit: 1,
      izin: 0,
      alpha: 1,
      total: 20,
      percentage: 90.0,
    ),
    StudentAttendanceRecap(
      id: 2,
      name: 'Budi Santoso',
      nis: '24002',
      hadir: 15,
      sakit: 2,
      izin: 1,
      alpha: 2,
      total: 20,
      percentage: 75.0,
    ),
  ],
);

const _gradeRecap = GradeRecap(
  taInfo: RecapTaInfo(id: 1, subjectName: 'Matematika', className: 'Kelas 6A'),
  students: [
    StudentGradeRecap(
      id: 1,
      name: 'Ahmad Fauzi',
      nis: '24001',
      dailyTestAvg: 85.0,
      midTest: 80.0,
      finalTest: 90.0,
      finalScore: 85.0,
      predicate: 'A',
    ),
    StudentGradeRecap(
      id: 2,
      name: 'Budi Santoso',
      nis: '24002',
      dailyTestAvg: 70.0,
      midTest: 65.0,
      finalTest: 72.0,
      finalScore: 69.0,
      predicate: 'B',
    ),
  ],
);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        recapRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(home: child),
    );
  }

  const screen = RecapScreen(
    taId: 1,
    subjectName: 'Matematika',
    className: 'Kelas 6A',
  );

  testWidgets('Absensi tab shows attendance data', (tester) async {
    when(() => repo.fetchAttendanceRecap(any()))
        .thenAnswer((_) async => const Success(_attendanceRecap));
    when(() => repo.fetchGradeRecap(any()))
        .thenAnswer((_) async => const Success(_gradeRecap));

    await tester.pumpWidget(wrap(screen));
    await tester.pumpAndSettle();

    // Tab chips visible
    expect(find.text('Absensi'), findsOneWidget);
    expect(find.text('Nilai'), findsOneWidget);

    // Both student names visible
    expect(find.text('Ahmad Fauzi'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);

    // NIS values visible
    expect(find.text('24001'), findsOneWidget);
    expect(find.text('24002'), findsOneWidget);

    // Status badge labels visible (each student has H/S/I/A so 2x each)
    expect(find.text('H'), findsNWidgets(2));
    expect(find.text('S'), findsNWidgets(2));
    expect(find.text('I'), findsNWidgets(2));
    expect(find.text('A'), findsNWidgets(2));

    // Hadir counts (18 and 15)
    expect(find.text('18'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);

    // Percentage labels
    expect(find.text('Kehadiran 90%'), findsOneWidget);
    expect(find.text('Kehadiran 75%'), findsOneWidget);
  });

  testWidgets('Nilai tab shows grade data after switching', (tester) async {
    when(() => repo.fetchAttendanceRecap(any()))
        .thenAnswer((_) async => const Success(_attendanceRecap));
    when(() => repo.fetchGradeRecap(any()))
        .thenAnswer((_) async => const Success(_gradeRecap));

    await tester.pumpWidget(wrap(screen));
    await tester.pumpAndSettle();

    // Switch to Nilai tab
    await tester.tap(find.text('Nilai'));
    await tester.pumpAndSettle();

    // Both student names visible
    expect(find.text('Ahmad Fauzi'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);

    // Score chip labels visible (one per student)
    expect(find.textContaining('Harian:'), findsNWidgets(2));
    expect(find.textContaining('UTS:'), findsNWidgets(2));
    expect(find.textContaining('UAS:'), findsNWidgets(2));
    expect(find.textContaining('Final:'), findsNWidgets(2));

    // Score values visible
    expect(find.text('85'), findsNWidgets(2)); // Ahmad daily + final
    expect(find.text('80'), findsOneWidget);   // Ahmad mid
    expect(find.text('90'), findsOneWidget);   // Ahmad final test
    expect(find.text('70'), findsOneWidget);   // Budi daily
    expect(find.text('65'), findsOneWidget);   // Budi mid
    expect(find.text('72'), findsOneWidget);   // Budi final test
    expect(find.text('69'), findsOneWidget);   // Budi final score

    // Predicate badges visible
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('shows error state with retry on attendance load failure',
      (tester) async {
    when(() => repo.fetchAttendanceRecap(any())).thenAnswer(
      (_) async =>
          const FailureResult(NetworkFailure('Tidak ada koneksi internet')),
    );
    when(() => repo.fetchGradeRecap(any()))
        .thenAnswer((_) async => const Success(_gradeRecap));

    await tester.pumpWidget(wrap(screen));
    await tester.pumpAndSettle();

    // Error message + retry button visible
    expect(find.text('Tidak ada koneksi internet'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);

    // After retry, repo is called again — first call already happened,
    // tap the retry and assert repo is called more than once.
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    verify(() => repo.fetchAttendanceRecap(1)).called(greaterThan(1));
  });
}
