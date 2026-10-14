import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import 'access_session.dart';

enum ApiErrorCode {
  invalidRequest('invalid_request'),
  unauthorized('unauthorized'),
  notFound('not_found'),
  conflict('conflict'),
  rateLimited('rate_limited'),
  internal('internal'),
  network('network'),
  unknown('unknown');

  const ApiErrorCode(this.wireName);

  final String wireName;

  static ApiErrorCode fromStatus(int? status) => switch (status) {
    400 || 422 => invalidRequest,
    401 || 403 => unauthorized,
    404 => notFound,
    409 => conflict,
    429 => rateLimited,
    final int s when s >= 500 => internal,
    _ => unknown,
  };
}

@immutable
class ApiFailure implements Exception {
  const ApiFailure({required this.code, required this.message, this.status});

  final ApiErrorCode code;
  final String message;
  final int? status;

  factory ApiFailure.fromDioException(DioException error) {
    if (error.error is ApiFailure) return error.error! as ApiFailure;
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiFailure(
        code: ApiErrorCode.network,
        message: "We couldn't reach your inbox. Check your connection.",
      );
    }

    final response = error.response;
    final status = response?.statusCode;
    if (status != null &&
        isAccessRejection(status, response?.headers.value('location'))) {
      return ApiFailure(
        code: ApiErrorCode.unauthorized,
        message: 'Your Access session ended. Sign in again.',
        status: status,
      );
    }

    final data = response?.data;
    final message = data is Map && data['error'] is String
        ? data['error'] as String
        : 'Request failed${status == null ? '' : ' ($status)'}.';
    return ApiFailure(
      code: ApiErrorCode.fromStatus(status),
      message: message,
      status: status,
    );
  }

  static const missingSession = ApiFailure(
    code: ApiErrorCode.unauthorized,
    message: 'You are not signed in.',
  );

  bool get isUnauthorized => code == ApiErrorCode.unauthorized;

  @override
  String toString() => message;
}
