import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

class _FakeHttpClientAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    final method = options.method.toUpperCase();

    if (method == 'GET' && path == '/get') {
      return ResponseBody.fromString(
        jsonEncode({'ok': true}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (method == 'POST' && path == '/post') {
      return ResponseBody.fromString(
        jsonEncode({'ok': true}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (method == 'GET' && path == '/status/404') {
      return ResponseBody.fromString(
        jsonEncode({'error': 'not found'}),
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'error': 'unhandled'}),
      500,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  group('Dio HTTP Logging Tests', () {
    late List<LogRecord> logRecords;
    late StreamSubscription<LogRecord> logSubscription;
    late Level previousRootLevel;

    setUp(() {
      logRecords = [];
      // Capture log records for testing
      logSubscription = Logger.root.onRecord.listen((record) {
        if (record.loggerName == 'HttpConfigUtils') {
          logRecords.add(record);
        }
      });

      previousRootLevel = Logger.root.level;
      Logger.root.level = Level.ALL;
    });

    tearDown(() async {
      Logger.root.level = previousRootLevel;
      await logSubscription.cancel();
      logRecords.clear();
    });

    test('should add logging interceptor when enableHttpLogging is true', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withTransportOptions({
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
      ).withTransportOptions({
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
      ).withTransportOptions({
        'enableHttpLogging': true,
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://example.com',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );
      dio.httpClientAdapter = _FakeHttpClientAdapter();

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
      ).withTransportOptions({
        'enableHttpLogging': true,
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://example.com',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );
      dio.httpClientAdapter = _FakeHttpClientAdapter();

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
      ).withTransportOptions({
        'enableHttpLogging': true,
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://example.com',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );
      dio.httpClientAdapter = _FakeHttpClientAdapter();

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
      ).withTransportOptions({
        'enableHttpLogging': true,
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://example.com',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );
      dio.httpClientAdapter = _FakeHttpClientAdapter();

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
      ).withTransportOptions({
        'enableHttpLogging': true,
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://example.com',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );
      dio.httpClientAdapter = _FakeHttpClientAdapter();

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
