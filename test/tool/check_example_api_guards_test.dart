import 'dart:io';

import 'package:test/test.dart';

import '../../tool/check_example_api_guards.dart' as guard;

void main() {
  group('check_example_api_guards', () {
    test('passes against current example set', () async {
      final result = await guard.evaluateExampleApiGuards(
        repoRoot: Directory.current,
      );

      expect(
        result.violations,
        isEmpty,
        reason: result.violations.join('\n'),
      );
    });

    test('reports legacy imports in default examples', () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'example/01_getting_started/quick_start.dart',
        '''
import 'package:llm_dart/legacy.dart';

void main() {}
''',
      );

      final result = await guard.evaluateExampleApiGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(result.violations, contains(contains('legacy barrel import')));
    });

    test('reports builder imports and LLMBuilder usage in default examples',
        () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'example/02_core_features/chat_basics.dart',
        '''
import 'package:llm_dart/builder/llm_builder.dart';

void main() {
  LLMBuilder();
}
''',
      );

      final result = await guard.evaluateExampleApiGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(result.violations, contains(contains('legacy builder import')));
      expect(result.violations, contains(contains('LLMBuilder usage')));
    });

    test(
        'reports legacy provider, model, and core subpath imports in default examples',
        () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'example/02_core_features/chat_basics.dart',
        '''
import 'package:llm_dart/core/capability.dart';
import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/providers/openai/openai.dart';

void main() {}
''',
      );

      final result = await guard.evaluateExampleApiGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(contains('legacy core subpath import')),
      );
      expect(
        result.violations,
        contains(contains('legacy model compatibility import')),
      );
      expect(
        result.violations,
        contains(contains('legacy provider compatibility import')),
      );
    });

    test('reports removed ai helper usage in default examples', () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'example/05_use_cases/chatbot.dart',
        '''
void main() {
  ai();
}
''',
      );

      final result = await guard.evaluateExampleApiGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(result.violations, contains(contains('removed ai() helper')));
    });

    test('reports grouped AI facade usage in default examples', () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'example/02_core_features/streaming_chat.dart',
        '''
import 'package:llm_dart/llm_dart.dart' as llm;

void main() {
  llm.AI.openai(apiKey: 'test');
}
''',
      );

      final result = await guard.evaluateExampleApiGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(result.violations, contains(contains('grouped AI facade')));
    });

    test('reports legacy imports even from old compatibility example paths',
        () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'example/02_core_features/capability_factory_methods.dart',
        '''
import 'package:llm_dart/builder/llm_builder.dart';

void main() {
  LLMBuilder();
}
''',
      );

      final result = await guard.evaluateExampleApiGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(result.violations, contains(contains('legacy builder import')));
      expect(result.violations, contains(contains('LLMBuilder usage')));
    });
  });
}

Future<Directory> _createTempWorkspace() async {
  final repoRoot = await Directory.systemTemp.createTemp(
    'llm_dart_example_api_guard_',
  );

  await _writeFile(
    repoRoot,
    'example/01_getting_started/focused.dart',
    '''
import 'package:llm_dart/llm_dart.dart';

void main() {}
''',
  );

  return repoRoot;
}

Future<void> _writeFile(
  Directory repoRoot,
  String relativePath,
  String content,
) async {
  final file = File('${repoRoot.path}${Platform.pathSeparator}$relativePath');
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}
