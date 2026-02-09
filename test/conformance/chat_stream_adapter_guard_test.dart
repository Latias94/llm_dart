library;

import 'dart:io';

import 'package:test/test.dart';

bool _shouldCheckFile(String content) {
  final hasBoth = content.contains('Stream<ChatStreamEvent> chatStream(') &&
      content.contains('Stream<LLMStreamPart> chatStreamParts(');
  if (!hasBoth) return false;

  // Only enforce for "leaf" implementations that likely parse streaming data.
  // Provider wrappers may delegate (possibly wrapped) to another class that
  // already satisfies the guard in its own file.
  final looksLikeParser = content.contains('postStream') ||
      content.contains('postStreamRaw') ||
      content.contains('resetSSEBuffer') ||
      content.contains('parseSSEChunk');

  return looksLikeParser;
}

bool _chatStreamLooksLikeAdapter(String content) {
  final regex = RegExp(
    r'chatStream\s*\([^)]*\)\s*async\*\s*\{[\s\S]{0,800}?chatStreamParts\s*\(',
    multiLine: true,
  );
  if (regex.hasMatch(content)) return true;

  final delegatingStream = RegExp(r'return\s+([A-Za-z0-9_]+)\.chatStream\s*\(')
      .firstMatch(content)
      ?.group(1);
  if (delegatingStream == null) return false;

  final delegatingParts =
      RegExp(r'return\s+([A-Za-z0-9_]+)\.chatStreamParts\s*\(')
          .firstMatch(content)
          ?.group(1);
  return delegatingParts != null && delegatingParts == delegatingStream;
}

void main() {
  group('No drift guard (chatStream derived from parts)', () {
    test('providers with chatStreamParts keep chatStream as an adapter', () {
      final root = Directory('packages');
      expect(root.existsSync(), isTrue);

      final failures = <String>[];

      for (final entity in root.listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.dart')) continue;

        final content = entity.readAsStringSync();
        if (!_shouldCheckFile(content)) continue;

        if (!_chatStreamLooksLikeAdapter(content)) {
          failures.add(entity.path);
        }
      }

      expect(
        failures,
        isEmpty,
        reason:
            'chatStream must be derived from chatStreamParts to prevent double parsing drift.\n'
            'Non-adapter implementations found:\n${failures.join('\n')}',
      );
    });
  });
}
