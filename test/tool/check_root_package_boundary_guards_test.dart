import 'dart:io';

import 'package:test/test.dart';

import '../../tool/check_root_package_boundary_guards.dart' as guard;

void main() {
  group('check_root_package_boundary_guards', () {
    test('passes against the current repository root package', () async {
      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: Directory.current,
      );

      expect(
        result.violations,
        isEmpty,
        reason: result.violations.join('\n'),
      );
    });

    test('passes when root is only the modern facade shell', () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(
        result.violations,
        isEmpty,
        reason: result.violations.join('\n'),
      );
    });

    test('reports legacy root implementation ownership if it returns',
        () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(repoRoot, 'lib/legacy.dart', 'library;\n');
      for (final directory in const [
        'lib/builder',
        'lib/core',
        'lib/models',
        'lib/providers',
        'lib/src/bootstrap',
        'lib/src/compatibility',
        'lib/src/config',
      ]) {
        await Directory(
          '${repoRoot.path}${Platform.pathSeparator}$directory',
        ).create(recursive: true);
      }

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains(
            'unexpected top-level directories: builder, core, models, providers',
          ),
        ),
      );
      expect(
        result.violations,
        contains(
            contains('unexpected top-level public entry files: legacy.dart')),
      );
      expect(
        result.violations,
        contains(
          contains(
            'lib/src/: unexpected top-level directories: bootstrap, compatibility, config',
          ),
        ),
      );
    });

    test('reports unexpected root public entry files and directories',
        () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(repoRoot, 'lib/flutter.dart', 'library;\n');
      await Directory(
        '${repoRoot.path}${Platform.pathSeparator}lib${Platform.pathSeparator}utils',
      ).create(recursive: true);
      await Directory(
        '${repoRoot.path}${Platform.pathSeparator}lib${Platform.pathSeparator}src${Platform.pathSeparator}runtime',
      ).create(recursive: true);

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('unexpected top-level public entry files: flutter.dart'),
        ),
      );
      expect(
        result.violations,
        contains(contains('lib/: unexpected top-level directories: utils')),
      );
      expect(
        result.violations,
        contains(
          contains('lib/src/: unexpected top-level directories: runtime'),
        ),
      );
    });

    test('reports chat package imports outside lib/chat.dart', () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'lib/openai.dart',
        '''
library;

export 'package:llm_dart_chat/llm_dart_chat.dart';
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains(
            'only lib/chat.dart may import or export package:llm_dart_chat/...',
          ),
        ),
      );
    });

    test('reports widened default root entrypoint', () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'lib/llm_dart.dart',
        '''
library;

export 'ai.dart';
export 'openai.dart';
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('default root entrypoint must only export ai.dart'),
        ),
      );
    });

    test('reports widened modern aggregator entrypoint', () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'lib/ai.dart',
        '''
library;

export 'package:llm_dart_ai/llm_dart_ai.dart';
export 'package:llm_dart_chat/llm_dart_chat.dart';
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('modern aggregator entrypoint must only compose stable'),
        ),
      );
    });

    test('reports widened focused provider entrypoints', () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'lib/openai.dart',
        '''
library;

export 'package:llm_dart_openai/llm_dart_openai.dart';
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains(
            'focused root entrypoint must only export its package-owned surface',
          ),
        ),
      );
    });

    test('reports widened focused core, transport, and chat entrypoints',
        () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'lib/core.dart',
        '''
library;

export 'package:llm_dart_ai/llm_dart_ai.dart';
export 'transport.dart';
''',
      );
      await _writeFile(
        repoRoot,
        'lib/transport.dart',
        '''
library;

export 'package:llm_dart_transport/llm_dart_transport.dart';
''',
      );
      await _writeFile(
        repoRoot,
        'lib/chat.dart',
        '''
library;

export 'package:llm_dart_chat/llm_dart_chat.dart';
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains(
            'lib/core.dart: focused root entrypoint must only export its package-owned surface',
          ),
        ),
      );
      expect(
        result.violations,
        contains(
          contains(
            'lib/transport.dart: focused root entrypoint must only export its package-owned surface',
          ),
        ),
      );
      expect(
        result.violations,
        contains(
          contains(
            'lib/chat.dart: focused root entrypoint must only export its package-owned surface',
          ),
        ),
      );
    });

    test('reports implementation declarations in root public entrypoints',
        () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'lib/openai.dart',
        '''
library;

final class RootImplementation {}
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('root public entrypoints must stay as facades'),
        ),
      );
    });

    test('reports any root import of llm_dart_flutter', () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'lib/openai.dart',
        '''
library;

export 'package:llm_dart_flutter/llm_dart_flutter.dart';
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains(
            'root package must not import or export package:llm_dart_flutter/...',
          ),
        ),
      );
    });

    test('reports legacy root subpath imports from examples', () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'example/02_core_features/legacy_builder_demo.dart',
        '''
import 'package:llm_dart/legacy.dart';
import 'package:llm_dart/builder/llm_builder.dart';
import 'package:llm_dart/core/capability.dart';
import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/providers/openai/openai.dart';

void main() {}
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(contains('examples must use focused stable')),
      );
      expect(result.violations, contains(contains('legacy.dart')));
      expect(result.violations, contains(contains('builder/')));
      expect(result.violations, contains(contains('core/')));
      expect(result.violations, contains(contains('models/')));
      expect(result.violations, contains(contains('providers/')));
    });
  });
}

Future<Directory> _createTempRootLayout() async {
  final repoRoot = await Directory.systemTemp.createTemp(
    'llm_dart_root_boundary_guards_',
  );

  await Directory(
    '${repoRoot.path}${Platform.pathSeparator}lib${Platform.pathSeparator}src${Platform.pathSeparator}facade',
  ).create(recursive: true);

  await _writeFile(
    repoRoot,
    'lib/llm_dart.dart',
    '''
library;

export 'ai.dart';
''',
  );

  await _writeFile(
    repoRoot,
    'lib/ai.dart',
    '''
library;

export 'package:llm_dart_ai/llm_dart_ai.dart';

export 'anthropic.dart';
export 'core.dart';
export 'elevenlabs.dart';
export 'google.dart';
export 'ollama.dart';
export 'openai.dart';
export 'transport.dart';
export 'src/facade/ai.dart' show AI, anthropic, deepSeek, elevenLabs, google, groq, ollama, openRouter, openai, phind, xai;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/core.dart',
    '''
library;

export 'package:llm_dart_ai/llm_dart_ai.dart';
''',
  );

  await _writeFile(
    repoRoot,
    'lib/transport.dart',
    '''
library;

export 'core.dart';
export 'package:llm_dart_transport/llm_dart_transport.dart';
''',
  );

  await _writeFile(
    repoRoot,
    'lib/chat.dart',
    '''
library;

export 'core.dart';
export 'transport.dart';
export 'package:llm_dart_chat/llm_dart_chat.dart';
export 'src/facade/ai.dart' show anthropic, deepSeek, google, groq, openRouter, openai, phind, xai;
''',
  );

  await _writeFocusedProviderEntrypoints(repoRoot);

  return repoRoot;
}

Future<void> _writeFocusedProviderEntrypoints(Directory repoRoot) async {
  await _writeFile(
    repoRoot,
    'lib/anthropic.dart',
    '''
library;

export 'package:llm_dart_anthropic/llm_dart_anthropic.dart' hide anthropic;
export 'src/facade/ai.dart' show anthropic;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/google.dart',
    '''
library;

export 'package:llm_dart_google/llm_dart_google.dart' hide google;
export 'src/facade/ai.dart' show google;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/elevenlabs.dart',
    '''
library;

export 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart' hide elevenLabs;
export 'src/facade/ai.dart' show elevenLabs;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/ollama.dart',
    '''
library;

export 'package:llm_dart_ollama/llm_dart_ollama.dart' hide ollama;
export 'src/facade/ai.dart' show ollama;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/openai.dart',
    '''
library;

export 'package:llm_dart_openai/llm_dart_openai.dart' hide deepSeek, groq, openRouter, openai, phind, xai;
export 'src/facade/ai.dart' show openai;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/groq.dart',
    '''
library;

export 'package:llm_dart_openai/llm_dart_openai.dart' show GroqProfile, OpenAI, OpenAIChatModelSettings, OpenAIGenerateTextOptions, OpenAILanguageModel;
export 'src/facade/ai.dart' show groq;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/phind.dart',
    '''
library;

export 'package:llm_dart_openai/llm_dart_openai.dart' show OpenAI, OpenAIChatModelSettings, OpenAIGenerateTextOptions, OpenAILanguageModel, PhindProfile;
export 'src/facade/ai.dart' show phind;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/xai.dart',
    '''
library;

export 'package:llm_dart_openai/llm_dart_openai.dart' show OpenAI, OpenAIChatModelSettings, OpenAIGenerateTextOptions, OpenAILanguageModel, XAIProfile, XAIGenerateTextOptions, XAILiveSearchOptions, XAINewsSearchSource, XAIRssSearchSource, XAISearchMode, XAISearchSource, XAIWebSearchSource, XAIXSearchSource;
export 'src/facade/ai.dart' show xai;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/deepseek.dart',
    '''
library;

export 'package:llm_dart_openai/llm_dart_openai.dart' show DeepSeekGenerateTextOptions, DeepSeekProfile, OpenAI, OpenAIChatModelSettings, OpenAIGenerateTextOptions, OpenAILanguageModel;
export 'src/facade/ai.dart' show deepSeek;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/openrouter.dart',
    '''
library;

export 'package:llm_dart_openai/llm_dart_openai.dart' show OpenAI, OpenAIChatModelSettings, OpenAIGenerateTextOptions, OpenAILanguageModel, OpenRouterChatModelSettings, OpenRouterGenerateTextOptions, OpenRouterProfile, OpenRouterSearchMode, OpenRouterSearchOptions;
export 'src/facade/ai.dart' show openRouter;
''',
  );
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
