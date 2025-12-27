import 'package:test/test.dart';
import 'package:dio/dio.dart';
import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'dio_proxy_test_stub.dart'
    if (dart.library.io) 'dio_proxy_test_io.dart'
    if (dart.library.html) 'dio_proxy_test_web.dart';

void main() {
  group('Dio Advanced Features Tests', () {
    group('Proxy Configuration', () {
      test('should configure HTTP proxy when specified', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'httpProxy': 'http://proxy.example.com:8080',
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        expect(dio, isA<Dio>());
        PlatformHttpAdapterTests.expectCorrectAdapterType(
            dio.httpClientAdapter);

        // The adapter should be configured (we can't easily test the internal proxy settings
        // without making actual requests, but we can verify the adapter type)
      });

      test('should handle proxy with authentication', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'httpProxy': 'http://user:pass@proxy.example.com:8080',
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        expect(dio, isA<Dio>());
        PlatformHttpAdapterTests.expectCorrectAdapterType(
            dio.httpClientAdapter);
      });

      test('should handle HTTPS proxy', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'httpProxy': 'https://proxy.example.com:8080',
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        expect(dio, isA<Dio>());
        PlatformHttpAdapterTests.expectCorrectAdapterType(
            dio.httpClientAdapter);
      });

      test('should not configure proxy when not specified', () {
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
        // Should use default adapter when no proxy is configured
        PlatformHttpAdapterTests.expectCorrectAdapterType(
            dio.httpClientAdapter);
      });
    });

    group('SSL Configuration', () {
      test('should configure SSL bypass when specified', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'bypassSSLVerification': true,
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        expect(dio, isA<Dio>());
        PlatformHttpAdapterTests.expectCorrectAdapterType(
            dio.httpClientAdapter);
      });

      test('should configure SSL certificate when specified', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'sslCertificate': '/path/to/certificate.pem',
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        expect(dio, isA<Dio>());
        PlatformHttpAdapterTests.expectCorrectAdapterType(
            dio.httpClientAdapter);
      });

      test('should handle both SSL bypass and certificate', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'bypassSSLVerification': false,
          'sslCertificate': '/path/to/certificate.pem',
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        expect(dio, isA<Dio>());
        PlatformHttpAdapterTests.expectCorrectAdapterType(
            dio.httpClientAdapter);
      });

      test('should not configure SSL when not specified', () {
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
        // Should use default adapter when no SSL configuration
        PlatformHttpAdapterTests.expectCorrectAdapterType(
            dio.httpClientAdapter);
      });
    });

    group('Combined Advanced Features', () {
      test('should configure proxy and SSL together', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'httpProxy': 'http://proxy.example.com:8080',
          'bypassSSLVerification': true,
          'sslCertificate': '/path/to/certificate.pem',
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        expect(dio, isA<Dio>());
        PlatformHttpAdapterTests.expectCorrectAdapterType(
            dio.httpClientAdapter);
      });

      test('should configure all advanced features together', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
          timeout: Duration(seconds: 45),
        ).withTransportOptions({
          'enableHttpLogging': true,
          'httpProxy': 'http://proxy.example.com:8080',
          'bypassSSLVerification': false,
          'sslCertificate': '/path/to/certificate.pem',
          'connectionTimeout': Duration(seconds: 30),
          'receiveTimeout': Duration(seconds: 120),
          'sendTimeout': Duration(seconds: 60),
          'customHeaders': {
            'X-Custom-Header': 'custom-value',
            'X-Client-Version': '1.0.0',
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

        expect(dio, isA<Dio>());
        PlatformHttpAdapterTests.expectCorrectAdapterType(
            dio.httpClientAdapter);

        // Check timeouts
        expect(dio.options.connectTimeout, equals(Duration(seconds: 30)));
        expect(dio.options.receiveTimeout, equals(Duration(seconds: 120)));
        expect(dio.options.sendTimeout, equals(Duration(seconds: 60)));

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

      test('should handle invalid proxy configuration gracefully', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'httpProxy': 'invalid-proxy-url',
        });

        // Should not throw an exception during configuration
        expect(() {
          final dio = HttpConfigUtils.createConfiguredDio(
            baseUrl: 'https://api.example.com/v1',
            defaultHeaders: {'Authorization': 'Bearer test-key'},
            config: config,
          );
          expect(dio, isA<Dio>());
        }, returnsNormally);
      });

      test('should handle empty proxy configuration gracefully', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'httpProxy': '',
        });

        // Should not throw an exception during configuration
        expect(() {
          final dio = HttpConfigUtils.createConfiguredDio(
            baseUrl: 'https://api.example.com/v1',
            defaultHeaders: {'Authorization': 'Bearer test-key'},
            config: config,
          );
          expect(dio, isA<Dio>());
        }, returnsNormally);
      });

      test('should handle empty SSL certificate path gracefully', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'sslCertificate': '',
        });

        // Should not throw an exception during configuration
        expect(() {
          final dio = HttpConfigUtils.createConfiguredDio(
            baseUrl: 'https://api.example.com/v1',
            defaultHeaders: {'Authorization': 'Bearer test-key'},
            config: config,
          );
          expect(dio, isA<Dio>());
        }, returnsNormally);
      });
    });

    group('HTTP Client Adapter Configuration', () {
      test(
          'should only configure custom adapter when HTTP client settings are present',
          () {
        final configWithoutHttpSettings = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'enableHttpLogging': true, // This doesn't require adapter change
        });

        final dioWithoutHttpConfig = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: configWithoutHttpSettings,
        );

        final configWithHttpSettings = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'httpProxy': 'http://proxy.example.com:8080',
        });

        final dioWithHttpConfig = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: configWithHttpSettings,
        );

        // Both should have correct adapter type, but the one with HTTP settings
        // should have a custom configured adapter
        PlatformHttpAdapterTests.expectCorrectAdapterType(
            dioWithoutHttpConfig.httpClientAdapter);
        PlatformHttpAdapterTests.expectCorrectAdapterType(
            dioWithHttpConfig.httpClientAdapter);
      });
    });
  });
}
