part of 'chat_ui_accumulator.dart';

extension _ChatUiAccumulatorToolSupport on ChatUiAccumulator {
  void _applyToolInputStartEvent(ToolInputStartEvent event) {
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
  }

  void _applyToolInputDeltaEvent(ToolInputDeltaEvent event) {
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
  }

  void _applyToolInputEndEvent(ToolInputEndEvent event) {
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
  }

  void _applyToolInputErrorEvent(ToolInputErrorEvent event) {
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
  }

  void _applyToolCallEvent(ToolCallEvent event) {
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
  }

  void _applyToolApprovalRequestEvent(ToolApprovalRequestEvent event) {
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
  }

  void _applyToolResultEvent(ToolResultEvent event) {
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
  }

  void _applyToolOutputDeniedEvent(ToolOutputDeniedEvent event) {
    _upsertToolPart(
      _buildToolPart(
        toolCallId: event.toolCallId,
        state: ToolUiPartState.outputDenied,
        resultProviderMetadata: event.providerMetadata,
      ),
    );
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
