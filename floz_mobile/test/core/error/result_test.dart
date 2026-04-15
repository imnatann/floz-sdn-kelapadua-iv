import 'package:flutter_test/flutter_test.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';

void main() {
  group('Result<T>', () {
    test('Success holds data', () {
      const Result<int> r = Success<int>(42);
      expect(r, isA<Success<int>>());
      expect((r as Success<int>).data, 42);
    });

    test('FailureResult holds failure', () {
      const Result<int> r = FailureResult<int>(NetworkFailure('offline'));
      expect(r, isA<FailureResult<int>>());
      expect((r as FailureResult<int>).failure, isA<NetworkFailure>());
    });

    test('pattern matching on Result', () {
      Result<int> r = const Success(10);
      final out = switch (r) {
        Success(:final data) => data * 2,
        FailureResult() => -1,
      };
      expect(out, 20);
    });
  });

  group('Failure', () {
    test('NetworkFailure carries a message', () {
      const f = NetworkFailure('no internet');
      expect(f.message, 'no internet');
    });

    test('ValidationFailure carries field errors', () {
      const f = ValidationFailure(
        message: 'invalid',
        fieldErrors: {'email': ['required']},
      );
      expect(f.fieldErrors['email'], ['required']);
    });
  });
}
