import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

void main() {
  group('Timeout Priority Tests', () {
    test('should use HTTP-specific timeout over global timeout', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
        timeout: Duration(minutes: 2), // Global timeout
      ).withTransportOptions({
        'connectionTimeout': Duration(seconds: 30), // HTTP-specific timeout
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );

      // Should use HTTP-specific timeout (30s), not global timeout (2min)
      expect(dio.options.connectTimeout, equals(Duration(seconds: 30)));
      // Should use global timeout for other timeouts
      expect(dio.options.receiveTimeout, equals(Duration(minutes: 2)));
      expect(dio.options.sendTimeout, equals(Duration(minutes: 2)));
    });

    test('should use global timeout when no HTTP-specific timeout', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
        timeout: Duration(minutes: 3), // Global timeout
      );

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );

      // Should use global timeout for all timeouts
      expect(dio.options.connectTimeout, equals(Duration(minutes: 3)));
      expect(dio.options.receiveTimeout, equals(Duration(minutes: 3)));
      expect(dio.options.sendTimeout, equals(Duration(minutes: 3)));
    });

    test('should use default timeout when no global or HTTP-specific timeout',
        () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
        // No timeout set
      );

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
      );

      // Should use system default timeout (60s)
      expect(dio.options.connectTimeout, equals(Duration(seconds: 60)));
      expect(dio.options.receiveTimeout, equals(Duration(seconds: 60)));
      expect(dio.options.sendTimeout, equals(Duration(seconds: 60)));
    });

    test('should use provider default timeout when specified', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
        // No timeout set
      );

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
        defaultTimeout: Duration(seconds: 45), // Provider default
      );

      // Should use provider default timeout (45s)
      expect(dio.options.connectTimeout, equals(Duration(seconds: 45)));
      expect(dio.options.receiveTimeout, equals(Duration(seconds: 45)));
      expect(dio.options.sendTimeout, equals(Duration(seconds: 45)));
    });

    test('should handle mixed timeout configurations', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
        timeout: Duration(minutes: 2), // Global timeout
      ).withTransportOptions({
        'connectionTimeout': Duration(seconds: 15), // Override connection
        'receiveTimeout': Duration(minutes: 5), // Override receive
        // sendTimeout not specified, should use global
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
        defaultTimeout: Duration(seconds: 30), // Provider default (ignored)
      );

      // Should use HTTP-specific timeouts where specified, global otherwise
      expect(dio.options.connectTimeout,
          equals(Duration(seconds: 15))); // HTTP-specific
      expect(dio.options.receiveTimeout,
          equals(Duration(minutes: 5))); // HTTP-specific
      expect(dio.options.sendTimeout,
          equals(Duration(minutes: 2))); // Global fallback
    });

    test('should demonstrate complete priority chain', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
        timeout: Duration(minutes: 2), // Global timeout
      ).withTransportOptions({
        'connectionTimeout': Duration(seconds: 20), // Highest priority
        // receiveTimeout not set - will use global
        // sendTimeout not set - will use global
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1',
        defaultHeaders: {'Authorization': 'Bearer test-key'},
        config: config,
        defaultTimeout: Duration(seconds: 45), // Lowest priority (ignored)
      );

      // Priority demonstration:
      // 1. HTTP-specific (connectionTimeout) = 20s
      // 2. Global timeout (receiveTimeout, sendTimeout) = 2min
      // 3. Provider default (ignored because global exists) = 45s
      // 4. System default (ignored) = 60s
      expect(dio.options.connectTimeout, equals(Duration(seconds: 20)));
      expect(dio.options.receiveTimeout, equals(Duration(minutes: 2)));
      expect(dio.options.sendTimeout, equals(Duration(minutes: 2)));
    });

    group('LLMBuilder Integration', () {
      test('should demonstrate timeout() method setting global timeout', () {
        // This test shows how the new timeout() method works
        final builder = LLMBuilder()
            .openai()
            .apiKey('test-key')
            .model('gpt-4')
            .timeout(Duration(minutes: 3)); // Sets global timeout

        expect(builder, isNotNull);
        // The actual timeout values would be tested in integration tests
      });

      test('should demonstrate HTTP config overriding global timeout', () {
        final builder = LLMBuilder()
            .openai()
            .apiKey('test-key')
            .model('gpt-4')
            .timeout(Duration(minutes: 2)) // Global: 2 minutes
            .http((http) => http
                .connectionTimeout(Duration(seconds: 30)) // Override connection
                .receiveTimeout(Duration(minutes: 5))); // Override receive
        // sendTimeout will use global (2 minutes)

        expect(builder, isNotNull);
      });

      test('should demonstrate mixed configuration scenarios', () {
        // Scenario 1: Only global timeout
        final builder1 = LLMBuilder()
            .openai()
            .apiKey('test-key')
            .timeout(Duration(minutes: 2));

        // Scenario 2: Only HTTP timeouts
        final builder2 = LLMBuilder().openai().apiKey('test-key').http((http) =>
            http
                .connectionTimeout(Duration(seconds: 30))
                .receiveTimeout(Duration(minutes: 5))
                .sendTimeout(Duration(seconds: 90)));

        // Scenario 3: Mixed (global + HTTP overrides)
        final builder3 = LLMBuilder()
            .openai()
            .apiKey('test-key')
            .timeout(Duration(minutes: 2))
            .http((http) => http.receiveTimeout(Duration(minutes: 10)));

        expect(builder1, isNotNull);
        expect(builder2, isNotNull);
        expect(builder3, isNotNull);
      });
    });

    group('Edge Cases', () {
      test('should handle zero timeout values', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
          timeout: Duration.zero, // Zero global timeout
        ).withTransportOptions({
          'connectionTimeout': Duration.zero, // Zero HTTP timeout
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        expect(dio.options.connectTimeout, equals(Duration.zero));
        expect(dio.options.receiveTimeout, equals(Duration.zero));
        expect(dio.options.sendTimeout, equals(Duration.zero));
      });

      test('should handle very large timeout values', () {
        final config = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
          timeout: Duration(hours: 1), // Large global timeout
        ).withTransportOptions({
          'receiveTimeout': Duration(hours: 2), // Even larger HTTP timeout
        });

        final dio = HttpConfigUtils.createConfiguredDio(
          baseUrl: 'https://api.example.com/v1',
          defaultHeaders: {'Authorization': 'Bearer test-key'},
          config: config,
        );

        expect(dio.options.connectTimeout, equals(Duration(hours: 1)));
        expect(dio.options.receiveTimeout, equals(Duration(hours: 2)));
        expect(dio.options.sendTimeout, equals(Duration(hours: 1)));
      });
    });
  });
}
