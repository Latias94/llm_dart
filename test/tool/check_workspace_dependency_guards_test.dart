import 'dart:io';

import '../../tool/check_workspace_dependency_guards.dart' as guard;
import 'package:test/test.dart';

void main() {
  group('check_workspace_dependency_guards', () {
    test('passes against the current repository workspace', () async {
      final result = await guard.evaluateWorkspaceDependencyGuards(
        repoRoot: Directory.current,
      );

      expect(
        result.violations,
        isEmpty,
        reason: result.violations.join('\n'),
      );
    });

    test('reports package implementation imports from the root package',
        () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'packages/llm_dart_openai/lib/src/example.dart',
        '''
import 'package:llm_dart/openai.dart';

void main() {}
''',
      );

      final result = await guard.evaluateWorkspaceDependencyGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains(
            'package implementation files must not import or export package:llm_dart/...',
          ),
        ),
      );
    });

    test('reports unexpected runtime dependencies in workspace pubspecs',
        () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'packages/llm_dart_openai/pubspec.yaml',
        '''
name: llm_dart_openai
dependencies:
  llm_dart_provider:
    path: ../llm_dart_provider
  llm_dart_transport:
    path: ../llm_dart_transport
  llm_dart_google:
    path: ../llm_dart_google
''',
      );

      final result = await guard.evaluateWorkspaceDependencyGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('unexpected runtime dependencies: llm_dart_google'),
        ),
      );
    });

    test('reports user-facing language model method names in package lib code',
        () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'packages/llm_dart_openai/lib/src/bad_language_model.dart',
        '''
import 'package:llm_dart_provider/llm_dart_provider.dart';

final class BadLanguageModel {
  Future<GenerateTextResult> generate(GenerateTextRequest request) async {
    throw UnimplementedError();
  }

  Stream<TextStreamEvent> stream(GenerateTextRequest request) async* {}
}
''',
      );

      final result = await guard.evaluateWorkspaceDependencyGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('LanguageModel provider contracts must use doGenerate'),
        ),
      );
      expect(
        result.violations,
        contains(
          contains('LanguageModel provider contracts must use doStream'),
        ),
      );
    });

    test('reports user-facing non-text model method names in package lib code',
        () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'packages/llm_dart_openai/lib/src/bad_non_text_models.dart',
        '''
import 'package:llm_dart_provider/llm_dart_provider.dart';

final class BadEmbeddingModel {
  Future<EmbedResult> embed(EmbedRequest request) async {
    throw UnimplementedError();
  }
}

final class BadImageModel {
  Future<ImageGenerationResult> generate(
    ImageGenerationRequest request,
  ) async {
    throw UnimplementedError();
  }
}

final class BadSpeechModel {
  Future<SpeechGenerationResult> generateSpeech(
    SpeechGenerationRequest request,
  ) async {
    throw UnimplementedError();
  }
}

final class BadTranscriptionModel {
  Future<TranscriptionResult> transcribe(
    TranscriptionRequest request,
  ) async {
    throw UnimplementedError();
  }
}
''',
      );

      final result = await guard.evaluateWorkspaceDependencyGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('EmbeddingModel provider contracts must use doEmbed'),
        ),
      );
      expect(
        result.violations,
        contains(
          contains('ImageModel provider contracts must use doGenerate'),
        ),
      );
      expect(
        result.violations,
        contains(
          contains('SpeechModel provider contracts must use doGenerate'),
        ),
      );
      expect(
        result.violations,
        contains(
          contains('TranscriptionModel provider contracts must use doGenerate'),
        ),
      );
    });

    test('reports chat and UI projection ownership in provider specs',
        () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'packages/llm_dart_provider/lib/src/bad_ui_projection.dart',
        '''
final class CustomUiPart {}

final class BadMapper {
  void use(ChatUiMessage message) {}
}
''',
      );

      final result = await guard.evaluateWorkspaceDependencyGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('llm_dart_provider must not own chat/UI projection'),
        ),
      );
    });

    test('reports provider prompts leaking into app-facing chat input',
        () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'packages/llm_dart_chat/lib/src/chat_input.dart',
        '''
import 'package:llm_dart_ai/llm_dart_ai.dart';

final class ChatInput {
  final PromptMessage message;

  const ChatInput.message(this.message);
}
''',
      );

      final result = await guard.evaluateWorkspaceDependencyGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('app-facing chat input surfaces must use ModelMessage'),
        ),
      );
    });

    test(
        'reports provider prompts in DefaultChatSession app-facing constructor',
        () async {
      final repoRoot = await _createTempWorkspace();
      addTearDown(() async {
        if (repoRoot.existsSync()) {
          await repoRoot.delete(recursive: true);
        }
      });

      await _writeFile(
        repoRoot,
        'packages/llm_dart_chat/lib/src/default_chat_session.dart',
        '''
import 'package:llm_dart_ai/llm_dart_ai.dart';

final class DefaultChatSession {
  DefaultChatSession({
    List<PromptMessage> initialPrompt = const [],
  });

  DefaultChatSession.withPromptHistory({
    List<PromptMessage> initialPrompt = const [],
  });
}
''',
      );

      final result = await guard.evaluateWorkspaceDependencyGuards(
        repoRoot: repoRoot,
      );

      expect(result.passed, isFalse);
      expect(
        result.violations,
        contains(
          contains('app-facing chat input surfaces must use ModelMessage'),
        ),
      );
      expect(
        result.violations
            .where(
              (violation) => violation.contains(
                'packages/llm_dart_chat/lib/src/default_chat_session.dart',
              ),
            )
            .toList(),
        hasLength(1),
      );
    });
  });
}

Future<Directory> _createTempWorkspace() async {
  final repoRoot = await Directory.systemTemp.createTemp(
    'llm_dart_dependency_guards_',
  );

  await _writeFile(
    repoRoot,
    'pubspec.yaml',
    '''
name: llm_dart
dependencies:
  llm_dart_ai:
    path: packages/llm_dart_ai
  llm_dart_chat:
    path: packages/llm_dart_chat
  llm_dart_provider:
    path: packages/llm_dart_provider
  llm_dart_transport:
    path: packages/llm_dart_transport
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_core/pubspec.yaml',
    '''
name: llm_dart_core
dependencies:
  llm_dart_ai:
    path: ../llm_dart_ai
  llm_dart_provider:
    path: ../llm_dart_provider
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_ai/pubspec.yaml',
    '''
name: llm_dart_ai
dependencies:
  llm_dart_provider:
    path: ../llm_dart_provider
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_provider/pubspec.yaml',
    '''
name: llm_dart_provider
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_provider/lib/llm_dart_provider.dart',
    'library;\n',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_flutter/pubspec.yaml',
    '''
name: llm_dart_flutter
dependencies:
  flutter:
    sdk: flutter
  llm_dart_chat:
    path: ../llm_dart_chat
  llm_dart_provider:
    path: ../llm_dart_provider
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_chat/pubspec.yaml',
    '''
name: llm_dart_chat
dependencies:
  llm_dart_ai:
    path: ../llm_dart_ai
  llm_dart_provider:
    path: ../llm_dart_provider
  llm_dart_transport:
    path: ../llm_dart_transport
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_chat/lib/src/chat_input.dart',
    '''
import 'package:llm_dart_ai/llm_dart_ai.dart';

final class ChatInput {
  final UserModelMessage message;

  const ChatInput.message(this.message);
}
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_chat/lib/src/chat_session.dart',
    '''
import 'chat_input.dart';

abstract interface class ChatSession {
  Future<void> sendMessage(ChatInput input);
}
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_chat/lib/src/default_chat_session.dart',
    '''
import 'package:llm_dart_ai/llm_dart_ai.dart';

final class DefaultChatSession {
  DefaultChatSession({
    List<ModelMessage> initialMessages = const [],
  });

  DefaultChatSession.withPromptHistory({
    List<PromptMessage> initialPrompt = const [],
  });
}
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_flutter/lib/src/chat_controller.dart',
    '''
import 'package:llm_dart_chat/llm_dart_chat.dart';

final class ChatController {
  Future<void> sendMessage(ChatInput input) async {}
}
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_transport/pubspec.yaml',
    '''
name: llm_dart_transport
dependencies:
  dio: ^5.9.0
  llm_dart_provider:
    path: ../llm_dart_provider
  logging: ^1.2.0
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_openai/pubspec.yaml',
    '''
name: llm_dart_openai
dependencies:
  llm_dart_provider:
    path: ../llm_dart_provider
  llm_dart_transport:
    path: ../llm_dart_transport
''',
  );
  await _writeFile(
    repoRoot,
    'packages/llm_dart_openai/lib/src/example.dart',
    'void main() {}\n',
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
