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

    test('AI runtime legacy stream codec usage stays isolated', () {
      final aiLib = Directory('packages/llm_dart_ai/lib');
      const allowedLegacyCodecPath =
          'packages/llm_dart_ai/lib/src/serialization/text_stream_event_json_codec.dart';

      final violations = <String>[];
      final dartFiles = aiLib
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      for (final file in dartFiles) {
        final path = file.path.replaceAll(r'\', '/');
        if (path == allowedLegacyCodecPath) {
          continue;
        }

        final content = file.readAsStringSync();
        if (content.contains('provider.TextStreamEventJsonCodec')) {
          violations.add(file.path);
        }
      }

      expect(violations, isEmpty);
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
