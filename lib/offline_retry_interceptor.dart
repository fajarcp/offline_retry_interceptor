import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:offline_retry_interceptor/src/offline_queue_db.dart';
import 'package:offline_retry_interceptor/src/retry_manager.dart';

class OfflineRetryInterceptor extends Interceptor {
  final OfflineQueueDb _db = OfflineQueueDb();
  final RetryManager _retryManager = RetryManager();

  OfflineRetryInterceptor() {
    _retryManager.startListening();
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.requestOptions.method.toUpperCase() != 'GET' &&
        (err.type == DioExceptionType.connectionError || err.type == DioExceptionType.connectionTimeout)) {
      final options = err.requestOptions;
      final headersString = jsonEncode(options.headers);
      final bodyString = options.data is Map || options.data is List
          ? jsonEncode(options.data)
          : options.data?.toString();
      await _db.queueRequest(options.path, options.method, bodyString, headersString);
      return handler.resolve(
        Response(requestOptions: options, statusCode: 202, statusMessage: 'Offline: Request queued securely'),
      );
    }
    return handler.next(err);
  }
}
