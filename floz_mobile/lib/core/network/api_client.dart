import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/storage_service.dart';
import '../constants/api_constants.dart';

class ApiClient {
  final Dio _dio;
  final StorageService _storageService;

  ApiClient(this._storageService)
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(
            milliseconds: ApiConstants.connectionTimeout,
          ),
          receiveTimeout: const Duration(
            milliseconds: ApiConstants.receiveTimeout,
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add Auth Token if available
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Add Tenant Slug if available
          final tenantSlug = await _storageService.getTenantSlug();
          if (tenantSlug != null) {
            options.headers['X-Tenant-Slug'] = tenantSlug;
          }

          if (kDebugMode) {
            print('🌐 [API Request] ${options.method} ${options.uri}');
            print('   Headers: ${options.headers}');
            if (options.data != null) print('   Body: ${options.data}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print(
              '✅ [API Response] ${response.statusCode} ${response.requestOptions.uri}',
            );
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            print(
              '❌ [API Error] ${e.response?.statusCode} ${e.requestOptions.uri}',
            );
            print('   Message: ${e.message}');
            print('   Data: ${e.response?.data}');
          }

          // Handle 401 Unauthorized (Token expired)
          if (e.response?.statusCode == 401) {
            // TODO: Trigger logout or refresh token flow
          }

          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
