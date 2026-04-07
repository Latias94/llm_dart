import 'package:dio/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderDioClientFactory', () {
    test('creates Dio from strategy and overrides', () {
      final dio = ProviderDioClientFactory.create(
        strategy: _TestStrategy(),
        config: const _TestConfig(),
        overrides: const _TestOverrides(
          customHeaders: {'X-Custom': '1'},
          timeout: Duration(seconds: 12),
          connectionTimeout: Duration(seconds: 3),
        ),
      );

      expect(dio.options.baseUrl, 'https://example.com');
      expect(dio.options.headers['Authorization'], 'Bearer test');
      expect(dio.options.headers['X-Custom'], '1');
      expect(dio.options.connectTimeout, const Duration(seconds: 3));
      expect(dio.options.receiveTimeout, const Duration(seconds: 12));
    });

    test('reuses custom Dio and applies provider enhancements', () {
      final customDio = Dio()..options.headers['X-Existing'] = '1';

      final dio = ProviderDioClientFactory.create(
        strategy: _TestStrategy(),
        config: const _TestConfig(),
        overrides: _MutableTestOverrides(customDio: customDio),
      );

      expect(dio, same(customDio));
      expect(dio.options.baseUrl, 'https://example.com');
      expect(dio.options.headers['Authorization'], 'Bearer test');
      expect(dio.options.headers['X-Existing'], '1');
    });
  });
}

final class _TestStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'Test';

  @override
  Map<String, String> buildHeaders(dynamic config) => const {
        'Authorization': 'Bearer test',
      };

  @override
  String getBaseUrl(dynamic config) => 'https://example.com';
}

final class _TestConfig {
  const _TestConfig();
}

final class _TestOverrides implements DioClientOverrides {
  final Map<String, String> _customHeaders;
  final Duration? _timeout;
  final Duration? _connectionTimeout;

  const _TestOverrides({
    Map<String, String> customHeaders = const <String, String>{},
    Duration? timeout,
    Duration? connectionTimeout,
  })  : _customHeaders = customHeaders,
        _timeout = timeout,
        _connectionTimeout = connectionTimeout;

  @override
  bool get bypassSslVerification => false;

  @override
  String? get certificatePath => null;

  @override
  Duration? get connectionTimeout => _connectionTimeout;

  @override
  Dio? get customDio => null;

  @override
  Map<String, String> get customHeaders => _customHeaders;

  @override
  bool get enableHttpLogging => false;

  @override
  String? get proxyUrl => null;

  @override
  Duration? get receiveTimeout => null;

  @override
  Duration? get sendTimeout => null;

  @override
  Duration? get timeout => _timeout;
}

final class _MutableTestOverrides extends _TestOverrides {
  final Dio _customDio;

  _MutableTestOverrides({required Dio customDio}) : _customDio = customDio;

  @override
  Dio? get customDio => _customDio;
}
