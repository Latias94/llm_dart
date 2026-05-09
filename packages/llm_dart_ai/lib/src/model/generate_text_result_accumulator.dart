import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

final class GenerateTextResultAccumulator {
  final List<ContentPart> _content = <ContentPart>[];
  final Map<String, int> _activeTextPartIndexes = <String, int>{};
  final Map<String, int> _activeReasoningPartIndexes = <String, int>{};
  final Map<String, int> _toolCallPartIndexes = <String, int>{};
  final Map<String, _PartialToolCall> _partialToolCalls =
      <String, _PartialToolCall>{};
  final List<ModelWarning> _warnings = <ModelWarning>[];

  String? _responseId;
  DateTime? _responseTimestamp;
  String? _responseModelId;
  FinishReason? _finishReason;
  String? _rawFinishReason;
  UsageStats? _usage;
  ProviderMetadata? _providerMetadata;
  ModelError? _error;

  bool get hasFinishEvent => _finishReason != null;
  String get text =>
      _content.whereType<TextContentPart>().map((part) => part.text).join();

  void apply(TextStreamEvent event) {
    switch (event) {
      case StartEvent(:final warnings):
        _warnings.addAll(warnings);
      case ResponseMetadataEvent():
        _setIfNotNull(
          event.responseId,
          (value) => _responseId = value,
        );
        _setIfNotNull(
          event.timestamp,
          (value) => _responseTimestamp = value,
        );
        _setIfNotNull(
          event.modelId,
          (value) => _responseModelId = value,
        );
        _mergeProviderMetadata(event.providerMetadata);
      case TextStartEvent():
        _mergeProviderMetadata(event.providerMetadata);
        _activeTextPartIndexes[event.id] = _appendPart(
          TextContentPart(
            '',
            providerMetadata: event.providerMetadata,
          ),
        );
      case TextDeltaEvent():
        _mergeProviderMetadata(event.providerMetadata);
        final index = _requireActivePartIndex(
          _activeTextPartIndexes,
          event.id,
          eventName: 'text-delta',
          startEventName: 'text-start',
          partName: 'text part',
        );
        final current = _content[index] as TextContentPart;
        _content[index] = TextContentPart(
          current.text + event.delta,
          providerMetadata: ProviderMetadata.mergeNullable(
            current.providerMetadata,
            event.providerMetadata,
          ),
        );
      case TextEndEvent():
        _mergeProviderMetadata(event.providerMetadata);
        final index = _requireActivePartIndex(
          _activeTextPartIndexes,
          event.id,
          eventName: 'text-end',
          startEventName: 'text-start',
          partName: 'text part',
        );
        final current = _content[index] as TextContentPart;
        _content[index] = TextContentPart(
          current.text,
          providerMetadata: ProviderMetadata.mergeNullable(
            current.providerMetadata,
            event.providerMetadata,
          ),
        );
        _activeTextPartIndexes.remove(event.id);
      case ReasoningStartEvent():
        _mergeProviderMetadata(event.providerMetadata);
        _activeReasoningPartIndexes[event.id] = _appendPart(
          ReasoningContentPart(
            '',
            providerMetadata: event.providerMetadata,
          ),
        );
      case ReasoningDeltaEvent():
        _mergeProviderMetadata(event.providerMetadata);
        final index = _requireActivePartIndex(
          _activeReasoningPartIndexes,
          event.id,
          eventName: 'reasoning-delta',
          startEventName: 'reasoning-start',
          partName: 'reasoning part',
        );
        final current = _content[index] as ReasoningContentPart;
        _content[index] = ReasoningContentPart(
          current.text + event.delta,
          providerMetadata: ProviderMetadata.mergeNullable(
            current.providerMetadata,
            event.providerMetadata,
          ),
        );
      case ReasoningEndEvent():
        _mergeProviderMetadata(event.providerMetadata);
        final index = _requireActivePartIndex(
          _activeReasoningPartIndexes,
          event.id,
          eventName: 'reasoning-end',
          startEventName: 'reasoning-start',
          partName: 'reasoning part',
        );
        final current = _content[index] as ReasoningContentPart;
        _content[index] = ReasoningContentPart(
          current.text,
          providerMetadata: ProviderMetadata.mergeNullable(
            current.providerMetadata,
            event.providerMetadata,
          ),
        );
        _activeReasoningPartIndexes.remove(event.id);
      case ReasoningFileEvent():
        _mergeProviderMetadata(event.providerMetadata);
        _appendPart(
          ReasoningFileContentPart(
            event.file,
            providerMetadata: event.providerMetadata,
          ),
        );
      case ToolInputStartEvent():
        _mergeProviderMetadata(event.providerMetadata);
        _partialToolCalls[event.toolCallId] = _PartialToolCall(
          toolName: event.toolName,
          providerExecuted: event.providerExecuted,
          isDynamic: event.isDynamic,
          title: event.title,
          providerMetadata: event.providerMetadata,
        );
      case ToolInputDeltaEvent():
        _mergeProviderMetadata(event.providerMetadata);
        final partial = _requirePartialToolCall(event.toolCallId);
        partial.append(event.delta);
        partial.providerMetadata = ProviderMetadata.mergeNullable(
          partial.providerMetadata,
          event.providerMetadata,
        );
      case ToolInputEndEvent():
        _mergeProviderMetadata(event.providerMetadata);
        final partial = _requirePartialToolCall(event.toolCallId);
        final providerMetadata = ProviderMetadata.mergeNullable(
          partial.providerMetadata,
          event.providerMetadata,
        );
        _upsertToolCallPart(
          ToolCallContentPart(
            ToolCallContent(
              toolCallId: event.toolCallId,
              toolName: partial.toolName,
              input: _decodeToolInputValue(partial.text),
              providerExecuted: partial.providerExecuted,
              isDynamic: partial.isDynamic,
              title: partial.title,
            ),
            providerMetadata: providerMetadata,
          ),
        );
        _partialToolCalls.remove(event.toolCallId);
      case ToolInputErrorEvent():
        _mergeProviderMetadata(event.providerMetadata);
        _partialToolCalls.remove(event.toolCallId);
      case ToolCallEvent():
        _mergeProviderMetadata(event.providerMetadata);
        final current = _toolCallPart(event.toolCall.toolCallId);
        _upsertToolCallPart(
          ToolCallContentPart(
            event.toolCall,
            providerMetadata: ProviderMetadata.mergeNullable(
              current?.providerMetadata,
              event.providerMetadata,
            ),
          ),
        );
        _partialToolCalls.remove(event.toolCall.toolCallId);
      case ToolResultEvent():
        _mergeProviderMetadata(event.providerMetadata);
        _partialToolCalls.remove(event.toolResult.toolCallId);
        _appendPart(
          ToolResultContentPart(
            event.toolResult,
            providerMetadata: event.providerMetadata,
          ),
        );
      case ToolApprovalRequestEvent():
        _mergeProviderMetadata(event.providerMetadata);
        _appendPart(
          ToolApprovalRequestContentPart(
            ToolApprovalRequestContent(
              approvalId: event.approvalId,
              toolCallId: event.toolCallId,
            ),
            providerMetadata: event.providerMetadata,
          ),
        );
      case ToolOutputDeniedEvent():
        _mergeProviderMetadata(event.providerMetadata);
        _partialToolCalls.remove(event.toolCallId);
        final toolCall = _requireToolCallPart(event.toolCallId);
        _appendPart(
          ToolResultContentPart(
            ToolResultContent(
              toolCallId: event.toolCallId,
              toolName: toolCall.toolCall.toolName,
              toolOutput: ExecutionDeniedToolOutput(event.reason),
              isDynamic: toolCall.toolCall.isDynamic,
            ),
            providerMetadata: event.providerMetadata,
          ),
        );
      case SourceEvent():
        _appendPart(SourceContentPart(event.source));
        _mergeProviderMetadata(event.source.providerMetadata);
      case FileEvent():
        _mergeProviderMetadata(event.providerMetadata);
        _appendPart(
          FileContentPart(
            event.file,
            providerMetadata: event.providerMetadata,
          ),
        );
      case StepStartEvent() ||
            StepFinishEvent() ||
            AbortEvent() ||
            RawChunkEvent():
        break;
      case FinishEvent():
        _finishReason = event.finishReason;
        _rawFinishReason = event.rawFinishReason;
        _usage = event.usage ?? _usage;
        _mergeProviderMetadata(event.providerMetadata);
      case CustomEvent():
        _mergeProviderMetadata(event.providerMetadata);
        _appendPart(
          CustomContentPart(
            kind: event.kind,
            data: event.data,
            providerMetadata: event.providerMetadata,
          ),
        );
      case ErrorEvent():
        _error = event.error;
    }
  }

  GenerateTextResult build() {
    if (_error case final error?) {
      throw error;
    }

    if (_finishReason == null) {
      throw StateError(
        'Cannot build GenerateTextResult before a finish event is received.',
      );
    }

    return GenerateTextResult(
      content: _content,
      finishReason: _finishReason!,
      rawFinishReason: _rawFinishReason,
      responseId: _responseId,
      responseTimestamp: _responseTimestamp,
      responseModelId: _responseModelId,
      usage: _usage,
      providerMetadata: _providerMetadata,
      warnings: _warnings,
    );
  }
}

Future<GenerateTextResult> collectGenerateTextResult(
  Stream<TextStreamEvent> events,
) async {
  final accumulator = GenerateTextResultAccumulator();
  await for (final event in events) {
    accumulator.apply(event);
  }
  return accumulator.build();
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

final class _PartialToolCall {
  final String toolName;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;
  final StringBuffer _buffer;
  ProviderMetadata? providerMetadata;

  _PartialToolCall({
    required this.toolName,
    required this.providerExecuted,
    required this.isDynamic,
    required this.title,
    required this.providerMetadata,
    String initialText = '',
  }) : _buffer = StringBuffer(initialText);

  String get text => _buffer.toString();

  void append(String value) {
    _buffer.write(value);
  }
}

extension on GenerateTextResultAccumulator {
  int _appendPart(ContentPart part) {
    _content.add(part);
    return _content.length - 1;
  }

  void _mergeProviderMetadata(ProviderMetadata? value) {
    _providerMetadata = ProviderMetadata.mergeNullable(
      _providerMetadata,
      value,
    );
  }

  void _setIfNotNull<T>(T? value, void Function(T value) assign) {
    if (value != null) {
      assign(value);
    }
  }

  _PartialToolCall _requirePartialToolCall(String toolCallId) {
    final value = _partialToolCalls[toolCallId];
    if (value != null) {
      return value;
    }

    throw StateError(
      'Received tool-input update for missing tool call with ID "$toolCallId". '
      'Ensure a "tool-input-start" event is applied before later tool-input events.',
    );
  }

  ToolCallContentPart? _toolCallPart(String toolCallId) {
    final index = _toolCallPartIndexes[toolCallId];
    if (index == null) {
      return null;
    }

    return _content[index] as ToolCallContentPart;
  }

  ToolCallContentPart _requireToolCallPart(String toolCallId) {
    final value = _toolCallPart(toolCallId);
    if (value != null) {
      return value;
    }

    throw StateError(
      'Received tool-output-denied for missing tool call with ID "$toolCallId". '
      'Ensure a tool-call or completed tool-input event is applied first.',
    );
  }

  void _upsertToolCallPart(ToolCallContentPart part) {
    final index = _toolCallPartIndexes[part.toolCall.toolCallId];
    if (index == null) {
      _toolCallPartIndexes[part.toolCall.toolCallId] = _appendPart(part);
      return;
    }

    _content[index] = part;
  }
}
