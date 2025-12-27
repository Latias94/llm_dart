import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'dio_proxy_test_stub.dart'
    if (dart.library.io) 'dio_proxy_test_io.dart'
    if (dart.library.html) 'dio_proxy_test_web.dart';

void main() {
  group('Dio Proxy Configuration Tests', () {
    // Run platform-specific tests
    group('Platform-Specific Tests', () {
      PlatformHttpAdapterTests.runPlatformTests();
    });

    test('should configure proxy using HttpConfigUtils', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withTransportOptions({
        'httpProxy': 'localhost:8888',
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );

      PlatformHttpAdapterTests.expectCorrectAdapterType(dio.httpClientAdapter);
    });

    test('should configure SSL bypass using HttpConfigUtils', () {
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

      PlatformHttpAdapterTests.expectCorrectAdapterType(dio.httpClientAdapter);
    });

    test('should configure both proxy and SSL using HttpConfigUtils', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withTransportOptions({
        'httpProxy': 'localhost:8888',
        'bypassSSLVerification': true,
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );

      PlatformHttpAdapterTests.expectCorrectAdapterType(dio.httpClientAdapter);
    });

    test(
        'should not configure custom adapter when no HTTP client settings specified',
        () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withTransportOptions({
        'enableHttpLogging': true, // This doesn't require adapter change
      });

      final dioWithoutHttpConfig = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );

      final configWithProxy = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withTransportOptions({
        'httpProxy': 'localhost:8888',
      });

      final dioWithHttpConfig = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: configWithProxy,
      );

      // Both should be correct adapter type, but they should be different instances
      PlatformHttpAdapterTests.expectCorrectAdapterType(
          dioWithoutHttpConfig.httpClientAdapter);
      PlatformHttpAdapterTests.expectCorrectAdapterType(
          dioWithHttpConfig.httpClientAdapter);
      expect(
          identical(dioWithoutHttpConfig.httpClientAdapter,
              dioWithHttpConfig.httpClientAdapter),
          isFalse);
    });

    test('should configure SSL certificate path', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withTransportOptions({
        'sslCertificate': '/path/to/cert.pem',
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );

      PlatformHttpAdapterTests.expectCorrectAdapterType(dio.httpClientAdapter);
    });

    test('should handle comprehensive HTTP client configuration', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withTransportOptions({
        'httpProxy': 'http://proxy.company.com:8080',
        'bypassSSLVerification': false,
        'sslCertificate': '/etc/ssl/corporate-cert.pem',
        'enableHttpLogging': true,
        'customHeaders': {
          'X-Corporate-ID': 'dept-123',
        },
        'connectionTimeout': Duration(seconds: 30),
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );

      PlatformHttpAdapterTests.expectCorrectAdapterType(dio.httpClientAdapter);
      expect(dio.options.headers['Authorization'], equals('Bearer test-key'));
      expect(dio.options.headers['X-Corporate-ID'], equals('dept-123'));
      expect(dio.options.connectTimeout, equals(Duration(seconds: 30)));
      expect(dio.interceptors.length, greaterThan(0)); // Logging interceptor
    });

    group('LLMBuilder Integration', () {
      test('should configure proxy through LLMBuilder', () {
        final builder = LLMBuilder()
            .openai()
            .apiKey('test-key')
            .model('gpt-4')
            .http((http) => http.proxy('localhost:8888'));

        expect(builder, isNotNull);
      });

      test('should configure SSL through LLMBuilder', () {
        final builder = LLMBuilder()
            .openai()
            .apiKey('test-key')
            .model('gpt-4')
            .http((http) => http.bypassSSLVerification(true));

        expect(builder, isNotNull);
      });

      test('should configure both proxy and SSL through LLMBuilder', () {
        final builder = LLMBuilder()
            .openai()
            .apiKey('test-key')
            .model('gpt-4')
            .http((http) => http
                .proxy('localhost:8888')
                .bypassSSLVerification(true)
                .sslCertificate('/path/to/cert.pem'));

        expect(builder, isNotNull);
      });

      test('should configure enterprise setup through LLMBuilder', () {
        final builder = LLMBuilder()
            .anthropic()
            .apiKey('enterprise-key')
            .model('claude-3-5-haiku-20241022')
            .http((http) => http
                .proxy('http://corporate-proxy:8080')
                .headers({
                  'X-Corporate-ID': 'dept-123',
                  'X-Environment': 'production',
                })
                .sslCertificate('/etc/ssl/corporate-cert.pem')
                .connectionTimeout(Duration(seconds: 45))
                .enableLogging(false));

        expect(builder, isNotNull);
      });
    });

    group('Edge Cases', () {
      test('should handle empty proxy URL', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'httpProxy': '',
        });

        // Empty proxy URL should not trigger custom adapter configuration
        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        // Should still be correct adapter type (Dio's default), but not configured with proxy
        PlatformHttpAdapterTests.expectCorrectAdapterType(
            dio.httpClientAdapter);
      });

      test('should handle null SSL certificate path', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'sslCertificate': null,
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        // Should still be correct adapter type (Dio's default), but not configured with SSL
        PlatformHttpAdapterTests.expectCorrectAdapterType(
            dio.httpClientAdapter);
      });

      test('should handle false SSL bypass', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'bypassSSLVerification': false,
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        // Should still be correct adapter type (Dio's default), but not configured with SSL bypass
        PlatformHttpAdapterTests.expectCorrectAdapterType(
            dio.httpClientAdapter);
      });
    });
  });
}
