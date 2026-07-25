import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

/// Signal used to force a global sign-out when refresh ultimately fails.
typedef OnUnauthorized = Future<void> Function();

/// Configures a [Dio] instance with:
///  - base URL / timeouts from [Env]
///  - a bearer-token interceptor
///  - transparent access-token refresh on 401 (single-flight)
///  - normalized [ApiException] error mapping
///  - dev logging
class DioClient {
  DioClient({
    required SecureStorage secureStorage,
    OnUnauthorized? onUnauthorized,
  })  : _secureStorage = secureStorage,
        _onUnauthorized = onUnauthorized {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: Env.connectTimeout,
        receiveTimeout: Env.receiveTimeout,
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );

    if (Env.enableLogging && kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
    }
  }

  final SecureStorage _secureStorage;
  final OnUnauthorized? _onUnauthorized;
  late final Dio _dio;

  /// A separate, interceptor-free Dio used exclusively for the refresh call so
  /// it can never recurse back into the 401 handler.
  final Dio _refreshDio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl));

  Completer<String?>? _refreshInFlight;

  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] != true) {
      final token = await _secureStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final isAuthError = response?.statusCode == 401;
    final isRetry = err.requestOptions.extra['retried'] == true;
    final skipAuth = err.requestOptions.extra['skipAuth'] == true;

    if (isAuthError && !isRetry && !skipAuth) {
      final newToken = await _refreshAccessToken();
      if (newToken != null) {
        try {
          final clone = await _retry(err.requestOptions, newToken);
          return handler.resolve(clone);
        } on DioException catch (e) {
          return handler.reject(e);
        }
      }
      // Refresh failed → force sign-out.
      await _onUnauthorized?.call();
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: ApiException.fromDio(err),
      ),
    );
  }

  /// Single-flight refresh: concurrent 401s await one shared refresh call.
  Future<String?> _refreshAccessToken() {
    if (_refreshInFlight != null) return _refreshInFlight!.future;

    final completer = Completer<String?>();
    _refreshInFlight = completer;

    unawaited(_performRefresh().then((token) {
      completer.complete(token);
    }).catchError((Object _) {
      completer.complete(null);
    }).whenComplete(() {
      _refreshInFlight = null;
    }));

    return completer.future;
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _secureStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final res = await _refreshDio.post<Map<String, dynamic>>(
      ApiEndpoints.refresh,
      data: {'refreshToken': refreshToken},
    );

    final data = res.data;
    final access = data?['accessToken'] as String?;
    final refresh = data?['refreshToken'] as String?;
    if (access == null) return null;

    await _secureStorage.saveTokens(
      accessToken: access,
      refreshToken: refresh ?? refreshToken,
    );
    return access;
  }

  Future<Response<dynamic>> _retry(RequestOptions options, String token) {
    final headers = Map<String, dynamic>.from(options.headers)
      ..['Authorization'] = 'Bearer $token';
    return _dio.request<dynamic>(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      cancelToken: options.cancelToken,
      options: Options(
        method: options.method,
        headers: headers,
        responseType: options.responseType,
        contentType: options.contentType,
        extra: {...options.extra, 'retried': true},
      ),
    );
  }
}
