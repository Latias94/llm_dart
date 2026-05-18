import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart'
    hide
        ToolApprovalRequestEvent,
        ToolCallEvent,
        ToolInputDeltaEvent,
        ToolInputEndEvent,
        ToolInputErrorEvent,
        ToolInputStartEvent,
        ToolResultEvent;

import '../stream/text_stream_event.dart';
import 'chat_ui_message.dart';
import 'chat_ui_stream_error.dart';

final class ChatUiToolPartStore {
  final List<ChatUiPart> _parts;
  final Map<String, int> _partIndexes = {};
  final Map<String, _PartialToolInput> _partialInputs = {};

  ChatUiToolPartStore(this._parts);

  void hydrate(ToolUiPart part, int index) {
    _partIndexes[part.toolCallId] = index;
    if (part.state != ToolUiPartState.inputStreaming) {
      return;
    }

    _partialInputs[part.toolCallId] = _PartialToolInput(
      toolName: part.toolName,
      providerExecuted: part.providerExecuted,
      isDynamic: part.isDynamic,
      title: part.title,
      initialText: part.inputText ?? _stringifyValue(part.input) ?? '',
    );
  }

  void clearStreamingInputs() {
    _partialInputs.clear();
  }

  void applyInputStart(ToolInputStartEvent event) {
    _partialInputs[event.toolCallId] = _PartialToolInput(
      toolName: event.toolName,
      providerExecuted: event.providerExecuted,
      isDynamic: event.isDynamic,
      title: event.title,
    );
    _upsert(
      _buildPart(
        toolCallId: event.toolCallId,
        toolName: event.toolName,
        state: ToolUiPartState.inputStreaming,
        setInput: true,
        input: null,
        setInputText: true,
        inputText: null,
        setOutput: true,
        output: null,
        setToolOutput: true,
        toolOutput: null,
        setErrorText: true,
        errorText: null,
        providerExecuted: event.providerExecuted,
        isDynamic: event.isDynamic,
        setTitle: true,
        title: event.title,
        callProviderMetadata: event.providerMetadata,
      ),
    );
  }

  void applyInputDelta(ToolInputDeltaEvent event) {
    final partial = _requirePartialInput(event.toolCallId);
    partial.append(event.delta);
    _upsert(
      _buildPart(
        toolCallId: event.toolCallId,
        state: ToolUiPartState.inputStreaming,
        setInput: true,
        input: _decodeToolInputValue(partial.text),
        setInputText: true,
        inputText: partial.text,
        callProviderMetadata: event.providerMetadata,
      ),
    );
  }

  void applyInputEnd(ToolInputEndEvent event) {
    final partial = _requirePartialInput(event.toolCallId);
    _upsert(
      _buildPart(
        toolCallId: event.toolCallId,
        state: ToolUiPartState.inputAvailable,
        setInput: true,
        input: _decodeToolInputValue(partial.text),
        setInputText: true,
        inputText: partial.text,
        callProviderMetadata: event.providerMetadata,
      ),
    );
    _partialInputs.remove(event.toolCallId);
  }

  void applyInputError(ToolInputErrorEvent event) {
    final partial = _partialInputs.remove(event.toolCallId);
    final input = event.input ??
        (partial == null ? null : _decodeToolInputValue(partial.text));
    final inputText = partial?.text ?? _stringifyValue(input);
    _upsert(
      _buildPart(
        toolCallId: event.toolCallId,
        toolName: event.toolName,
        state: ToolUiPartState.outputError,
        setInput: true,
        input: input,
        setInputText: true,
        inputText: inputText,
        setOutput: true,
        output: null,
        setToolOutput: true,
        toolOutput: null,
        setErrorText: true,
        errorText: event.errorText,
        providerExecuted: event.providerExecuted,
        isDynamic: event.isDynamic,
        setTitle: event.title != null,
        title: event.title,
        callProviderMetadata: event.providerMetadata,
      ),
    );
  }

  void applyCall(ToolCallEvent event) {
    _partialInputs.remove(event.toolCall.toolCallId);
    _upsert(
      _buildPart(
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
  }

  void applyApprovalRequest(ToolApprovalRequestEvent event) {
    _requirePart(
      event.toolCallId,
      chunkType: 'tool-approval-request',
      message:
          'Received tool-approval-request for missing tool call with ID "${event.toolCallId}". '
          'Ensure a tool-input-start or tool-call event is applied first.',
    );
    _upsert(
      _buildPart(
        toolCallId: event.toolCallId,
        state: ToolUiPartState.approvalRequested,
        setApproval: true,
        approval: ToolApprovalUiState(
          approvalId: event.approvalId,
        ),
        callProviderMetadata: event.providerMetadata,
      ),
    );
  }

  void applyResult(ToolResultEvent event) {
    _partialInputs.remove(event.toolResult.toolCallId);
    _requirePart(
      event.toolResult.toolCallId,
      chunkType: 'tool-result',
      message:
          'Received tool-result for missing tool call with ID "${event.toolResult.toolCallId}". '
          'Ensure a tool-input-start or tool-call event is applied first.',
    );
    _upsert(
      _buildPart(
        toolCallId: event.toolResult.toolCallId,
        toolName: event.toolResult.toolName,
        state: event.toolResult.toolOutput.denied
            ? ToolUiPartState.outputDenied
            : event.toolResult.isError
                ? ToolUiPartState.outputError
                : ToolUiPartState.outputAvailable,
        setOutput: true,
        output: event.toolResult.output,
        setToolOutput: true,
        toolOutput: event.toolResult.toolOutput,
        setErrorText: true,
        errorText: event.toolResult.isError
            ? _stringifyValue(event.toolResult.output)
            : null,
        preliminary: event.toolResult.preliminary,
        isDynamic: event.toolResult.isDynamic,
        resultProviderMetadata: event.providerMetadata,
      ),
    );
  }

  void applyOutputDenied(ToolOutputDeniedEvent event) {
    _requirePart(
      event.toolCallId,
      chunkType: 'tool-output-denied',
      message:
          'Received tool-output-denied for missing tool call with ID "${event.toolCallId}". '
          'Ensure a tool-input-start or tool-call event is applied first.',
    );
    _upsert(
      _buildPart(
        toolCallId: event.toolCallId,
        state: ToolUiPartState.outputDenied,
        setOutput: true,
        output: null,
        setToolOutput: true,
        toolOutput: ExecutionDeniedToolOutput(event.reason),
        resultProviderMetadata: event.providerMetadata,
      ),
    );
  }

  ToolUiPart? _part(String toolCallId) {
    final index = _partIndexes[toolCallId];
    if (index == null) {
      return null;
    }

    return _parts[index] as ToolUiPart;
  }

  ToolUiPart _requirePart(
    String toolCallId, {
    required String chunkType,
    required String message,
  }) {
    final part = _part(toolCallId);
    if (part != null) {
      return part;
    }

    throw ChatUiStreamError(
      chunkType: chunkType,
      chunkId: toolCallId,
      message: message,
    );
  }

  void _upsert(ToolUiPart part) {
    final index = _partIndexes[part.toolCallId];
    if (index == null) {
      _partIndexes[part.toolCallId] = _append(part);
      return;
    }

    _parts[index] = part;
  }

  int _append(ToolUiPart part) {
    _parts.add(part);
    return _parts.length - 1;
  }

  ToolUiPart _buildPart({
    required String toolCallId,
    String? toolName,
    ToolUiPartState? state,
    Object? input,
    bool setInput = false,
    String? inputText,
    bool setInputText = false,
    Object? output,
    bool setOutput = false,
    ToolOutput? toolOutput,
    bool setToolOutput = false,
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
    final current = _part(toolCallId);
    final partial = _partialInputs[toolCallId];
    final resolvedToolName = toolName ?? current?.toolName ?? partial?.toolName;

    if (resolvedToolName == null) {
      throw ChatUiStreamError(
        chunkType: 'tool-update',
        chunkId: toolCallId,
        message:
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
      toolOutput: setToolOutput ? toolOutput : current?.toolOutput,
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
      callProviderMetadata: ProviderMetadata.mergeNullable(
        current?.callProviderMetadata,
        callProviderMetadata,
      ),
      resultProviderMetadata: ProviderMetadata.mergeNullable(
        current?.resultProviderMetadata,
        resultProviderMetadata,
      ),
    );
  }

  _PartialToolInput _requirePartialInput(String toolCallId) {
    final value = _partialInputs[toolCallId];
    if (value != null) {
      return value;
    }

    throw ChatUiStreamError(
      chunkType: 'tool-input-update',
      chunkId: toolCallId,
      message:
          'Received tool-input update for missing tool call with ID "$toolCallId". '
          'Ensure a "tool-input-start" event is applied before later tool-input events.',
    );
  }
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
