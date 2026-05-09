import '../common/model_error.dart';
import '../common/provider_metadata.dart';
import '../model/finish_reason.dart';
import '../stream/text_stream_event.dart';
import 'chat_ui_message.dart';
import 'chat_ui_tool_part_store.dart';

part 'chat_ui_accumulator_data_support.dart';
part 'chat_ui_accumulator_hydration_support.dart';
part 'chat_ui_accumulator_metadata_support.dart';
part 'chat_ui_accumulator_output_support.dart';
part 'chat_ui_accumulator_text_support.dart';

final class ChatUiAccumulatorOptions {
  final bool includeRawChunksInMetadata;

  const ChatUiAccumulatorOptions({
    this.includeRawChunksInMetadata = false,
  });
}

final class ChatUiAccumulator {
  final ChatUiRole role;
  final ChatUiAccumulatorOptions options;

  String _messageId;
  final List<ChatUiPart> _parts;
  final Map<String, Object?> _metadata;
  final Map<String, int> _activeTextPartIndexes = {};
  final Map<String, int> _activeReasoningPartIndexes = {};
  final Map<String, int> _dataPartIndexes = {};
  final ChatUiToolPartStore _toolParts;
  int _nextStepIndex = 0;

  factory ChatUiAccumulator({
    required String messageId,
    ChatUiRole role = ChatUiRole.assistant,
    ChatUiMessage? seedMessage,
    ChatUiAccumulatorOptions options = const ChatUiAccumulatorOptions(),
  }) {
    final assistantSeed =
        seedMessage?.role == ChatUiRole.assistant ? seedMessage : null;

    return ChatUiAccumulator._(
      messageId: assistantSeed?.id ?? messageId,
      role: assistantSeed?.role ?? role,
      parts: List.of(assistantSeed?.parts ?? const <ChatUiPart>[]),
      metadata: Map.of(assistantSeed?.metadata ?? const <String, Object?>{}),
      options: options,
    ).._hydrateIndexes();
  }

  ChatUiAccumulator._({
    required String messageId,
    required this.role,
    required List<ChatUiPart> parts,
    required Map<String, Object?> metadata,
    required this.options,
  })  : _messageId = messageId,
        _parts = parts,
        _metadata = metadata,
        _toolParts = ChatUiToolPartStore(parts);

  ChatUiMessage get message => ChatUiMessage(
        id: _messageId,
        role: role,
        parts: List.of(_parts),
        metadata: Map.of(_metadata),
      );

  ChatUiMessage apply(TextStreamEvent event) {
    switch (event) {
      case StartEvent():
        _applyStartEvent(event);
      case ResponseMetadataEvent():
        _applyResponseMetadataEvent(event);
      case TextStartEvent():
        _applyTextStartEvent(event);
      case TextDeltaEvent():
        _applyTextDeltaEvent(event);
      case TextEndEvent():
        _applyTextEndEvent(event);
      case ReasoningStartEvent():
        _applyReasoningStartEvent(event);
      case ReasoningDeltaEvent():
        _applyReasoningDeltaEvent(event);
      case ReasoningEndEvent():
        _applyReasoningEndEvent(event);
      case ReasoningFileEvent():
        _applyReasoningFileEvent(event);
      case ToolInputStartEvent():
        _toolParts.applyInputStart(event);
      case ToolInputDeltaEvent():
        _toolParts.applyInputDelta(event);
      case ToolInputEndEvent():
        _toolParts.applyInputEnd(event);
      case ToolInputErrorEvent():
        _toolParts.applyInputError(event);
      case ToolCallEvent():
        _toolParts.applyCall(event);
      case ToolApprovalRequestEvent():
        _toolParts.applyApprovalRequest(event);
      case ToolResultEvent():
        _toolParts.applyResult(event);
      case ToolOutputDeniedEvent():
        _toolParts.applyOutputDenied(event);
      case SourceEvent():
        _applySourceEvent(event);
      case FileEvent():
        _applyFileEvent(event);
      case StepStartEvent():
        _applyStepStartEvent(event);
      case StepFinishEvent():
        _applyStepFinishEvent();
      case AbortEvent(:final reason):
        _applyAbortEvent(reason);
      case FinishEvent():
        _applyFinishEvent(event);
      case CustomEvent():
        _applyCustomEvent(event);
      case RawChunkEvent():
        _applyRawChunkEvent(event);
      case ErrorEvent():
        _applyErrorEvent(event);
    }

    return message;
  }

  ChatUiMessage applyDataPart<T>(DataUiPart<T> part) {
    return _applyDataPart(part);
  }

  Stream<ChatUiMessage> project(Stream<TextStreamEvent> events) async* {
    await for (final event in events) {
      yield apply(event);
    }
  }

  int _appendPart(ChatUiPart part) {
    _parts.add(part);
    return _parts.length - 1;
  }

  int _requireActivePartIndex(
    Map<String, int> activeParts,
    String id, {
    required String eventName,
    required String startEventName,
    required String partName,
  }) {
    final index = activeParts[id];
    if (index != null) {
      return index;
    }

    throw StateError(
      'Received $eventName for missing $partName with ID "$id". '
      'Ensure a "$startEventName" event is applied first.',
    );
  }

  void _setMetadataIfNotNull(String key, Object? value) {
    if (value != null) {
      _metadata[key] = value;
    }
  }
}

Stream<ChatUiMessage> projectChatUiMessageStream(
  Stream<TextStreamEvent> events, {
  required String messageId,
  ChatUiRole role = ChatUiRole.assistant,
  ChatUiMessage? seedMessage,
  ChatUiAccumulatorOptions options = const ChatUiAccumulatorOptions(),
}) {
  final accumulator = ChatUiAccumulator(
    messageId: messageId,
    role: role,
    seedMessage: seedMessage,
    options: options,
  );

  return accumulator.project(events);
}
