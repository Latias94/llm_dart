import 'package:test/test.dart';
import 'package:dio/dio.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('HttpConfigUtils Tests', () {
    group('createConfiguredDio', () {
      test('should create Dio with basic configuration', () {
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

        expect(dio, isA<Dio>());
        expect(dio.options.baseUrl, equals('https://api.example.com/v1'));
        expect(dio.options.headers['Authorization'], equals('Bearer test-key'));
      });

      test('should apply custom headers from config', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withExtensions({
          LLMConfigKeys.customHeaders: {
            'X-Custom-Header': 'custom-value',
            'User-Agent': 'TestApp/1.0',
          }
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        expect(dio.options.headers['Authorization'], equals('Bearer test-key'));
        expect(dio.options.headers['X-Custom-Header'], equals('custom-value'));
        expect(dio.options.headers['User-Agent'], equals('TestApp/1.0'));
      });

      test('should override default headers with custom headers', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withExtensions({
          LLMConfigKeys.customHeaders: {
            'Authorization': 'Bearer custom-key',
          }
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer default-key'},
          config: config,
        );

        expect(
            dio.options.headers['Authorization'], equals('Bearer custom-key'));
      });

      test('should apply timeout configurations', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
          timeout: Duration(seconds: 60),
        ).withExtensions({
          LLMConfigKeys.connectionTimeout: Duration(seconds: 30),
          LLMConfigKeys.receiveTimeout: Duration(minutes: 5),
          LLMConfigKeys.sendTimeout: Duration(seconds: 120),
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        expect(dio.options.connectTimeout, equals(Duration(seconds: 30)));
        expect(dio.options.receiveTimeout, equals(Duration(minutes: 5)));
        expect(dio.options.sendTimeout, equals(Duration(seconds: 120)));
      });

      test('should use default timeout when custom timeouts not specified', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        );

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
          defaultTimeout: Duration(seconds: 45),
        );

        expect(dio.options.connectTimeout, equals(Duration(seconds: 45)));
        expect(dio.options.receiveTimeout, equals(Duration(seconds: 45)));
        expect(dio.options.sendTimeout, equals(Duration(seconds: 45)));
      });

      test('should add logging interceptor when enabled', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withExtensions({
          LLMConfigKeys.enableHttpLogging: true,
        });

        final dioWithLogging = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        // Create a dio without logging for comparison
        final configWithoutLogging = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        );

        final dioWithoutLogging = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: configWithoutLogging,
        );

        expect(dioWithLogging.interceptors.length,
            greaterThan(dioWithoutLogging.interceptors.length));
      });

      test('should not add logging interceptor when disabled', () {
        final configDisabled = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withExtensions({
          LLMConfigKeys.enableHttpLogging: false,
        });

        final configDefault = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        );

        final dioDisabled = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: configDisabled,
        );

        final dioDefault = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: configDefault,
        );

        // Both should have the same number of interceptors (no logging interceptor added)
        expect(dioDisabled.interceptors.length,
            equals(dioDefault.interceptors.length));
      });
    });

    group('createSimpleDio', () {
      test('should create simple Dio instance', () {
        final dio = HttpConfigUtils.createSimpleDio(
          baseUrl: 'https://api.example.com/v1',
          headers: {'Authorization': 'Bearer test-key'},
        );

        expect(dio, isA<Dio>());
        expect(dio.options.baseUrl, equals('https://api.example.com/v1'));
        expect(dio.options.headers['Authorization'], equals('Bearer test-key'));
        expect(dio.options.connectTimeout, equals(Duration(seconds: 60)));
        expect(dio.options.receiveTimeout, equals(Duration(seconds: 60)));
      });

      test('should apply custom timeout', () {
        final dio = HttpConfigUtils.createSimpleDio(
          baseUrl: 'https://api.example.com/v1',
          headers: {'Authorization': 'Bearer test-key'},
          timeout: Duration(seconds: 30),
        );

        expect(dio.options.connectTimeout, equals(Duration(seconds: 30)));
        expect(dio.options.receiveTimeout, equals(Duration(seconds: 30)));
      });
    });

    group('validateHttpConfig', () {
      test('should not throw for valid configuration', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
          timeout: Duration(seconds: 60),
        ).withExtensions({
          LLMConfigKeys.connectionTimeout: Duration(seconds: 60),
          LLMConfigKeys.receiveTimeout: Duration(seconds: 60),
          LLMConfigKeys.httpProxy: 'http://proxy.example.com:8080',
        });

        expect(
            () => HttpConfigUtils.validateHttpConfig(config), returnsNormally);
      });

      test('should handle configuration without extensions', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        );

        expect(
            () => HttpConfigUtils.validateHttpConfig(config), returnsNormally);
      });

      test('should handle empty extensions', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withExtensions({});

        expect(
            () => HttpConfigUtils.validateHttpConfig(config), returnsNormally);
      });

      test('should validate proxy URL format', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withExtensions({
          LLMConfigKeys.httpProxy: 'invalid-proxy-url',
        });

        // Should not throw, but may log warnings
        expect(
            () => HttpConfigUtils.validateHttpConfig(config), returnsNormally);
      });

      test('should handle SSL bypass configuration', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withExtensions({
          LLMConfigKeys.bypassSSLVerification: true,
        });

        // Should not throw, but may log warnings
        expect(
            () => HttpConfigUtils.validateHttpConfig(config), returnsNormally);
      });
    });

    group('Timeout Configuration Logic', () {
      test('should prioritize custom timeout over global timeout', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
          timeout: Duration(seconds: 60),
        ).withExtensions({
          LLMConfigKeys.connectionTimeout: Duration(seconds: 30),
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        expect(dio.options.connectTimeout, equals(Duration(seconds: 30)));
        expect(dio.options.receiveTimeout,
            equals(Duration(seconds: 60))); // Falls back to global
      });

      test('should use default timeout when no timeouts specified', () {
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

        expect(dio.options.connectTimeout, equals(Duration(seconds: 60)));
        expect(dio.options.receiveTimeout, equals(Duration(seconds: 60)));
        expect(dio.options.sendTimeout, equals(Duration(seconds: 60)));
      });
    });

    group('Header Merging Logic', () {
      test('should merge headers correctly', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withExtensions({
          LLMConfigKeys.customHeaders: {
            'X-Custom': 'custom-value',
            'User-Agent': 'CustomApp/1.0',
          }
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {
            'Authorization': 'Bearer test-key',
            'Content-Type': 'application/json',
          },
          config: config,
        );

        expect(dio.options.headers['Authorization'], equals('Bearer test-key'));
        expect(dio.options.headers['Content-Type'], equals('application/json'));
        expect(dio.options.headers['X-Custom'], equals('custom-value'));
        expect(dio.options.headers['User-Agent'], equals('CustomApp/1.0'));
      });

      test('should handle empty custom headers', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withExtensions({
          LLMConfigKeys.customHeaders: <String, String>{},
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        expect(dio.options.headers['Authorization'], equals('Bearer test-key'));
      });
    });
  });
}
