import 'package:llm_dart_provider/llm_dart_provider.dart'
    hide
        CustomEvent,
        ErrorEvent,
        FileEvent,
        FinishEvent,
        RawChunkEvent,
        ReasoningDeltaEvent,
        ReasoningEndEvent,
        ReasoningFileEvent,
        ReasoningStartEvent,
        ResponseMetadataEvent,
        SourceEvent,
        StartEvent,
        TextDeltaEvent,
        TextEndEvent,
        TextStartEvent,
        ToolApprovalRequestEvent,
        ToolCallEvent,
        ToolInputDeltaEvent,
        ToolInputEndEvent,
        ToolInputErrorEvent,
        ToolInputStartEvent,
        ToolResultEvent;

import '../stream/text_stream_event.dart';
import 'chat_ui_message.dart';
import 'chat_ui_metadata_store.dart';
import 'chat_ui_stream_error.dart';
import 'chat_ui_tool_part_store.dart';

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
  late final ChatUiMetadataStore _metadataStore = ChatUiMetadataStore(
    metadata: _metadata,
    includeRawChunks: options.includeRawChunksInMetadata,
  );
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
      case RunStartEvent():
        _metadataStore.applyRunStart(event);
      case RunFinishEvent():
        _metadataStore.applyRunFinish(event);
      case StartEvent():
        _metadataStore.applyStart(event);
      case ResponseMetadataEvent():
        _metadataStore.applyResponseMetadata(event);
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
        _metadataStore.applyAbort(reason);
      case FinishEvent():
        _metadataStore.applyFinish(event);
      case CustomEvent():
        _applyCustomEvent(event);
      case RawChunkEvent():
        _metadataStore.applyRawChunk(event);
      case ErrorEvent():
        _metadataStore.applyError(event);
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

    throw ChatUiStreamError(
      chunkType: eventName,
      chunkId: id,
      message: 'Received $eventName for missing $partName with ID "$id". '
          'Ensure a "$startEventName" event is applied first.',
    );
  }

  ChatUiMessage _applyDataPart<T>(DataUiPart<T> part) {
    final dataPartId = part.id;
    if (dataPartId == null) {
      _appendPart(part);
      return message;
    }

    final identity = _dataPartIdentity(part.key, dataPartId);
    final index = _dataPartIndexes[identity];
    if (index == null) {
      _dataPartIndexes[identity] = _appendPart(part);
    } else {
      _parts[index] = part;
    }

    return message;
  }

  void _hydrateIndexes() {
    _nextStepIndex = _parts.whereType<StepBoundaryUiPart>().length;

    for (var index = 0; index < _parts.length; index++) {
      final part = _parts[index];
      if (part is ToolUiPart) {
        _toolParts.hydrate(part, index);
        continue;
      }

      if (part case DataUiPart(:final id?, :final key)) {
        _hydrateDataPartIndex(key, id, index);
      }
    }
  }

  void _hydrateDataPartIndex(String key, String id, int index) {
    _dataPartIndexes[_dataPartIdentity(key, id)] = index;
  }

  void _applyReasoningFileEvent(ReasoningFileEvent event) {
    _appendPart(
      ReasoningFileUiPart(
        event.file,
        providerMetadata: event.providerMetadata,
      ),
    );
  }

  void _applySourceEvent(SourceEvent event) {
    _appendPart(SourceUiPart(event.source));
  }

  void _applyFileEvent(FileEvent event) {
    _appendPart(
      FileUiPart(
        event.file,
        providerMetadata: event.providerMetadata,
      ),
    );
  }

  void _applyCustomEvent(CustomEvent event) {
    _appendPart(
      CustomUiPart(
        kind: event.kind,
        data: event.data,
        providerMetadata: event.providerMetadata,
      ),
    );
  }

  void _applyTextStartEvent(TextStartEvent event) {
    _activeTextPartIndexes[event.id] = _appendPart(
      TextUiPart(
        text: '',
        isStreaming: true,
        providerMetadata: event.providerMetadata,
      ),
    );
  }

  void _applyTextDeltaEvent(TextDeltaEvent event) {
    final index = _requireActivePartIndex(
      _activeTextPartIndexes,
      event.id,
      eventName: 'text-delta',
      startEventName: 'text-start',
      partName: 'text part',
    );
    final current = _parts[index] as TextUiPart;
    _parts[index] = TextUiPart(
      text: current.text + event.delta,
      isStreaming: true,
      providerMetadata: ProviderMetadata.mergeNullable(
        current.providerMetadata,
        event.providerMetadata,
      ),
    );
  }

  void _applyTextEndEvent(TextEndEvent event) {
    final index = _requireActivePartIndex(
      _activeTextPartIndexes,
      event.id,
      eventName: 'text-end',
      startEventName: 'text-start',
      partName: 'text part',
    );
    final current = _parts[index] as TextUiPart;
    _parts[index] = TextUiPart(
      text: current.text,
      isStreaming: false,
      providerMetadata: ProviderMetadata.mergeNullable(
        current.providerMetadata,
        event.providerMetadata,
      ),
    );
    _activeTextPartIndexes.remove(event.id);
  }

  void _applyReasoningStartEvent(ReasoningStartEvent event) {
    _activeReasoningPartIndexes[event.id] = _appendPart(
      ReasoningUiPart(
        text: '',
        isStreaming: true,
        providerMetadata: event.providerMetadata,
      ),
    );
  }

  void _applyReasoningDeltaEvent(ReasoningDeltaEvent event) {
    final index = _requireActivePartIndex(
      _activeReasoningPartIndexes,
      event.id,
      eventName: 'reasoning-delta',
      startEventName: 'reasoning-start',
      partName: 'reasoning part',
    );
    final current = _parts[index] as ReasoningUiPart;
    _parts[index] = ReasoningUiPart(
      text: current.text + event.delta,
      isStreaming: true,
      providerMetadata: ProviderMetadata.mergeNullable(
        current.providerMetadata,
        event.providerMetadata,
      ),
    );
  }

  void _applyReasoningEndEvent(ReasoningEndEvent event) {
    final index = _requireActivePartIndex(
      _activeReasoningPartIndexes,
      event.id,
      eventName: 'reasoning-end',
      startEventName: 'reasoning-start',
      partName: 'reasoning part',
    );
    final current = _parts[index] as ReasoningUiPart;
    _parts[index] = ReasoningUiPart(
      text: current.text,
      isStreaming: false,
      providerMetadata: ProviderMetadata.mergeNullable(
        current.providerMetadata,
        event.providerMetadata,
      ),
    );
    _activeReasoningPartIndexes.remove(event.id);
  }

  void _applyStepStartEvent(StepStartEvent event) {
    final stepId = event.stepId ?? 'step-$_nextStepIndex';
    _nextStepIndex += 1;
    _appendPart(StepBoundaryUiPart(stepId));
  }

  void _applyStepFinishEvent() {
    _activeTextPartIndexes.clear();
    _activeReasoningPartIndexes.clear();
    _toolParts.clearStreamingInputs();
  }
}

String _dataPartIdentity(String key, String id) => '$key\u0000$id';

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
