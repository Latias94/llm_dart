// ignore_for_file: avoid_print

import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart';

Future<void> main() async {
  final store = _MemoryPersistenceStore();
  final persistence = ChatPersistenceAdapter(store: store);
  final session = _buildSession();
  final subscription = session.states.listen(_printState);

  try {
    await session.sendMessage(
      ChatInput.text('What is the weather in Hong Kong?'),
    );
    await _waitUntilReady(session);

    await persistence.saveSession(session);
    print('\nPersisted chatId=${session.state.chatId}');

    final restoredSession =
        await persistence.restoreSession<DefaultChatSession>(
      session.state.chatId,
      createSession: (snapshot) => _buildSession(snapshot: snapshot),
    );

    if (restoredSession != null) {
      final latest =
          const ChatMessageMapper().map(restoredSession.state.messages.last);
      print('restoredMessages=${restoredSession.state.messages.length}');
      print('restoredLatestText=${latest.text}');
      await restoredSession.dispose();
    }
  } finally {
    await subscription.cancel();
    await session.dispose();
  }
}

Future<void> _waitUntilReady(ChatSession session) async {
  if (session.state.status == ChatStatus.ready) {
    return;
  }

  await session.states.firstWhere((state) => state.status == ChatStatus.ready);
}

DefaultChatSession _buildSession({
  ChatSessionSnapshot? snapshot,
}) {
  final registry = ToolExecutionRegistry().withJsonHandler<String>(
    'weather',
    decode: (json) => json['location']! as String,
    handle: (request, location) async {
      print('tool ${request.toolName} -> $location');
      return ToolExecutionResult.toolOutput(
        JsonToolOutput({
          'location': location,
          'temperatureC': 24,
          'condition': 'clear',
        }),
      );
    },
  );

  if (snapshot != null) {
    return DefaultChatSession.fromSnapshot(
      transport: const DirectChatTransport(
        model: _DemoWeatherLanguageModel(),
      ),
      snapshot: snapshot,
      toolExecutionRegistry: registry,
    );
  }

  return DefaultChatSession(
    transport: const DirectChatTransport(
      model: _DemoWeatherLanguageModel(),
    ),
    toolExecutionRegistry: registry,
  );
}

void _printState(ChatState state) {
  print('status=${state.status}');

  if (state.messages.isEmpty) {
    return;
  }

  final latest = state.messages.last;
  final mapped = const ChatMessageMapper().map(latest);
  print('latestRole=${latest.role}');

  for (final toolPart in mapped.toolParts) {
    print('tool=${toolPart.toolName} state=${toolPart.state}');
  }

  if (mapped.text.isNotEmpty) {
    print('latestText=${mapped.text}');
  }
}

final class _MemoryPersistenceStore implements ChatPersistenceStore {
  final Map<String, Object?> _storage = <String, Object?>{};

  @override
  Future<void> deleteSnapshot(String chatId) async {
    _storage.remove(chatId);
  }

  @override
  Future<Object?> readSnapshot(String chatId) async {
    return _storage[chatId];
  }

  @override
  Future<void> writeSnapshot(String chatId, Object? snapshotEnvelope) async {
    _storage[chatId] = snapshotEnvelope;
  }
}

final class _DemoWeatherLanguageModel implements LanguageModel {
  const _DemoWeatherLanguageModel();

  @override
  String get providerId => 'demo';

  @override
  String get modelId => 'demo-weather';

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) {
    throw UnimplementedError(
      'This example focuses on stream-driven chat sessions.',
    );
  }

  @override
  Stream<TextStreamEvent> doStream(GenerateTextRequest request) async* {
    yield StartEvent();

    ToolPromptMessage? toolMessage;
    for (final message in request.prompt) {
      if (message is ToolPromptMessage) {
        toolMessage = message;
      }
    }

    if (toolMessage == null) {
      yield const ToolCallEvent(
        toolCall: ToolCallContent(
          toolCallId: 'tool-weather-1',
          toolName: 'weather',
          input: {
            'location': 'Hong Kong',
          },
        ),
      );
      yield const FinishEvent(
        finishReason: FinishReason.toolCalls,
      );
      return;
    }

    final resultPart = toolMessage.parts.whereType<ToolResultPromptPart>().last;
    final output = resultPart.toolOutput.value as Map<String, Object?>;
    final location = output['location'] as String? ?? 'unknown';
    final temperatureC = output['temperatureC'];
    final condition = output['condition'] as String? ?? 'unknown';

    yield const TextStartEvent(id: 'text-1');
    yield TextDeltaEvent(
      id: 'text-1',
      delta: 'The weather in $location is $temperatureC C and $condition.',
    );
    yield const TextEndEvent(id: 'text-1');
    yield const FinishEvent(
      finishReason: FinishReason.stop,
    );
  }
}
