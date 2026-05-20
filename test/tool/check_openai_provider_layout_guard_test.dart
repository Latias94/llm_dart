import 'dart:io';

import 'package:test/test.dart';

import '../../tool/check_openai_provider_layout_guard.dart' as guard;

void main() {
  group('check_openai_provider_layout_guard', () {
    test('passes against the current repository root', () async {
      final result = await guard.evaluateOpenAIProviderLayoutGuard(
        repoRoot: Directory.current,
      );

      expect(
        result.violations,
        isEmpty,
        reason: result.violations.join('\n'),
      );
    });

    test('rejects flat OpenAI src implementation files', () async {
      final temp = await Directory.systemTemp.createTemp(
        'openai_provider_layout_guard_',
      );
      addTearDown(() async {
        if (temp.existsSync()) {
          await temp.delete(recursive: true);
        }
      });

      await _createExpectedDirectories(temp);
      await _writeFile(
        temp,
        'packages/llm_dart_openai/lib/src/openai_responses_codec.dart',
        'final legacyFlatFile = true;',
      );

      final result = await guard.evaluateOpenAIProviderLayoutGuard(
        repoRoot: temp,
      );

      expect(result.violations, hasLength(1));
      expect(result.violations.single, contains('openai_responses_codec.dart'));
    });

    test('requires the expected capability directories', () async {
      final temp = await Directory.systemTemp.createTemp(
        'openai_provider_layout_guard_missing_',
      );
      addTearDown(() async {
        if (temp.existsSync()) {
          await temp.delete(recursive: true);
        }
      });

      await Directory.fromUri(
        temp.uri.resolve('packages/llm_dart_openai/lib/src/responses/'),
      ).create(recursive: true);

      final result = await guard.evaluateOpenAIProviderLayoutGuard(
        repoRoot: temp,
      );

      expect(result.violations, hasLength(1));
      expect(result.violations.single, contains('chat_completions'));
      expect(result.violations.single, contains('provider'));
    });
  });
}

Future<void> _createExpectedDirectories(Directory root) async {
  const directories = [
    'assistants',
    'chat_completions',
    'common',
    'custom_parts',
    'embedding',
    'files',
    'image',
    'language',
    'moderation',
    'provider',
    'responses',
    'speech',
    'tools',
    'transcription',
  ];

  for (final directory in directories) {
    await Directory.fromUri(
      root.uri.resolve('packages/llm_dart_openai/lib/src/$directory/'),
    ).create(recursive: true);
  }
}

Future<void> _writeFile(
  Directory root,
  String path,
  String contents,
) async {
  final file = File.fromUri(root.uri.resolve(path));
  await file.parent.create(recursive: true);
  await file.writeAsString(contents);
}
