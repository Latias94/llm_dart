/// Test runner for working llm_dart tests
///
/// This file imports and runs only the tests that are currently working.
/// Run with: dart test test/test_working.dart
library;

import 'package:test/test.dart';

// Core tests that are working
import 'core/capability_test.dart' as capability_tests;
import 'core/config_test.dart' as config_tests;
import 'core/error_test.dart' as error_tests;
import 'core/registry_test.dart' as registry_tests;

// Model tests that are working
import 'models/chat_models_test.dart' as chat_models_tests;
import 'models/tool_models_test.dart' as tool_models_tests;

// Existing tests
import 'providers/openai/openai_advanced_test.dart' as openai_advanced_tests;

void main() {
  group('LLM Dart Library - Working Tests', () {
    group('Core System Tests', () {
      capability_tests.main();
      config_tests.main();
      error_tests.main();
      registry_tests.main();
    });

    group('Model Tests', () {
      chat_models_tests.main();
      tool_models_tests.main();
    });

    group('Provider Tests', () {
      openai_advanced_tests.main();
    });
  });
}
