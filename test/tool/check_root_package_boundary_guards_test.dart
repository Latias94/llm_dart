import 'dart:io';

import '../../tool/check_root_package_boundary_guards.dart' as guard;
import 'package:test/test.dart';

const _legacyEntrypointContent = r'''
library;

export 'src/facade/ai.dart' show AI;
export 'src/bootstrap/root_registry_bootstrap.dart'
    show ensureRootRegistryBootstrap;
export 'src/facade/legacy_builder_helpers.dart';
export 'src/compatibility/providers/legacy_dio_client_overrides.dart'
    show createLegacyDioClientOverrides;
export 'src/compatibility/providers/openai_family_compat_deepseek_config.dart'
    show createLegacyDeepSeekConfig;
export 'src/compatibility/providers/openai_family_compat_groq_config.dart'
    show createLegacyGroqConfig;
export 'src/compatibility/providers/openai_family_compat_phind_config.dart'
    show createLegacyPhindConfig;
export 'src/compatibility/providers/openai_family_compat_support.dart'
    show createLegacyOpenAIConfig;
export 'src/compatibility/providers/openai_family_compat_xai_config.dart'
    show createLegacyXAIConfig;
export 'src/compatibility/providers/anthropic_config_adapter.dart'
    show createLegacyAnthropicConfig;
export 'src/compatibility/providers/google_config_adapter.dart'
    show createLegacyGoogleConfig;
export 'src/compatibility/providers/elevenlabs/config_adapter.dart'
    show createLegacyElevenLabsConfig;
export 'src/compatibility/providers/ollama/config_adapter.dart'
    show createLegacyOllamaConfig;
export 'src/compatibility/openai_compatible_provider_config.dart'
    show
        ConfigTransformer,
        HeadersTransformer,
        ModelCapabilityConfig,
        OpenAICompatibleProviderConfig,
        RequestBodyTransformer;
export 'src/compatibility/web_search_presets.dart' show CompatWebSearchPresets;

export 'core/capability.dart';
export 'core/cancellation.dart';
export 'core/llm_error.dart';
export 'core/config.dart';
export 'core/registry.dart';
export 'core/openai_compatible_configs.dart';
export 'core/tool_validator.dart';
export 'core/web_search.dart';
export 'package:llm_dart_transport/llm_dart_transport.dart'
    show
        StreamingTransportResponse,
        TransportClient,
        TransportException,
        TransportHttpException,
        TransportMethod,
        TransportNetworkException,
        TransportRequest,
        TransportResponse,
        TransportResponseFormatException,
        TransportResponseType,
        TransportTimeoutException;

export 'models/chat_models.dart';
export 'models/tool_models.dart';
export 'models/audio_models.dart';
export 'models/image_models.dart';
export 'models/file_models.dart';
export 'models/moderation_models.dart';

export 'providers/openai/openai.dart';
export 'providers/openai/client.dart';
export 'providers/openai/chat.dart';
export 'providers/openai/embeddings.dart';
export 'providers/openai/audio.dart';
export 'providers/openai/images.dart';
export 'providers/openai/files.dart';
export 'providers/openai/models.dart';
export 'providers/openai/moderation.dart';
export 'providers/openai/assistants.dart';
export 'providers/openai/completion.dart';
export 'providers/anthropic/anthropic.dart';
export 'providers/anthropic/models.dart';
export 'providers/google/google.dart';
export 'providers/google/client.dart';
export 'providers/google/chat.dart';
export 'providers/google/embeddings.dart';
export 'providers/google/tts.dart';
export 'providers/deepseek/deepseek.dart';
export 'providers/ollama/ollama.dart';
export 'providers/xai/xai.dart';
export 'providers/phind/phind.dart';
export 'providers/groq/groq.dart';
export 'providers/elevenlabs/elevenlabs.dart';

export 'providers/factories/base_factory.dart';

export 'builder/llm_builder.dart';
export 'builder/http_config.dart';

export 'core/tool_call_aggregator.dart';
''';

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

    test('reports unexpected root public entry files and directories',
        () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'lib/flutter.dart',
        'library;\n',
      );
      await Directory(
        '${repoRoot.path}${Platform.pathSeparator}lib${Platform.pathSeparator}src${Platform.pathSeparator}runtime',
      ).create(recursive: true);
      await Directory(
        '${repoRoot.path}${Platform.pathSeparator}lib${Platform.pathSeparator}utils',
      ).create(recursive: true);
      await _writeFile(
        repoRoot,
        'lib/models/assistant_models.dart',
        'library;\n',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
            contains('unexpected top-level public entry files: flutter.dart')),
      );
      expect(
        result.violations,
        contains(contains('lib/: unexpected top-level directories: utils')),
      );
      expect(
        result.violations,
        contains(
          contains(
            'provider-specific model files must stay with their provider: assistant_models.dart',
          ),
        ),
      );
      expect(
        result.violations,
        contains(
            contains('lib/src/: unexpected top-level directories: runtime')),
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
        'lib/ai.dart',
        '''
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
              'only lib/chat.dart may import or export package:llm_dart_chat/...'),
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
export 'legacy.dart';
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
export 'builder/llm_builder.dart';
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
export 'providers/openai/openai.dart';
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
              'focused root entrypoint must only export its package-owned surface'),
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
export 'legacy.dart';
''',
      );
      await _writeFile(
        repoRoot,
        'lib/transport.dart',
        '''
library;

export 'package:llm_dart_transport/llm_dart_transport.dart';
export 'src/compatibility/providers/openai/client.dart';
''',
      );
      await _writeFile(
        repoRoot,
        'lib/chat.dart',
        '''
library;

export 'package:llm_dart_chat/llm_dart_chat.dart';
export 'legacy.dart';
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
              'lib/core.dart: focused root entrypoint must only export its package-owned surface'),
        ),
      );
      expect(
        result.violations,
        contains(
          contains(
              'lib/transport.dart: focused root entrypoint must only export its package-owned surface'),
        ),
      );
      expect(
        result.violations,
        contains(
          contains(
              'lib/chat.dart: focused root entrypoint must only export its package-owned surface'),
        ),
      );
    });

    test('reports widened legacy compatibility entrypoint', () async {
      final repoRoot = await _createTempRootLayout();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'lib/legacy.dart',
        '''
$_legacyEntrypointContent

export 'src/compatibility/new_legacy_surface.dart';
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
              'legacy entrypoint is frozen as an explicit compatibility shell'),
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
        'lib/legacy.dart',
        '''
library;

final class LegacyImplementation {}
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
        'lib/legacy.dart',
        '''
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
              'root package must not import or export package:llm_dart_flutter/...'),
        ),
      );
    });

    test('reports legacy imports from examples', () async {
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

void main() {}
''',
      );

      final result = await guard.evaluateRootPackageBoundaryGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('examples must use focused stable'),
        ),
      );
    });
  });
}

Future<Directory> _createTempRootLayout() async {
  final repoRoot = await Directory.systemTemp.createTemp(
    'llm_dart_root_boundary_guards_',
  );

  for (final directory in const [
    'lib/builder',
    'lib/core',
    'lib/models',
    'lib/providers',
    'lib/src',
    'lib/src/bootstrap',
    'lib/src/compatibility',
    'lib/src/config',
    'lib/src/facade',
  ]) {
    await Directory(
      '${repoRoot.path}${Platform.pathSeparator}$directory',
    ).create(recursive: true);
  }

  for (final file in const [
    'lib/ai.dart',
    'lib/anthropic.dart',
    'lib/chat.dart',
    'lib/core.dart',
    'lib/deepseek.dart',
    'lib/elevenlabs.dart',
    'lib/google.dart',
    'lib/groq.dart',
    'lib/legacy.dart',
    'lib/llm_dart.dart',
    'lib/ollama.dart',
    'lib/openai.dart',
    'lib/openrouter.dart',
    'lib/phind.dart',
    'lib/transport.dart',
    'lib/xai.dart',
  ]) {
    await _writeFile(repoRoot, file, 'library;\n');
  }

  await _writeFile(
    repoRoot,
    'lib/llm_dart.dart',
    '''
library;

export 'ai.dart';
''',
  );

  await _writeFile(repoRoot, 'lib/legacy.dart', _legacyEntrypointContent);

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
    'lib/anthropic.dart',
    '''
library;

export 'package:llm_dart_anthropic/llm_dart_anthropic.dart'
    hide anthropic;
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

export 'package:llm_dart_openai/llm_dart_openai.dart'
    hide deepSeek, groq, openRouter, openai, phind, xai;
export 'src/facade/ai.dart' show openai;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/groq.dart',
    '''
library;

export 'package:llm_dart_openai/llm_dart_openai.dart'
    show
        GroqProfile,
        OpenAI,
        OpenAIChatModelSettings,
        OpenAIGenerateTextOptions,
        OpenAILanguageModel;
export 'src/facade/ai.dart' show groq;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/phind.dart',
    '''
library;

export 'package:llm_dart_openai/llm_dart_openai.dart'
    show
        OpenAI,
        OpenAIChatModelSettings,
        OpenAIGenerateTextOptions,
        OpenAILanguageModel,
        PhindProfile;
export 'src/facade/ai.dart' show phind;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/xai.dart',
    '''
library;

export 'package:llm_dart_openai/llm_dart_openai.dart'
    show
        OpenAI,
        OpenAIChatModelSettings,
        OpenAIGenerateTextOptions,
        OpenAILanguageModel,
        XAIProfile,
        XAIGenerateTextOptions,
        XAILiveSearchOptions,
        XAINewsSearchSource,
        XAIRssSearchSource,
        XAISearchMode,
        XAISearchSource,
        XAIWebSearchSource,
        XAIXSearchSource;
export 'src/facade/ai.dart' show xai;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/deepseek.dart',
    '''
library;

export 'package:llm_dart_openai/llm_dart_openai.dart'
    show
        DeepSeekGenerateTextOptions,
        DeepSeekProfile,
        OpenAI,
        OpenAIChatModelSettings,
        OpenAIGenerateTextOptions,
        OpenAILanguageModel;
export 'src/facade/ai.dart' show deepSeek;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/openrouter.dart',
    '''
library;

export 'package:llm_dart_openai/llm_dart_openai.dart'
    show
        OpenAI,
        OpenAIChatModelSettings,
        OpenAIGenerateTextOptions,
        OpenAILanguageModel,
        OpenRouterChatModelSettings,
        OpenRouterGenerateTextOptions,
        OpenRouterProfile,
        OpenRouterSearchMode,
        OpenRouterSearchOptions;
export 'src/facade/ai.dart' show openRouter;
''',
  );

  await _writeFile(
    repoRoot,
    'lib/core.dart',
    '''
library;

export 'package:llm_dart_ai/llm_dart_ai.dart';

export 'core/cancellation.dart'
    show CancellationHelper, TransportCancellation, TransportCancelledException;
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
export 'src/facade/ai.dart'
    show anthropic, deepSeek, google, groq, openRouter, openai, phind, xai;
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
