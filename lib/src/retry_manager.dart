import 'dart:convert';
import 'dart:developer';

import 'package:offline_retry_interceptor/src/offline_queue_db.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class RetryManager {
  final OfflineQueueDb _db = OfflineQueueDb();
  final Dio _dio = Dio();

  void startListening() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        _processQueue();
      }
    });
  }

  Future<void> _processQueue() async {
    final queuedRequests = await _db.getQueuedRequests();
    if (queuedRequests.isEmpty) return;
    for (var request in queuedRequests) {
      try {
        final Map<String, dynamic> headers = jsonDecode(
          request['headers'] ?? '{}',
        );
        await _dio.request(
          request['url'],
          data: request['body'],
          options: Options(method: request['method'], headers: headers),
        );
        await _db.deleteRequest(request['id']);
      } catch (e) {
        log(e.toString());
      }
    }
  }
}
