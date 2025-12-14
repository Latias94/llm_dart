/// Complete test suite for OpenAI Responses API
///
/// This file runs all OpenAI Responses API related tests in a single suite.
/// Run with: dart test test/providers/openai/responses_test_suite.dart
library;

import 'package:test/test.dart';

// Import all OpenAI Responses API test files
import 'responses_test.dart' as config_tests;
import 'responses_stateful_test.dart' as stateful_tests;
import 'responses_comprehensive_test.dart' as comprehensive_tests;
import 'responses_error_handling_test.dart' as error_tests;
import 'responses_functionality_test.dart' as functionality_tests;

void main() {
  group('OpenAI Responses API Complete Test Suite', () {
    group('Configuration Tests', () {
      config_tests.main();
    });

    group('Stateful Features Tests', () {
      stateful_tests.main();
    });

    group('Comprehensive Feature Tests', () {
      comprehensive_tests.main();
    });

    group('Error Handling Tests', () {
      error_tests.main();
    });

    group('Functionality Tests', () {
      functionality_tests.main();
    });
  });
}
