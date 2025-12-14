/// Comprehensive Dio HTTP Configuration Test Suite
///
/// This file runs all Dio-related tests to ensure the HTTP configuration
/// system is working correctly across all providers and scenarios.
///
/// Test Categories:
/// 1. Client Configuration Tests - Verify providers use unified HTTP config
/// 2. Logging Tests - Verify HTTP request/response logging works
/// 3. Configuration Priority Tests - Verify config precedence rules
/// 4. Error Handling Tests - Verify error logging and handling
/// 5. Advanced Features Tests - Verify proxy, SSL, and other features
/// 6. End-to-End Integration Tests - Verify complete workflows
///
/// Usage:
/// ```bash
/// dart test test/test_dio_comprehensive.dart
/// ```
library;

import 'package:test/test.dart';

// Import all Dio-related test files
import 'utils/dio/dio_client_configuration_test.dart' as client_config_tests;
import 'utils/dio/dio_logging_test.dart' as logging_tests;
import 'utils/dio/dio_configuration_priority_test.dart' as priority_tests;
import 'utils/dio/dio_advanced_features_test.dart' as advanced_features_tests;
import 'integration/dio_end_to_end_test.dart' as end_to_end_tests;

// Import existing HTTP-related tests
import 'utils/http_config_utils_test.dart' as http_config_utils_tests;
import 'utils/dio/dio_proxy_test.dart' as dio_proxy_tests;
import 'integration/http_configuration_integration_test.dart'
    as http_integration_tests;
import 'builder/http_config_test.dart' as http_builder_tests;

void main() {
  group('🔧 Comprehensive Dio HTTP Configuration Test Suite', () {
    group('📋 1. Client Configuration Tests', () {
      client_config_tests.main();
    });

    group('📝 2. HTTP Logging Tests', () {
      logging_tests.main();
    });

    group('⚖️ 3. Configuration Priority Tests', () {
      priority_tests.main();
    });

    group('🔒 4. Advanced Features Tests', () {
      advanced_features_tests.main();
    });

    group('🔄 5. End-to-End Integration Tests', () {
      end_to_end_tests.main();
    });

    group('🛠️ 6. Existing HTTP Configuration Tests', () {
      group('HTTP Config Utils', () {
        http_config_utils_tests.main();
      });

      group('Dio Proxy Configuration', () {
        dio_proxy_tests.main();
      });

      group('HTTP Configuration Integration', () {
        http_integration_tests.main();
      });

      group('HTTP Builder Configuration', () {
        http_builder_tests.main();
      });
    });
  });
}

/// Test Summary and Documentation
///
/// This comprehensive test suite covers:
///
/// ## 1. Client Configuration Tests
/// - ✅ Anthropic client uses unified HTTP config when available
/// - ✅ OpenAI client uses unified HTTP config when available
/// - ✅ DeepSeek client uses unified HTTP config when available
/// - ✅ Groq client uses unified HTTP config when available
/// - ✅ xAI client uses unified HTTP config when available
/// - ✅ Google client uses unified HTTP config when available
/// - ✅ Ollama client uses unified HTTP config when available
/// - ✅ All clients fall back to simple Dio when no config available
///
/// ## 2. HTTP Logging Tests
/// - ✅ Logging interceptor added when enableHttpLogging=true
/// - ✅ No logging interceptor when enableHttpLogging=false
/// - ✅ Request information logged (URL, headers, data)
/// - ✅ Response information logged (status, headers)
/// - ✅ Error information logged (URL, error details)
/// - ✅ Correct log levels used (INFO, FINE, SEVERE)
/// - ✅ POST request data logged when available
///
/// ## 3. Configuration Priority Tests
/// - ✅ Custom timeouts override LLMConfig timeouts
/// - ✅ LLMConfig timeouts override default timeouts
/// - ✅ Default timeouts used when no others specified
/// - ✅ Fallback timeouts used when nothing specified
/// - ✅ Different timeout types handled independently
/// - ✅ Custom headers merged with default headers
/// - ✅ Custom headers can override default headers
/// - ✅ Empty/null custom headers handled gracefully
/// - ✅ Multiple configurations applied together
///
/// ## 4. Error Handling Tests
/// - ✅ Connection timeout errors logged
/// - ✅ HTTP status errors logged (404, 401, 500)
/// - ✅ Network errors handled gracefully
/// - ✅ No error logs when logging disabled
/// - ✅ Original error information preserved
/// - ✅ Malformed response data handled gracefully
/// - ✅ Large response data handled gracefully
///
/// ## 5. Advanced Features Tests
/// - ✅ HTTP proxy configuration
/// - ✅ Proxy with authentication
/// - ✅ HTTPS proxy support
/// - ✅ SSL bypass configuration
/// - ✅ SSL certificate configuration
/// - ✅ Combined proxy and SSL configuration
/// - ✅ All advanced features together
/// - ✅ Invalid configurations handled gracefully
/// - ✅ HTTP client adapter configuration
///
/// ## 6. End-to-End Integration Tests
/// - ✅ HTTP config through LLMBuilder for all providers
/// - ✅ Complex HTTP configuration scenarios
/// - ✅ Works without HTTP configuration
/// - ✅ Streaming with HTTP configuration
/// - ✅ Error scenarios with HTTP configuration
///
/// ## 7. Existing HTTP Configuration Tests
/// - ✅ HttpConfigUtils functionality
/// - ✅ Dio proxy configuration
/// - ✅ HTTP configuration integration
/// - ✅ HTTP builder configuration
///
/// ## Key Benefits of This Test Suite:
///
/// 1. **Complete Coverage**: Tests all aspects of HTTP configuration
/// 2. **Provider Consistency**: Ensures all providers work the same way
/// 3. **Regression Prevention**: Catches breaking changes early
/// 4. **Documentation**: Serves as living documentation of features
/// 5. **Debugging Aid**: Helps identify issues quickly
/// 6. **Quality Assurance**: Ensures robust HTTP handling
///
/// ## Running Tests:
///
/// ```bash
/// # Run all Dio tests
/// dart test test/test_dio_comprehensive.dart
///
/// # Run specific test groups
/// dart test test/utils/dio_logging_test.dart
/// dart test test/integration/dio_end_to_end_test.dart
///
/// # Run with verbose output
/// dart test test/test_dio_comprehensive.dart --reporter=expanded
/// ```
