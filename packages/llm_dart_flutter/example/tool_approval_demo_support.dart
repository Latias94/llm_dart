import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

const String demoProviderToolCallId = 'tool-browser-1';
const String demoProviderApprovalId = 'approval-browser-1';
const String demoLocalToolCallId = 'tool-weather-1';

ChatController createToolApprovalDemoController({
  ChatSessionSnapshot? snapshot,
}) {
  return ChatController(
    session: createToolApprovalDemoSession(
      snapshot: snapshot,
    ),
  );
}

DefaultChatSession createToolApprovalDemoSession({
  ChatSessionSnapshot? snapshot,
}) {
  const transport = DirectChatTransport(
    model: _ToolApprovalDemoLanguageModel(),
  );

  if (snapshot != null) {
    return DefaultChatSession.fromSnapshot(
      transport: transport,
      snapshot: snapshot,
    );
  }

  return DefaultChatSession(
    transport: transport,
  );
}

String toolUiStateLabel(ToolUiPartState state) {
  return switch (state) {
    ToolUiPartState.inputStreaming => 'inputStreaming',
    ToolUiPartState.inputAvailable => 'inputAvailable',
    ToolUiPartState.approvalRequested => 'approvalRequested',
    ToolUiPartState.approvalResponded => 'approvalResponded',
    ToolUiPartState.outputAvailable => 'outputAvailable',
    ToolUiPartState.outputError => 'outputError',
    ToolUiPartState.outputDenied => 'outputDenied',
  };
}

ToolOutput buildDemoLocalToolOutput(ToolUiPart part) {
  final input = switch (part.input) {
    Map<String, Object?>() => part.input as Map<String, Object?>,
    Map() => Map<String, Object?>.from(part.input as Map),
    _ => const <String, Object?>{},
  };

  final location = input['location'] as String? ?? 'Tokyo';

  return JsonToolOutput({
    'location': location,
    'temperatureC': 24,
    'condition': 'clear',
  });
}

final class DemoMemoryChatPersistenceStore implements ChatPersistenceStore {
  final Map<String, Object?> _snapshots = <String, Object?>{};

  @override
  Future<void> deleteSnapshot(String chatId) async {
    _snapshots.remove(chatId);
  }

  @override
  Future<Object?> readSnapshot(String chatId) async {
    return _snapshots[chatId];
  }

  @override
  Future<void> writeSnapshot(
    String chatId,
    Object? snapshotEnvelope,
  ) async {
    _snapshots[chatId] = snapshotEnvelope;
  }
}

final class _ToolApprovalDemoLanguageModel implements LanguageModel {
  const _ToolApprovalDemoLanguageModel();

  @override
  String get providerId => 'demo';

  @override
  String get modelId => 'demo-tool-approval';

  @override
  Future<GenerateTextResult> generate(GenerateTextRequest request) {
    throw UnimplementedError(
      'This demo focuses on stream-driven chat sessions.',
    );
  }

  @override
  Stream<TextStreamEvent> stream(GenerateTextRequest request) async* {
    final approvalResponse = _findApprovalResponse(request.prompt);
    final localToolResult = _findLocalToolResult(request.prompt);
    final latestUserText = _latestUserText(request.prompt);

    yield StartEvent();
    yield ResponseMetadataEvent(
      responseId: 'demo-tool-turn-${request.prompt.length}',
      modelId: modelId,
    );

    if (approvalResponse == null && localToolResult == null) {
      yield const TextStartEvent(id: 'text-1');
      yield const TextDeltaEvent(
        id: 'text-1',
        delta:
            'I need one provider approval and one local tool result before I can finish this answer. ',
      );
      yield const TextEndEvent(id: 'text-1');
      yield const ToolCallEvent(
        toolCall: ToolCallContent(
          toolCallId: demoProviderToolCallId,
          toolName: 'computer',
          input: {
            'action': 'click',
            'target': 'Publish button',
          },
          providerExecuted: true,
          isDynamic: true,
          title: 'Browser',
        ),
      );
      yield const ToolApprovalRequestEvent(
        approvalId: demoProviderApprovalId,
        toolCallId: demoProviderToolCallId,
      );
      yield const ToolCallEvent(
        toolCall: ToolCallContent(
          toolCallId: demoLocalToolCallId,
          toolName: 'weather',
          input: {
            'location': 'Tokyo',
          },
        ),
      );
      yield const FinishEvent(
        finishReason: FinishReason.toolCalls,
      );
      return;
    }

    final localOutput = _normalizeLocalToolOutput(localToolResult?.toolOutput);
    final approvalStatus = approvalResponse?.approved == true
        ? 'The provider-side browser action was approved.'
        : 'The provider-side browser action was denied.';
    final approvalReason = approvalResponse?.reason == null
        ? ''
        : ' Reason: ${approvalResponse!.reason}.';

    yield const TextStartEvent(id: 'text-1');
    yield TextDeltaEvent(
      id: 'text-1',
      delta: 'Tool orchestration completed for "$latestUserText". ',
    );
    yield TextDeltaEvent(
      id: 'text-1',
      delta: '$approvalStatus$approvalReason ',
    );
    yield TextDeltaEvent(
      id: 'text-1',
      delta:
          'Local weather returned ${localOutput['location']}, ${localOutput['temperatureC']} C, ${localOutput['condition']}.',
    );
    yield const TextEndEvent(id: 'text-1');
    yield const FinishEvent(
      finishReason: FinishReason.stop,
    );
  }

  ToolApprovalResponsePromptPart? _findApprovalResponse(
    List<PromptMessage> prompt,
  ) {
    for (final message in prompt.reversed) {
      if (message is! ToolPromptMessage) {
        continue;
      }

      for (final part in message.parts.reversed) {
        if (part is ToolApprovalResponsePromptPart &&
            part.approvalId == demoProviderApprovalId) {
          return part;
        }
      }
    }

    return null;
  }

  ToolResultPromptPart? _findLocalToolResult(List<PromptMessage> prompt) {
    for (final message in prompt.reversed) {
      if (message is! ToolPromptMessage) {
        continue;
      }

      for (final part in message.parts.reversed) {
        if (part is ToolResultPromptPart &&
            part.toolCallId == demoLocalToolCallId) {
          return part;
        }
      }
    }

    return null;
  }

  String _latestUserText(List<PromptMessage> prompt) {
    for (final message in prompt.reversed) {
      if (message is! UserPromptMessage) {
        continue;
      }

      final text = message.parts
          .whereType<TextPromptPart>()
          .map((part) => part.text)
          .join(' ')
          .trim();
      if (text.isNotEmpty) {
        return text;
      }
    }

    return 'the user request';
  }

  Map<String, Object?> _normalizeLocalToolOutput(ToolOutput? output) {
    final value = output?.value;

    if (value is Map<String, Object?>) {
      return value;
    }

    if (value is Map) {
      return Map<String, Object?>.from(value);
    }

    return const {
      'location': 'Tokyo',
      'temperatureC': 24,
      'condition': 'clear',
    };
  }
}
