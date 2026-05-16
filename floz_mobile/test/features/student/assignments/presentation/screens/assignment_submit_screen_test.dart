import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/student/assignments/domain/entities/assignment.dart';
import 'package:floz_mobile/features/student/assignments/domain/repositories/assignment_repository.dart';
import 'package:floz_mobile/features/student/assignments/presentation/screens/assignment_submit_screen.dart';
import 'package:floz_mobile/features/student/assignments/providers/assignment_providers.dart';

class _MockRepo extends Mock implements AssignmentRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    // Stub fetchList and fetchDetail so Riverpod doesn't complain if providers are watched
    when(() => repo.fetchList(
          status: any(named: 'status'),
          forceRefresh: any(named: 'forceRefresh'),
        )).thenAnswer((_) async => const Success([]));
    when(() => repo.fetchDetail(any())).thenAnswer((_) async => Success(
          const AssignmentDetail(
            id: 1, title: '', description: '', subject: '', teacher: '',
            type: 'manual', files: [], submission: null,
          ),
        ));
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [assignmentRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows text field, link field, and submit button', (tester) async {
    await tester.pumpWidget(wrap(const AssignmentSubmitScreen(assignmentId: 1)));

    expect(find.byKey(const Key('answer_text_field')), findsOneWidget);
    expect(find.byKey(const Key('answer_link_field')), findsOneWidget);
    expect(find.byKey(const Key('submit_button')), findsOneWidget);
  });

  testWidgets('shows error snackbar when both fields empty', (tester) async {
    await tester.pumpWidget(wrap(const AssignmentSubmitScreen(assignmentId: 1)));

    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pump();

    expect(
      find.text('Isi jawaban atau link terlebih dahulu.'),
      findsOneWidget,
    );
    verifyNever(() => repo.submit(any()));
  });

  testWidgets('calls repository submit on success and pops', (tester) async {
    when(() => repo.submit(1, answerText: 'My answer', answerLink: null))
        .thenAnswer((_) async => Success(SubmissionResult(
              submissionId: 10,
              status: 'submitted',
              submittedAt: DateTime.now(),
              isLate: false,
            )));

    await tester.pumpWidget(wrap(const AssignmentSubmitScreen(assignmentId: 1)));

    await tester.enterText(
        find.byKey(const Key('answer_text_field')), 'My answer');
    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pumpAndSettle();

    verify(() => repo.submit(1, answerText: 'My answer', answerLink: null))
        .called(1);
  });

  testWidgets('shows failure snackbar on server error', (tester) async {
    when(() => repo.submit(1, answerText: 'answer', answerLink: null))
        .thenAnswer((_) async =>
            const FailureResult(ServerFailure('Terjadi kesalahan server.')));

    await tester.pumpWidget(wrap(const AssignmentSubmitScreen(assignmentId: 1)));

    await tester.enterText(
        find.byKey(const Key('answer_text_field')), 'answer');
    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pump(); // start async
    await tester.pump(const Duration(seconds: 1)); // settle

    expect(find.text('Terjadi kesalahan server.'), findsOneWidget);
  });
}
