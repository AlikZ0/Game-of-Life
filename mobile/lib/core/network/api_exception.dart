import 'package:dio/dio.dart';

/// Normalized application-facing error mapped from [DioException] / API error
/// envelopes so the UI never has to reason about raw HTTP.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.errors,
  });

  final String message;
  final int? statusCode;

  /// Machine-readable error code from the API envelope (e.g. `INVALID_CREDENTIALS`).
  final String? code;

  /// Field-level validation errors (`{ email: ["is required"] }`).
  final Map<String, List<String>>? errors;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isNetwork => statusCode == null;

  /// Maps a low-level [DioException] into a friendly [ApiException].
  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'The connection timed out. Check your network and try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          message: "Can't reach Life Quest right now. Check your connection.",
        );
      case DioExceptionType.badResponse:
        return ApiException.fromResponse(e.response);
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request cancelled.');
      case DioExceptionType.badCertificate:
      default: // unknown, transformTimeout, and any future Dio error types
        return ApiException(message: e.message ?? 'Something went wrong.');
    }
  }

  /// Parses the standard API error envelope:
  /// `{ "error": { "message": "...", "code": "...", "fields": {...} } }`
  factory ApiException.fromResponse(Response<dynamic>? response) {
    final int? status = response?.statusCode;
    final dynamic data = response?.data;

    if (data is Map<String, dynamic>) {
      final dynamic err = data['error'] ?? data;
      if (err is Map<String, dynamic>) {
        Map<String, List<String>>? fields;
        final dynamic rawFields = err['fields'] ?? err['errors'];
        if (rawFields is Map) {
          fields = rawFields.map(
            (key, value) => MapEntry(
              key.toString(),
              (value is List ? value : [value]).map((e) => e.toString()).toList(),
            ),
          );
        }
        return ApiException(
          message: (err['message'] ?? _defaultFor(status)).toString(),
          statusCode: status,
          code: err['code']?.toString(),
          errors: fields,
        );
      }
    }
    return ApiException(message: _defaultFor(status), statusCode: status);
  }

  static String _defaultFor(int? status) {
    if (status == null) return 'Something went wrong.';
    return switch (status) {
      400 => 'That request was invalid.',
      401 => 'Your session expired. Please sign in again.',
      403 => "You don't have access to that.",
      404 => "We couldn't find what you were looking for.",
      409 => 'That conflicts with something that already exists.',
      429 => 'Too many requests — slow down a moment.',
      >= 500 => 'Our servers hit a snag. Please try again shortly.',
      _ => 'Something went wrong.',
    };
  }

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
