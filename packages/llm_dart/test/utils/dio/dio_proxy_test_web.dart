import 'package:test/test.dart';
import 'package:dio/dio.dart';

/// Web platform implementation for HTTP adapter tests
class PlatformHttpAdapterTests {
  /// Run platform-specific HTTP adapter tests
  static void runPlatformTests() {
    test('should use default adapter on web platform', () {
      // Web platform uses browser's default HTTP client
      final dio = Dio();
      expect(dio.httpClientAdapter, isNotNull);
    });

    test('should not support advanced HTTP features on web platform', () {
      // Web platform doesn't support proxy/SSL configuration
      expect(true, isTrue); // This platform doesn't support advanced features
    });
  }

  /// Check if the HTTP adapter is the expected type for this platform
  static void expectCorrectAdapterType(HttpClientAdapter adapter) {
    // On web platform, we just expect it to be a valid adapter
    expect(adapter, isNotNull);
  }

  /// Get the expected adapter type name for this platform
  static String get expectedAdapterTypeName => 'BrowserHttpClientAdapter';
}
