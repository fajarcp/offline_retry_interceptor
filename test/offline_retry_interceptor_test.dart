import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:offline_retry_interceptor/offline_retry_interceptor.dart';

import 'package:offline_retry_interceptor/src/offline_queue_db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class MockRequestOptions extends Mock implements RequestOptions {}

class FakeResponse extends Fake implements Response {}

class FakeDioException extends Fake implements DioException {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(FakeResponse());
    registerFallbackValue(FakeDioException());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (MethodCall methodCall) async => 'none',
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
          (MethodCall methodCall) async => null,
        );
  });

  group('OfflineQueueDb Tests', () {
    late OfflineQueueDb dbHelper;

    setUp(() async {
      dbHelper = OfflineQueueDb();
      final db = await dbHelper.database;
      await db.delete('network_queue');
    });

    test('Should queue a request and retrieve it', () async {
      await dbHelper.queueRequest(
        'https://api.example.com/post',
        'POST',
        jsonEncode({'key': 'value'}),
        jsonEncode({'Authorization': 'Bearer token'}),
      );

      final queue = await dbHelper.getQueuedRequests();

      expect(queue.length, 1);
      expect(queue.first['url'], 'https://api.example.com/post');
      expect(queue.first['method'], 'POST');
    });

    test('Should delete a request by ID', () async {
      await dbHelper.queueRequest(
        'https://api.example.com/delete',
        'DELETE',
        null,
        null,
      );
      var queue = await dbHelper.getQueuedRequests();
      expect(queue.length, 1);

      final idToDelete = queue.first['id'] as int;

      await dbHelper.deleteRequest(idToDelete);

      queue = await dbHelper.getQueuedRequests();

      expect(queue.isEmpty, true);
    });
  });

  group('OfflineRetryInterceptor Tests', () {
    late OfflineRetryInterceptor interceptor;
    late MockErrorInterceptorHandler mockHandler;
    late OfflineQueueDb dbHelper;

    setUp(() async {
      interceptor = OfflineRetryInterceptor();
      mockHandler = MockErrorInterceptorHandler();
      dbHelper = OfflineQueueDb();

      final db = await dbHelper.database;
      await db.delete('network_queue');
    });

    test(
      'Should intercept connection errors, queue POST requests, and resolve with 202',
      () async {
        final requestOptions = RequestOptions(
          path: '/submit-data',
          method: 'POST',
          data: {'foo': 'bar'},
          headers: {'Content-Type': 'application/json'},
        );

        final dioException = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
        );

        await interceptor.onError(dioException, mockHandler);

        verify(() => mockHandler.resolve(any())).called(1);
        final queue = await dbHelper.getQueuedRequests();
        expect(queue.length, 1);
        expect(queue.first['url'], '/submit-data');
        expect(queue.first['body'], '{"foo":"bar"}');
      },
    );

    test(
      'Should ignore GET requests and pass the error down the chain',
      () async {
        final requestOptions = RequestOptions(path: '/get-data', method: 'GET');

        final dioException = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
        );

        await interceptor.onError(dioException, mockHandler);

        verify(() => mockHandler.next(dioException)).called(1);

        final queue = await dbHelper.getQueuedRequests();
        expect(queue.isEmpty, true);
      },
    );
  });
}
