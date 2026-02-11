import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

import '../utils/v3_parts_golden.dart';

void main() {
  group('v3 stream part codec: decode -> encode round-trip', () {
    final cases = <String>[
      'test/fixtures/v3_parts/openai/openai-file-search-tool.1.jsonl',
      'test/fixtures/v3_parts/openai/openai-mcp-tool-approval.1.jsonl',
      'test/fixtures/v3_parts/google/google-thinking-text.1.jsonl',
    ];

    for (final path in cases) {
      test(path, () {
        final objects = readJsonlObjects(path);
        final parts = decodeV3StreamParts(objects);
        final encoded = encodeV3StreamParts(parts);

        expectStableJsonlGolden(
          goldenPath: path,
          actualObjects: encoded,
        );
      });
    }
  });
}
