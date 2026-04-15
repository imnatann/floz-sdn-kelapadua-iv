import 'package:dio/dio.dart';
import 'api_exception.dart';
import '../storage/secure_token_storage.dart';

class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final void Function()? _onUnauthorized;

  ApiClient({
    required String baseUrl,
    required TokenStorage tokenStorage,
    void Function()? onUnauthorized,
    Dio? dioOverride,
  })  : _tokenStorage = tokenStorage,
        _onUnauthorized = onUnauthorized,
        _dio = dioOverride ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'Accept': 'application/json',
                'X-Client': 'floz-mobile/1.0.0',
              },
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      return await _dio.get(path, queryParameters: query);
    } on DioException catch (e) {
      throw mapError(e);
    }
  }

  Future<Response<dynamic>> post(String path, {dynamic body}) async {
    try {
      return await _dio.post(path, data: body);
    } on DioException catch (e) {
      throw mapError(e);
    }
  }

  Future<Response<dynamic>> put(String path, {dynamic body}) async {
    try {
      return await _dio.put(path, data: body);
    } on DioException catch (e) {
      throw mapError(e);
    }
  }

  Future<Response<dynamic>> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw mapError(e);
    }
  }

  static Never mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        throw NetworkException(e.message ?? 'Terjadi kesalahan jaringan.');
      default:
        break;
    }

    final code = e.response?.statusCode;
    final body = e.response?.data;
    final message = (body is Map && body['message'] is String)
        ? body['message'] as String
        : (e.message ?? 'Terjadi kesalahan.');

    switch (code) {
      case 401:
        throw UnauthorizedException(message);
      case 403:
        throw ForbiddenException(message);
      case 404:
        throw NotFoundException(message);
      case 422:
        final errors = <String, List<String>>{};
        if (body is Map && body['errors'] is Map) {
          (body['errors'] as Map).forEach((k, v) {
            if (v is List) {
              errors[k.toString()] = v.map((e) => e.toString()).toList();
            }
          });
        }
        throw ValidationException(message, errors);
      case 429:
        throw RateLimitException(message);
      default:
        throw ServerException(message, statusCode: code);
    }
  }
}
