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

    test('focused provider packages do not emit runtime-only events', () {
      const roots = [
        'packages/llm_dart_openai/lib',
        'packages/llm_dart_anthropic/lib',
        'packages/llm_dart_google/lib',
        'packages/llm_dart_ollama/lib',
        'packages/llm_dart_elevenlabs/lib',
        'packages/llm_dart_test/lib',
      ];
      const forbiddenTokens = [
        'StepStartEvent',
        'StepFinishEvent',
        'ToolOutputDeniedEvent',
        'AbortEvent',
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

    test('provider packages do not runtime-depend on app/runtime layers', () {
      const packageRoots = [
        'packages/llm_dart_provider',
        'packages/llm_dart_openai',
        'packages/llm_dart_anthropic',
        'packages/llm_dart_google',
        'packages/llm_dart_ollama',
        'packages/llm_dart_elevenlabs',
        'packages/llm_dart_test',
      ];
      const forbiddenPackages = [
        'llm_dart',
        'llm_dart_ai',
        'llm_dart_chat',
        'llm_dart_flutter',
      ];

      final violations = <String>[];
      for (final root in packageRoots) {
        final pubspec = File('$root/pubspec.yaml');
        if (pubspec.existsSync()) {
          final dependencies = _topLevelYamlSection(
            pubspec.readAsStringSync(),
            'dependencies',
          );
          for (final package in forbiddenPackages) {
            if (dependencies
                .contains(RegExp('^  $package:', multiLine: true))) {
              violations.add('${pubspec.path}: dependencies.$package');
            }
          }
        }

        final libDirectory = Directory('$root/lib');
        if (!libDirectory.existsSync()) {
          continue;
        }

        final dartFiles = libDirectory
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'));
        for (final file in dartFiles) {
          final content = file.readAsStringSync();
          for (final package in forbiddenPackages) {
            final importPrefix = "package:$package/";
            if (content.contains(importPrefix)) {
              violations.add('${file.path}: $importPrefix');
            }
          }
        }
      }

      expect(violations, isEmpty);
    });

    test('AI runtime does not use the legacy provider stream codec', () {
      final aiLib = Directory('packages/llm_dart_ai/lib');

      final violations = <String>[];
      final dartFiles = aiLib
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        if (content.contains('provider.TextStreamEventJsonCodec')) {
          violations.add(file.path);
        }
      }

      expect(violations, isEmpty);
    });

    test('provider language stream codec stays model-call scoped', () {
      final file = File(
        'packages/llm_dart_provider/lib/src/serialization/'
        'language_model_stream_event_json_codec.dart',
      );
      final content = file.readAsStringSync();
      const forbiddenTokens = [
        'TextStreamEventJsonCodec',
        'StepStartEvent',
        'StepFinishEvent',
        'ToolOutputDeniedEvent',
        'AbortEvent',
      ];

      final violations = [
        for (final token in forbiddenTokens)
          if (content.contains(token)) token,
      ];

      expect(violations, isEmpty);
    });

    test('provider public stream exports stay model-call scoped', () {
      final foundation = File('packages/llm_dart_provider/lib/foundation.dart');
      final content = foundation.readAsStringSync();

      expect(
        content,
        isNot(
          contains(
            "export 'src/serialization/text_stream_event_json_codec.dart'",
          ),
        ),
      );
      expect(
        content,
        isNot(contains("export 'src/stream/text_stream_event.dart'")),
      );
      expect(
        content,
        contains(
          "export 'src/serialization/"
          "language_model_stream_event_json_codec.dart'",
        ),
      );
      expect(
        content,
        contains("export 'src/stream/language_model_stream_event.dart'"),
      );
    });

    test('provider internals no longer own full-stream runtime events', () {
      final providerLib = Directory('packages/llm_dart_provider/lib');

      const forbiddenTokens = [
        'TextStreamEvent',
        'TextStreamEventJsonCodec',
        'StepStartEvent',
        'StepFinishEvent',
        'ToolOutputDeniedEvent',
        'AbortEvent',
      ];

      final violations = <String>[];
      final dartFiles = providerLib
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

      expect(violations, isEmpty);
    });

    test('provider input contracts do not accept raw ProviderMetadata', () {
      const inputContractFiles = [
        'packages/llm_dart_provider/lib/src/common/call_options.dart',
        'packages/llm_dart_provider/lib/src/prompt/prompt_message.dart',
      ];

      final violations = <String>[];
      for (final path in inputContractFiles) {
        final content = File(path).readAsStringSync();
        if (content.contains('ProviderMetadata')) {
          violations.add(path);
        }
      }

      final languageModel = File(
        'packages/llm_dart_provider/lib/src/model/language_model.dart',
      ).readAsStringSync();
      final languageModelInputContracts = _sliceBefore(
        languageModel,
        'final class GenerateTextResult',
      );
      if (languageModelInputContracts.contains('ProviderMetadata')) {
        violations.add(
          'packages/llm_dart_provider/lib/src/model/language_model.dart',
        );
      }

      expect(violations, isEmpty);
    });

    test('provider replay metadata is explicit typed prompt options only', () {
      final options = _readLibraryWithParts(
        'packages/llm_dart_provider/lib/src/common/provider_options.dart',
      );
      final promptPartCodec = File(
        'packages/llm_dart_provider/lib/src/serialization/'
        'prompt_part_json_codec.dart',
      ).readAsStringSync();
      final toolOutputCodec = File(
        'packages/llm_dart_provider/lib/src/serialization/'
        'serialization_tool_output_part_json_codec.dart',
      ).readAsStringSync();

      expect(options, contains('ProviderReplayPromptPartOptions'));
      expect(options, contains('ProviderMetadata metadata'));
      expect(
        promptPartCodec,
        contains('Legacy prompt replay metadata is no longer supported'),
      );
      expect(
        toolOutputCodec,
        contains('Legacy prompt replay metadata is no longer supported'),
      );
    });
  });
}

String _topLevelYamlSection(String yaml, String sectionName) {
  final lines = yaml.split(RegExp(r'\r?\n'));
  final section = <String>[];
  var inSection = false;

  for (final line in lines) {
    if (!line.startsWith(' ') && line.endsWith(':')) {
      final currentSection = line.substring(0, line.length - 1);
      if (currentSection == sectionName) {
        inSection = true;
        continue;
      }

      if (inSection) {
        break;
      }
    }

    if (inSection) {
      section.add(line);
    }
  }

  return section.join('\n');
}

String _sliceBefore(String content, String marker) {
  final index = content.indexOf(marker);
  if (index < 0) {
    return content;
  }

  return content.substring(0, index);
}

String _readLibraryWithParts(String path) {
  final file = File(path);
  final source = file.readAsStringSync();
  final sources = <String>[source];

  final partPattern = RegExp(
    r'''^\s*part\s+['"]([^'"]+)['"]\s*;''',
    multiLine: true,
  );
  for (final match in partPattern.allMatches(source)) {
    final partPath = match.group(1)!;
    final partFile = File.fromUri(file.absolute.uri.resolve(partPath));
    sources.add(partFile.readAsStringSync());
  }

  return sources.join('\n');
}
