import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/network/api_client.dart';
import 'package:floz_mobile/features/student/assignments/data/datasources/assignment_remote_datasource.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient mockClient;
  late AssignmentRemoteDataSourceImpl datasource;

  setUp(() {
    mockClient = _MockApiClient();
    datasource = AssignmentRemoteDataSourceImpl(mockClient);
  });

  test('submitAssignment posts to correct endpoint and returns SubmissionResult', () async {
    when(() => mockClient.post(
          '/student/assignments/7/submit',
          body: {'answer_text': 'hello', 'answer_link': null},
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 201,
          data: {
            'data': {
              'submission_id': 1,
              'status': 'submitted',
              'submitted_at': '2026-05-08T10:00:00.000000Z',
              'is_late': false,
            }
          },
        ));

    final result = await datasource.submitAssignment(7, answerText: 'hello');
    expect(result.status, 'submitted');
    expect(result.isLate, false);
    expect(result.submissionId, 1);
  });

  test('submitAssignment with both text and link succeeds', () async {
    when(() => mockClient.post(
          '/student/assignments/3/submit',
          body: {'answer_text': 'answer', 'answer_link': 'https://drive.google.com/x'},
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 201,
          data: {
            'data': {
              'submission_id': 5,
              'status': 'submitted',
              'submitted_at': '2026-05-08T10:00:00.000000Z',
              'is_late': true,
            }
          },
        ));

    final result = await datasource.submitAssignment(
      3,
      answerText: 'answer',
      answerLink: 'https://drive.google.com/x',
    );
    expect(result.isLate, true);
    expect(result.submissionId, 5);
  });
}
