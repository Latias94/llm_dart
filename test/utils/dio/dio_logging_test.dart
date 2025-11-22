import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:llm_dart/core/config.dart';
import 'package:llm_dart/utils/http_config_utils.dart';
import 'package:test/test.dart';

/// A fake HttpClientAdapter that always returns a successful 200 response.
class _FakeSuccessAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      'OK',
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A fake HttpClientAdapter that always throws a connection error.
class _FakeErrorAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'Simulated error',
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('Dio HTTP Logging Tests', () {
    late List<LogRecord> logRecords;
    late StreamSubscription<LogRecord> logSubscription;

    setUp(() {
      // Enable hierarchical logging to allow setting levels on non-root loggers
      hierarchicalLoggingEnabled = true;

      logRecords = [];
      // Capture log records for testing
      logSubscription = Logger('HttpConfigUtils').onRecord.listen((record) {
        logRecords.add(record);
      });
      Logger('HttpConfigUtils').level = Level.ALL;
    });

    tearDown(() {
      logSubscription.cancel();
      logRecords.clear();
    });

    test('should add logging interceptor when enableHttpLogging is true', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withExtensions({
        'enableHttpLogging': true,
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );

      // Should have logging interceptor
      expect(dio.interceptors.length, greaterThan(0));

      // Check that the interceptor is an InterceptorsWrapper (our logging interceptor)
      final hasLoggingInterceptor = dio.interceptors
          .any((interceptor) => interceptor is InterceptorsWrapper);
      expect(hasLoggingInterceptor, isTrue);
    });

    test('should not add logging interceptor when enableHttpLogging is false',
        () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withExtensions({
        'enableHttpLogging': false,
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );

      // Should not have our custom logging interceptor (InterceptorsWrapper)
      final hasLoggingInterceptor = dio.interceptors
          .any((interceptor) => interceptor is InterceptorsWrapper);
      expect(hasLoggingInterceptor, isFalse);
    });

    test('should not add logging interceptor when enableHttpLogging is not set',
        () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      );

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );

      // Should not have our custom logging interceptor (InterceptorsWrapper)
      final hasLoggingInterceptor = dio.interceptors
          .any((interceptor) => interceptor is InterceptorsWrapper);
      expect(hasLoggingInterceptor, isFalse);
    });

    test('should log request information when logging is enabled', () async {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withExtensions({
        'enableHttpLogging': true,
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://example.com',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );

      // Use a fake adapter to avoid real network calls.
      dio.httpClientAdapter = _FakeSuccessAdapter();

      // Clear any setup logs
      logRecords.clear();

      try {
        // Make a test request to httpbin.org (a testing service)
        await dio.get('/get');
      } catch (e) {
        // We don't care if the request fails, we just want to test logging
      }

      // Should have logged the request
      final requestLogs = logRecords
          .where((record) => record.message.contains('→ GET'))
          .toList();
      expect(requestLogs.length, greaterThan(0));

      // Should have logged headers
      final headerLogs = logRecords
          .where((record) => record.message.contains('→ Headers:'))
          .toList();
      expect(headerLogs.length, greaterThan(0));
    });

    test('should log response information when logging is enabled', () async {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withExtensions({
        'enableHttpLogging': true,
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://example.com',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );

      // Use a fake adapter that always succeeds.
      dio.httpClientAdapter = _FakeSuccessAdapter();

      // Clear any setup logs
      logRecords.clear();

      try {
        // Make a test request to httpbin.org
        await dio.get('/get');

        // Should have logged the response
        final responseLogs = logRecords
            .where((record) => record.message.contains('← 200'))
            .toList();
        expect(responseLogs.length, greaterThan(0));

        // Should have logged response headers
        final responseHeaderLogs = logRecords
            .where((record) => record.message.contains('← Headers:'))
            .toList();
        expect(responseHeaderLogs.length, greaterThan(0));
      } catch (e) {
        // If the request fails, we should still have error logs
        final errorLogs =
            logRecords.where((record) => record.message.contains('✗')).toList();
        expect(errorLogs.length, greaterThan(0));
      }
    });

    test('should log error information when request fails', () async {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withExtensions({
        'enableHttpLogging': true,
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://example.com',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );

      // Use a fake adapter that always fails to trigger error logging.
      dio.httpClientAdapter = _FakeErrorAdapter();

      // Clear any setup logs
      logRecords.clear();

      try {
        // Make a request that should fail (404)
        await dio.get('/status/404');
      } catch (e) {
        // Expected to fail
      }

      // Should have logged the error
      final errorLogs = logRecords
          .where((record) => record.message.contains('✗ GET'))
          .toList();
      expect(errorLogs.length, greaterThan(0));

      // Should have logged error details
      final errorDetailLogs = logRecords
          .where((record) => record.message.contains('✗ Error:'))
          .toList();
      expect(errorDetailLogs.length, greaterThan(0));
    });

    test('should log POST request data when available', () async {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withExtensions({
        'enableHttpLogging': true,
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://example.com',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );

      // Use a fake adapter that always succeeds.
      dio.httpClientAdapter = _FakeSuccessAdapter();

      // Clear any setup logs
      logRecords.clear();

      try {
        // Make a POST request with data
        await dio.post('/post', data: {'test': 'data', 'number': 42});
      } catch (e) {
        // We don't care if the request fails
      }

      // Should have logged the request data
      final dataLogs = logRecords
          .where((record) => record.message.contains('→ Data:'))
          .toList();
      expect(dataLogs.length, greaterThan(0));

      // The data log should contain our test data
      final dataLog = dataLogs.first;
      expect(dataLog.message, contains('test'));
      expect(dataLog.message, contains('data'));
    });

    test('should use correct log levels for different types of information',
        () async {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withExtensions({
        'enableHttpLogging': true,
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://example.com',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );

      // Use a fake adapter that always succeeds.
      dio.httpClientAdapter = _FakeSuccessAdapter();

      // Clear any setup logs
      logRecords.clear();

      try {
        await dio.get('/get');
      } catch (e) {
        // We don't care if the request fails
      }

      // Request/response URLs should be INFO level
      final infoLogs =
          logRecords.where((record) => record.level == Level.INFO).toList();
      expect(infoLogs.length, greaterThan(0));

      // Headers and data should be FINE level
      final fineLogs =
          logRecords.where((record) => record.level == Level.FINE).toList();
      expect(fineLogs.length, greaterThan(0));
    });
  });
}
