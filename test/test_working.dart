/// Test runner for focused root tests that are still meaningful after the
/// root legacy provider/builder/model implementation was removed.
///
/// Run with: dart test test/test_working.dart
library;

import 'package:test/test.dart';

import 'ai_entrypoint_test.dart' as ai_entrypoint_tests;
import 'chat_entrypoint_test.dart' as chat_entrypoint_tests;
import 'modern_facade_test.dart' as modern_facade_tests;
import 'openai_family_entrypoints_test.dart' as openai_family_tests;

void main() {
  group('LLM Dart Library - Working Tests', () {
    ai_entrypoint_tests.main();
    chat_entrypoint_tests.main();
    modern_facade_tests.main();
    openai_family_tests.main();
  });
}
