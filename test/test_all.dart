/// Test runner for all llm_dart tests
///
/// This file imports and runs all test suites in the project.
/// Run with: dart test test/test_all.dart
library;

import 'package:test/test.dart';

// Utils tests
import 'utils/utf8_stream_decoder_test.dart' as utf8_decoder_tests;

// Tool tests
import 'tool/bootstrap_workspace_pubspec_overrides_test.dart'
    as bootstrap_overrides_tool_tests;
import 'tool/check_example_api_guards_test.dart'
    as example_api_guard_tool_tests;
import 'tool/check_openai_provider_layout_guard_test.dart'
    as openai_provider_layout_guard_tool_tests;
import 'tool/check_pub_version_availability_test.dart'
    as pub_version_availability_tool_tests;
import 'tool/check_provider_replay_metadata_guards_test.dart'
    as provider_replay_metadata_guard_tool_tests;
import 'tool/check_workspace_dependency_guards_test.dart'
    as dependency_guard_tool_tests;
import 'tool/check_root_package_boundary_guards_test.dart'
    as root_boundary_guard_tool_tests;
import 'tool/check_test_legacy_import_guards_test.dart'
    as test_legacy_import_guard_tool_tests;
import 'tool/check_transport_boundary_guards_test.dart'
    as transport_boundary_guard_tool_tests;
import 'tool/release_readiness_test.dart' as release_readiness_tool_tests;
import 'tool/run_consumer_smoke_test.dart' as consumer_smoke_tool_tests;
import 'tool/run_workspace_package_tests_test.dart' as package_tests_tool_tests;
import 'tool/run_workspace_publish_dry_run_test.dart'
    as publish_dry_run_tool_tests;

// Integration tests
import 'integration/thinking_content_extraction_test.dart'
    as thinking_extraction_tests;
import 'integration/thinking_tags_streaming_test.dart'
    as thinking_streaming_tests;
import 'integration/utf8_streaming_test.dart' as utf8_streaming_tests;

void main() {
  group('LLM Dart Library Tests', () {
    group('Utils Tests', () {
      utf8_decoder_tests.main();
    });

    group('Tool Tests', () {
      bootstrap_overrides_tool_tests.main();
      example_api_guard_tool_tests.main();
      openai_provider_layout_guard_tool_tests.main();
      pub_version_availability_tool_tests.main();
      provider_replay_metadata_guard_tool_tests.main();
      dependency_guard_tool_tests.main();
      root_boundary_guard_tool_tests.main();
      test_legacy_import_guard_tool_tests.main();
      transport_boundary_guard_tool_tests.main();
      release_readiness_tool_tests.main();
      consumer_smoke_tool_tests.main();
      package_tests_tool_tests.main();
      publish_dry_run_tool_tests.main();
    });

    group('Integration Tests', () {
      thinking_extraction_tests.main();
      thinking_streaming_tests.main();
      utf8_streaming_tests.main();
    });
  });
}
