import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floz_mobile/core/network/api_client.dart';
import 'package:floz_mobile/core/network/api_exception.dart';

void main() {
  group('ApiClient.mapError', () {
    // ignore: no_leading_underscores_for_local_identifiers
    DioException _makeErr({
      int? code,
      dynamic data,
      DioExceptionType type = DioExceptionType.badResponse,
    }) {
      return DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: code == null
            ? null
            : Response(
                requestOptions: RequestOptions(path: '/x'),
                statusCode: code,
                data: data,
              ),
        type: type,
      );
    }

    test('401 → UnauthorizedException', () {
      expect(
        () => ApiClient.mapError(_makeErr(code: 401, data: {'message': 'unauth'})),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('403 → ForbiddenException', () {
      expect(
        () => ApiClient.mapError(_makeErr(code: 403, data: {'message': 'forbidden'})),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('404 → NotFoundException', () {
      expect(
        () => ApiClient.mapError(_makeErr(code: 404, data: {'message': 'no'})),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('422 → ValidationException with fieldErrors', () {
      ValidationException? caught;
      try {
        // ignore: dead_code
        ApiClient.mapError(_makeErr(
          code: 422,
          data: {
            'message': 'invalid',
            'errors': {
              'email': ['required', 'email format']
            },
          },
        ));
      } on ValidationException catch (e) {
        caught = e;
      }
      expect(caught, isNotNull, reason: 'should have thrown ValidationException');
      expect(caught.errors['email'], ['required', 'email format']);
      expect(caught.message, 'invalid');
    });

    test('429 → RateLimitException', () {
      expect(
        () => ApiClient.mapError(_makeErr(code: 429, data: {'message': 'slow down'})),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('500 → ServerException', () {
      expect(
        () => ApiClient.mapError(_makeErr(code: 500, data: {'message': 'boom'})),
        throwsA(isA<ServerException>()),
      );
    });

    test('connection timeout → NetworkException', () {
      expect(
        () => ApiClient.mapError(_makeErr(type: DioExceptionType.connectionTimeout)),
        throwsA(isA<NetworkException>()),
      );
    });

    test('connection error → NetworkException', () {
      expect(
        () => ApiClient.mapError(_makeErr(type: DioExceptionType.connectionError)),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
