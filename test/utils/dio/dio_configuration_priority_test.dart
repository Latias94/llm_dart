import 'package:test/test.dart';
import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

void main() {
  group('Dio Configuration Priority Tests', () {
    test('should prioritize custom timeout over default timeout', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
        timeout: Duration(seconds: 45), // LLMConfig timeout
      ).withTransportOptions({
        'connectionTimeout': Duration(seconds: 30), // Custom connection timeout
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
        defaultTimeout: Duration(seconds: 60), // Default timeout
      );

      // Should use custom connection timeout (30s), not LLMConfig timeout (45s) or default (60s)
      expect(dio.options.connectTimeout, equals(Duration(seconds: 30)));
    });

    test(
        'should prioritize LLMConfig timeout over default timeout when no custom timeout',
        () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
        timeout: Duration(seconds: 45), // LLMConfig timeout
      );

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
        defaultTimeout: Duration(seconds: 60), // Default timeout
      );

      // Should use LLMConfig timeout for all timeout types
      expect(dio.options.connectTimeout, equals(Duration(seconds: 45)));
      expect(dio.options.receiveTimeout, equals(Duration(seconds: 45)));
      expect(dio.options.sendTimeout, equals(Duration(seconds: 45)));
    });

    test('should use default timeout when no other timeouts are specified', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      );

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
        defaultTimeout: Duration(seconds: 60), // Default timeout
      );

      // Should use default timeout for all timeout types
      expect(dio.options.connectTimeout, equals(Duration(seconds: 60)));
      expect(dio.options.receiveTimeout, equals(Duration(seconds: 60)));
      expect(dio.options.sendTimeout, equals(Duration(seconds: 60)));
    });

    test('should use fallback timeout when no timeouts are specified', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      );

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
        // No default timeout provided
      );

      // Should use fallback timeout (60s)
      expect(dio.options.connectTimeout, equals(Duration(seconds: 60)));
      expect(dio.options.receiveTimeout, equals(Duration(seconds: 60)));
      expect(dio.options.sendTimeout, equals(Duration(seconds: 60)));
    });

    test('should handle different timeout types independently', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
        timeout: Duration(seconds: 45), // LLMConfig timeout
      ).withTransportOptions({
        'connectionTimeout': Duration(seconds: 30), // Custom connection timeout
        'receiveTimeout': Duration(seconds: 120), // Custom receive timeout
        // No custom send timeout - should use LLMConfig timeout
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
        defaultTimeout: Duration(seconds: 60), // Default timeout
      );

      expect(
          dio.options.connectTimeout, equals(Duration(seconds: 30))); // Custom
      expect(
          dio.options.receiveTimeout, equals(Duration(seconds: 120))); // Custom
      expect(
          dio.options.sendTimeout, equals(Duration(seconds: 45))); // LLMConfig
    });

    test('should merge custom headers with default headers', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withTransportOptions({
        'customHeaders': {
          'X-Custom-Header': 'custom-value',
          'X-Another-Header': 'another-value',
        },
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {
          'Authorization': 'Bearer test-key',
          'Content-Type': 'application/json',
        },
        config: config,
      );

      // Should have both default and custom headers
      expect(dio.options.headers['Authorization'], equals('Bearer test-key'));
      expect(dio.options.headers['Content-Type'], equals('application/json'));
      expect(dio.options.headers['X-Custom-Header'], equals('custom-value'));
      expect(dio.options.headers['X-Another-Header'], equals('another-value'));
    });

    test('should allow custom headers to override default headers', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withTransportOptions({
        'customHeaders': {
          'Content-Type': 'application/xml', // Override default
          'X-Custom-Header': 'custom-value',
        },
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {
          'Authorization': 'Bearer test-key',
          'Content-Type': 'application/json', // This should be overridden
        },
        config: config,
      );

      // Custom header should override default
      expect(dio.options.headers['Authorization'], equals('Bearer test-key'));
      expect(dio.options.headers['Content-Type'],
          equals('application/xml')); // Overridden
      expect(dio.options.headers['X-Custom-Header'], equals('custom-value'));
    });

    test('should handle empty custom headers gracefully', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withTransportOptions({
        'customHeaders': <String, String>{}, // Empty map
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {
          'Authorization': 'Bearer test-key',
          'Content-Type': 'application/json',
        },
        config: config,
      );

      // Should only have default headers
      expect(dio.options.headers['Authorization'], equals('Bearer test-key'));
      expect(dio.options.headers['Content-Type'], equals('application/json'));
      expect(dio.options.headers.length, equals(2));
    });

    test('should handle null custom headers gracefully', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      );
      // No customHeaders extension

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {
          'Authorization': 'Bearer test-key',
          'Content-Type': 'application/json',
        },
        config: config,
      );

      // Should only have default headers
      expect(dio.options.headers['Authorization'], equals('Bearer test-key'));
      expect(dio.options.headers['Content-Type'], equals('application/json'));
      expect(dio.options.headers.length, equals(2));
    });

    test('should apply multiple HTTP configurations together', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
        timeout: Duration(seconds: 45),
      ).withTransportOptions({
        'enableHttpLogging': true,
        'connectionTimeout': Duration(seconds: 30),
        'receiveTimeout': Duration(seconds: 120),
        'customHeaders': {
          'X-Custom-Header': 'custom-value',
          'X-Client-Version': '1.0.0',
        },
        'httpProxy': 'http://proxy.example.com:8080',
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {
          'Authorization': 'Bearer test-key',
          'Content-Type': 'application/json',
        },
        config: config,
      );

      // Check timeouts
      expect(dio.options.connectTimeout, equals(Duration(seconds: 30)));
      expect(dio.options.receiveTimeout, equals(Duration(seconds: 120)));
      expect(dio.options.sendTimeout, equals(Duration(seconds: 45)));

      // Check headers
      expect(dio.options.headers['Authorization'], equals('Bearer test-key'));
      expect(dio.options.headers['Content-Type'], equals('application/json'));
      expect(dio.options.headers['X-Custom-Header'], equals('custom-value'));
      expect(dio.options.headers['X-Client-Version'], equals('1.0.0'));

      // Check logging interceptor is added
      expect(dio.interceptors.length, greaterThan(0));

      // Check base URL
      expect(dio.options.baseUrl, equals('https://api.example.com/v1'));
    });
  });
}
