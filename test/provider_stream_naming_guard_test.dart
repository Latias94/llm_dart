import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('provider stream naming guard', () {
    test('focused provider packages use LanguageModelStreamEvent names', () {
      const roots = [
        'packages/llm_dart_openai/lib',
        'packages/llm_dart_anthropic/lib',
        'packages/llm_dart_google/lib',
        'packages/llm_dart_ollama/lib',
        'packages/llm_dart_elevenlabs/lib',
        'packages/llm_dart_test/lib',
      ];
      const forbiddenTokens = [
        'TextStreamEvent',
        'TextStreamEventJsonCodec',
      ];

      final violations = <String>[];
      for (final root in roots) {
        final directory = Directory(root);
        if (!directory.existsSync()) {
          continue;
        }

        final dartFiles = directory
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'));

        for (final file in dartFiles) {
          final content = file.readAsStringSync();
          for (final token in forbiddenTokens) {
            if (content.contains(token)) {
              violations.add('${file.path}: $token');
            }
          }
        }
      }

      expect(violations, isEmpty);
    });
  });
}
