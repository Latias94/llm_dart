/// Minimal test runner for verified working tests
///
/// This file imports and runs only the tests that are verified to work.
/// Run with: dart test test/test_minimal.dart
library;

import 'package:test/test.dart';

// Only the tests that are confirmed working
import 'core/capability_test.dart' as capability_tests;
import 'core/error_test.dart' as error_tests;
import 'models/chat_models_test.dart' as chat_models_tests;

void main() {
  group('LLM Dart Library - Minimal Working Tests', () {
    group('Core System Tests', () {
      capability_tests.main();
      error_tests.main();
    });

    group('Model Tests', () {
      chat_models_tests.main();
    });
  });
}
