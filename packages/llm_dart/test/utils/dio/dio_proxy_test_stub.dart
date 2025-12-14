import 'package:test/test.dart';
import 'package:dio/dio.dart';

/// Stub implementation for platform-specific HTTP adapter tests
class PlatformHttpAdapterTests {
  /// Run platform-specific HTTP adapter tests
  static void runPlatformTests() {
    test('platform not supported - stub implementation', () {
      expect(true, isTrue); // Placeholder test
    });
  }

  /// Check if the HTTP adapter is the expected type for this platform
  static void expectCorrectAdapterType(HttpClientAdapter adapter) {
    // Stub implementation - no specific expectations
    expect(adapter, isNotNull);
  }

  /// Get the expected adapter type name for this platform
  static String get expectedAdapterTypeName => 'HttpClientAdapter';
}
