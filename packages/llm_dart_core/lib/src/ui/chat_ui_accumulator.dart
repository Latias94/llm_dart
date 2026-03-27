import 'dart:convert';

import '../common/provider_metadata.dart';
import '../stream/text_stream_event.dart';
import 'chat_ui_message.dart';

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
              _mergeProviderMetadata(
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
          providerMetadata: _mergeProviderMetadata(
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
          providerMetadata: _mergeProviderMetadata(
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
          providerMetadata: _mergeProviderMetadata(
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
          providerMetadata: _mergeProviderMetadata(
            current.providerMetadata,
            event.providerMetadata,
          ),
        );
        _activeReasoningPartIndexes.remove(event.id);
      case ToolInputStartEvent():
        _partialToolInputs[event.toolCallId] = _PartialToolInput(
          toolName: event.toolName,
          providerExecuted: event.providerExecuted,
          isDynamic: event.isDynamic,
          title: event.title,
        );
        _upsertToolPart(
          _buildToolPart(
            toolCallId: event.toolCallId,
            toolName: event.toolName,
            state: ToolUiPartState.inputStreaming,
            setInput: true,
            input: null,
            setInputText: true,
            inputText: null,
            setOutput: true,
            output: null,
            setErrorText: true,
            errorText: null,
            providerExecuted: event.providerExecuted,
            isDynamic: event.isDynamic,
            setTitle: true,
            title: event.title,
            callProviderMetadata: event.providerMetadata,
          ),
        );
      case ToolInputDeltaEvent():
        final partial = _requirePartialToolInput(event.toolCallId);
        partial.append(event.delta);
        _upsertToolPart(
          _buildToolPart(
            toolCallId: event.toolCallId,
            state: ToolUiPartState.inputStreaming,
            setInput: true,
            input: _decodeToolInputValue(partial.text),
            setInputText: true,
            inputText: partial.text,
            callProviderMetadata: event.providerMetadata,
          ),
        );
      case ToolInputEndEvent():
        final partial = _requirePartialToolInput(event.toolCallId);
        _upsertToolPart(
          _buildToolPart(
            toolCallId: event.toolCallId,
            state: ToolUiPartState.inputAvailable,
            setInput: true,
            input: _decodeToolInputValue(partial.text),
            setInputText: true,
            inputText: partial.text,
            callProviderMetadata: event.providerMetadata,
          ),
        );
        _partialToolInputs.remove(event.toolCallId);
      case ToolInputErrorEvent():
        final partial = _partialToolInputs.remove(event.toolCallId);
        final input = event.input ??
            (partial == null ? null : _decodeToolInputValue(partial.text));
        final inputText = partial?.text ?? _stringifyValue(input);
        _upsertToolPart(
          _buildToolPart(
            toolCallId: event.toolCallId,
            toolName: event.toolName,
            state: ToolUiPartState.outputError,
            setInput: true,
            input: input,
            setInputText: true,
            inputText: inputText,
            setOutput: true,
            output: null,
            setErrorText: true,
            errorText: event.errorText,
            providerExecuted: event.providerExecuted,
            isDynamic: event.isDynamic,
            setTitle: event.title != null,
            title: event.title,
            callProviderMetadata: event.providerMetadata,
          ),
        );
      case ToolCallEvent():
        _partialToolInputs.remove(event.toolCall.toolCallId);
        _upsertToolPart(
          _buildToolPart(
            toolCallId: event.toolCall.toolCallId,
            toolName: event.toolCall.toolName,
            state: ToolUiPartState.inputAvailable,
            setInput: true,
            input: event.toolCall.input,
            providerExecuted: event.toolCall.providerExecuted,
            isDynamic: event.toolCall.isDynamic,
            setTitle: true,
            title: event.toolCall.title,
            callProviderMetadata: event.providerMetadata,
          ),
        );
      case ToolApprovalRequestEvent():
        _upsertToolPart(
          _buildToolPart(
            toolCallId: event.toolCallId,
            state: ToolUiPartState.approvalRequested,
            setApproval: true,
            approval: ToolApprovalUiState(
              approvalId: event.approvalId,
            ),
            callProviderMetadata: event.providerMetadata,
          ),
        );
      case ToolResultEvent():
        _partialToolInputs.remove(event.toolResult.toolCallId);
        _upsertToolPart(
          _buildToolPart(
            toolCallId: event.toolResult.toolCallId,
            toolName: event.toolResult.toolName,
            state: event.toolResult.isError
                ? ToolUiPartState.outputError
                : ToolUiPartState.outputAvailable,
            setOutput: true,
            output: event.toolResult.output,
            setErrorText: true,
            errorText: event.toolResult.isError
                ? _stringifyValue(event.toolResult.output)
                : null,
            preliminary: event.toolResult.preliminary,
            isDynamic: event.toolResult.isDynamic,
            resultProviderMetadata: event.providerMetadata,
          ),
        );
      case ToolOutputDeniedEvent():
        _upsertToolPart(
          _buildToolPart(
            toolCallId: event.toolCallId,
            state: ToolUiPartState.outputDenied,
            resultProviderMetadata: event.providerMetadata,
          ),
        );
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
      case FinishEvent():
        _metadata[ChatUiMetadataKeys.finishReason] = event.finishReason;
        _setMetadataIfNotNull(
          ChatUiMetadataKeys.rawFinishReason,
          event.rawFinishReason,
        );
        if (event.usage != null) {
          _metadata[ChatUiMetadataKeys.usage] = event.usage;
        }
        if (event.providerMetadata != null) {
          _metadata[ChatUiMetadataKeys.finishProviderMetadata] =
              _mergeProviderMetadata(
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
            _metadata[ChatUiMetadataKeys.errors] as List<Object?>? ??
                const <Object?>[];
        _metadata[ChatUiMetadataKeys.errors] =
            List<Object?>.unmodifiable([...current, event.error]);
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

  ToolUiPart? _toolPart(String toolCallId) {
    final index = _toolPartIndexes[toolCallId];
    if (index == null) {
      return null;
    }

    return _parts[index] as ToolUiPart;
  }

  void _upsertToolPart(ToolUiPart part) {
    final index = _toolPartIndexes[part.toolCallId];
    if (index == null) {
      _toolPartIndexes[part.toolCallId] = _appendPart(part);
      return;
    }

    _parts[index] = part;
  }

  ToolUiPart _buildToolPart({
    required String toolCallId,
    String? toolName,
    ToolUiPartState? state,
    Object? input,
    bool setInput = false,
    String? inputText,
    bool setInputText = false,
    Object? output,
    bool setOutput = false,
    String? errorText,
    bool setErrorText = false,
    bool? providerExecuted,
    bool? isDynamic,
    bool? preliminary,
    String? title,
    bool setTitle = false,
    ToolApprovalUiState? approval,
    bool setApproval = false,
    ProviderMetadata? callProviderMetadata,
    ProviderMetadata? resultProviderMetadata,
  }) {
    final current = _toolPart(toolCallId);
    final partial = _partialToolInputs[toolCallId];
    final resolvedToolName = toolName ?? current?.toolName ?? partial?.toolName;

    if (resolvedToolName == null) {
      throw StateError(
        'Received tool update for missing tool call with ID "$toolCallId". '
        'Ensure a tool-input-start or tool-call event is applied first.',
      );
    }

    return ToolUiPart(
      toolCallId: toolCallId,
      toolName: resolvedToolName,
      state: state ?? current?.state ?? ToolUiPartState.inputAvailable,
      input: setInput ? input : current?.input,
      inputText: setInputText ? inputText : current?.inputText,
      output: setOutput ? output : current?.output,
      errorText: setErrorText ? errorText : current?.errorText,
      providerExecuted: current?.providerExecuted == true ||
          providerExecuted == true ||
          partial?.providerExecuted == true,
      isDynamic: current?.isDynamic == true ||
          isDynamic == true ||
          partial?.isDynamic == true,
      preliminary: preliminary ?? current?.preliminary ?? false,
      title: setTitle ? title : current?.title ?? partial?.title,
      approval: setApproval ? approval : current?.approval,
      callProviderMetadata: _mergeProviderMetadata(
        current?.callProviderMetadata,
        callProviderMetadata,
      ),
      resultProviderMetadata: _mergeProviderMetadata(
        current?.resultProviderMetadata,
        resultProviderMetadata,
      ),
    );
  }

  _PartialToolInput _requirePartialToolInput(String toolCallId) {
    final value = _partialToolInputs[toolCallId];
    if (value != null) {
      return value;
    }

    throw StateError(
      'Received tool-input update for missing tool call with ID "$toolCallId". '
      'Ensure a "tool-input-start" event is applied before later tool-input events.',
    );
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

ProviderMetadata? _mergeProviderMetadata(
  ProviderMetadata? current,
  ProviderMetadata? next,
) {
  if (current == null || current.isEmpty) {
    return next;
  }

  if (next == null || next.isEmpty) {
    return current;
  }

  final merged = <String, Object?>{
    ...current.values,
  };

  for (final entry in next.values.entries) {
    final previous = merged[entry.key];
    final value = entry.value;

    if (previous is Map && value is Map) {
      merged[entry.key] = <Object?, Object?>{
        ...previous,
        ...value,
      };
      continue;
    }

    merged[entry.key] = value;
  }

  return ProviderMetadata(merged);
}

Object? _decodeToolInputValue(String inputText) {
  final trimmed = inputText.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  try {
    return jsonDecode(trimmed);
  } on FormatException {
    return inputText;
  }
}

String? _stringifyValue(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is String) {
    return value;
  }

  try {
    return jsonEncode(value);
  } on JsonUnsupportedObjectError {
    return value.toString();
  }
}

final class _PartialToolInput {
  final String toolName;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;
  final StringBuffer _buffer;

  _PartialToolInput({
    required this.toolName,
    required this.providerExecuted,
    required this.isDynamic,
    required this.title,
    String initialText = '',
  }) : _buffer = StringBuffer(initialText);

  String get text => _buffer.toString();

  void append(String value) {
    _buffer.write(value);
  }
}
