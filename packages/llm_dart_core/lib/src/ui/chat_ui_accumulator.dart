import 'dart:convert';

import '../common/model_error.dart';
import '../model/language_model.dart';
import '../common/provider_metadata.dart';
import '../stream/text_stream_event.dart';
import 'chat_ui_message.dart';

part 'chat_ui_accumulator_tool_support.dart';

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
  final Map<String, int> _toolPartIndexes = {};
  final Map<String, int> _dataPartIndexes = {};
  final Map<String, _PartialToolInput> _partialToolInputs = {};
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
        _metadata = metadata;

  ChatUiMessage get message => ChatUiMessage(
        id: _messageId,
        role: role,
        parts: List.of(_parts),
        metadata: Map.of(_metadata),
      );

  ChatUiMessage apply(TextStreamEvent event) {
    switch (event) {
      case StartEvent():
        _metadata[ChatUiMetadataKeys.warnings] =
            List.unmodifiable(event.warnings);
      case ResponseMetadataEvent():
        _setMetadataIfNotNull(ChatUiMetadataKeys.responseId, event.responseId);
        _setMetadataIfNotNull(
          ChatUiMetadataKeys.responseTimestamp,
          event.timestamp,
        );
        _setMetadataIfNotNull(ChatUiMetadataKeys.modelId, event.modelId);
        if (event.providerMetadata != null) {
          _metadata[ChatUiMetadataKeys.responseProviderMetadata] =
              ProviderMetadata.mergeNullable(
            _metadata[ChatUiMetadataKeys.responseProviderMetadata]
                as ProviderMetadata?,
            event.providerMetadata,
          );
        }
      case TextStartEvent():
        _activeTextPartIndexes[event.id] = _appendPart(
          TextUiPart(
            text: '',
            isStreaming: true,
            providerMetadata: event.providerMetadata,
          ),
        );
      case TextDeltaEvent():
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
      case TextEndEvent():
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
      case ReasoningStartEvent():
        _activeReasoningPartIndexes[event.id] = _appendPart(
          ReasoningUiPart(
            text: '',
            isStreaming: true,
            providerMetadata: event.providerMetadata,
          ),
        );
      case ReasoningDeltaEvent():
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
      case ReasoningEndEvent():
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
      case ReasoningFileEvent():
        _appendPart(
          ReasoningFileUiPart(
            event.file,
            providerMetadata: event.providerMetadata,
          ),
        );
      case ToolInputStartEvent():
        _applyToolInputStartEvent(event);
      case ToolInputDeltaEvent():
        _applyToolInputDeltaEvent(event);
      case ToolInputEndEvent():
        _applyToolInputEndEvent(event);
      case ToolInputErrorEvent():
        _applyToolInputErrorEvent(event);
      case ToolCallEvent():
        _applyToolCallEvent(event);
      case ToolApprovalRequestEvent():
        _applyToolApprovalRequestEvent(event);
      case ToolResultEvent():
        _applyToolResultEvent(event);
      case ToolOutputDeniedEvent():
        _applyToolOutputDeniedEvent(event);
      case SourceEvent():
        _appendPart(SourceUiPart(event.source));
      case FileEvent():
        _appendPart(
          FileUiPart(
            event.file,
            providerMetadata: event.providerMetadata,
          ),
        );
      case StepStartEvent():
        final stepId = event.stepId ?? 'step-$_nextStepIndex';
        _nextStepIndex += 1;
        _appendPart(StepBoundaryUiPart(stepId));
      case StepFinishEvent():
        _activeTextPartIndexes.clear();
        _activeReasoningPartIndexes.clear();
        _partialToolInputs.clear();
      case AbortEvent(:final reason):
        _metadata[ChatUiMetadataKeys.isAborted] = true;
        if (reason != null) {
          _metadata[ChatUiMetadataKeys.abortReason] = reason;
        }
      case FinishEvent():
        _metadata[ChatUiMetadataKeys.finishReason] = event.finishReason;
        _setMetadataIfNotNull(
          ChatUiMetadataKeys.rawFinishReason,
          event.rawFinishReason,
        );
        if (event.finishReason == FinishReason.aborted) {
          _metadata[ChatUiMetadataKeys.isAborted] = true;
          _setMetadataIfNotNull(
            ChatUiMetadataKeys.abortReason,
            event.rawFinishReason,
          );
        }
        if (event.usage != null) {
          _metadata[ChatUiMetadataKeys.usage] = event.usage;
        }
        if (event.providerMetadata != null) {
          _metadata[ChatUiMetadataKeys.finishProviderMetadata] =
              ProviderMetadata.mergeNullable(
            _metadata[ChatUiMetadataKeys.finishProviderMetadata]
                as ProviderMetadata?,
            event.providerMetadata,
          );
        }
      case CustomEvent():
        _appendPart(
          CustomUiPart(
            kind: event.kind,
            data: event.data,
            providerMetadata: event.providerMetadata,
          ),
        );
      case RawChunkEvent():
        if (options.includeRawChunksInMetadata) {
          final current =
              _metadata[ChatUiMetadataKeys.rawChunks] as List<Object?>? ??
                  const <Object?>[];
          _metadata[ChatUiMetadataKeys.rawChunks] =
              List<Object?>.unmodifiable([...current, event.raw]);
        }
      case ErrorEvent():
        final current =
            _metadata[ChatUiMetadataKeys.errors] as List<ModelError>? ??
                const <ModelError>[];
        _metadata[ChatUiMetadataKeys.errors] =
            List<ModelError>.unmodifiable([...current, event.error]);
    }

    return message;
  }

  ChatUiMessage applyDataPart<T>(DataUiPart<T> part) {
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

  Stream<ChatUiMessage> project(Stream<TextStreamEvent> events) async* {
    await for (final event in events) {
      yield apply(event);
    }
  }

  void _hydrateIndexes() {
    _nextStepIndex = _parts.whereType<StepBoundaryUiPart>().length;

    for (var index = 0; index < _parts.length; index++) {
      final part = _parts[index];
      if (part is ToolUiPart) {
        _toolPartIndexes[part.toolCallId] = index;
        if (part.state == ToolUiPartState.inputStreaming) {
          _partialToolInputs[part.toolCallId] = _PartialToolInput(
            toolName: part.toolName,
            providerExecuted: part.providerExecuted,
            isDynamic: part.isDynamic,
            title: part.title,
            initialText: part.inputText ?? _stringifyValue(part.input) ?? '',
          );
        }
        continue;
      }

      if (part case DataUiPart(:final id?, :final key)) {
        _dataPartIndexes[_dataPartIdentity(key, id)] = index;
      }
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
