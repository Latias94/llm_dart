import 'dart:io';

import 'package:test/test.dart';

import '../../tool/check_provider_replay_metadata_guards.dart' as guard;

void main() {
  group('check_provider_replay_metadata_guards', () {
    test('passes against the current repository root', () async {
      final result = await guard.evaluateProviderReplayMetadataGuards(
        repoRoot: Directory.current,
      );

      expect(
        result.violations,
        isEmpty,
        reason: result.violations.join('\n'),
      );
    });

    test('allows response metadata while guarding prompt replay metadata',
        () async {
      final temp = await Directory.systemTemp.createTemp(
        'provider_replay_guard_',
      );
      addTearDown(() async {
        if (temp.existsSync()) {
          await temp.delete(recursive: true);
        }
      });

      await _writeFile(
        temp,
        'packages/llm_dart_ai/lib/src/model/generate_text_runner_support.dart',
        '''
final resultPart = ToolResultContentPart(
  toolResult,
  providerMetadata: execution.providerMetadata,
);
final promptPart = TextPromptPart(
  'replay',
  providerMetadata: metadata,
);
''',
      );
      for (final path in [
        'packages/llm_dart_openai/lib/src/openai_responses_codec.dart',
        'packages/llm_dart_google/lib/src/google_generate_content_codec.dart',
        'packages/llm_dart_anthropic/lib/src/anthropic_messages_codec.dart',
      ]) {
        await _writeFile(temp, path, 'final ok = part.providerOptions;');
      }
      await _writeFile(
        temp,
        'packages/llm_dart_provider/lib/src/common/provider_options.dart',
        '''
ProviderMetadata? providerReplayMetadataFromOptions(options) => null;
''',
      );
      await _writeFile(
        temp,
        'packages/llm_dart_anthropic/lib/src/anthropic_code_execution_replay.dart',
        '''
final options = ProviderReplayPromptPartOptions.fromMetadata(metadata);
final replay = providerReplayMetadataFromOptions(part.providerOptions);
''',
      );

      final result = await guard.evaluateProviderReplayMetadataGuards(
        repoRoot: temp,
      );

      expect(result.violations, hasLength(1));
      expect(result.violations.single, contains('TextPromptPart'));
    });

    test('requires the provider replay extraction helper to stay single-entry',
        () async {
      final temp = await Directory.systemTemp.createTemp(
        'provider_replay_guard_helper_',
      );
      addTearDown(() async {
        if (temp.existsSync()) {
          await temp.delete(recursive: true);
        }
      });

      await _writeFile(
        temp,
        'packages/llm_dart_ai/lib/src/model/generate_text_runner_support.dart',
        'final ok = TextPromptPart("replay", providerOptions: replayOptions);',
      );
      for (final path in [
        'packages/llm_dart_openai/lib/src/openai_responses_codec.dart',
        'packages/llm_dart_google/lib/src/google_generate_content_codec.dart',
        'packages/llm_dart_anthropic/lib/src/anthropic_messages_codec.dart',
      ]) {
        await _writeFile(temp, path, 'final ok = part.providerOptions;');
      }
      await _writeFile(
        temp,
        'packages/llm_dart_anthropic/lib/src/anthropic_code_execution_replay.dart',
        '''
final options = ProviderReplayPromptPartOptions.fromMetadata(metadata);
final replay = providerReplayMetadataFromOptions(part.providerOptions);
''',
      );
      await _writeFile(
        temp,
        'packages/llm_dart_provider/lib/src/common/provider_options.dart',
        '''
ProviderMetadata? providerReplayMetadataFromOptions(options) => null;
ProviderMetadata? mergeProviderReplayMetadata({providerOptions}) => null;
''',
      );

      final result = await guard.evaluateProviderReplayMetadataGuards(
        repoRoot: temp,
      );

      expect(result.violations, hasLength(1));
      expect(
        result.violations.single,
        contains('mergeProviderReplayMetadata'),
      );
    });
  });
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
