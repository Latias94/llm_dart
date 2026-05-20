import 'package:llm_dart_provider/llm_dart_provider.dart'
    hide
        ToolApprovalRequestEvent,
        ToolCallEvent,
        ToolInputDeltaEvent,
        ToolInputEndEvent,
        ToolInputErrorEvent,
        ToolInputStartEvent,
        ToolResultEvent;

import '../common/tool_input_stream_state.dart';
import '../stream/text_stream_event.dart';
import 'chat_ui_message.dart';
import 'chat_ui_tool_input_stream_store.dart';
import 'chat_ui_tool_part_index.dart';
import 'chat_ui_tool_part_builder.dart';

final class ChatUiToolPartStore {
  final ChatUiToolPartIndex _parts;
  final ChatUiToolInputStreamStore _inputStreams = ChatUiToolInputStreamStore();

  ChatUiToolPartStore(List<ChatUiPart> parts)
      : _parts = ChatUiToolPartIndex(parts);

  void hydrate(ToolUiPart part, int index) {
    _parts.hydrate(part, index);
    _inputStreams.hydrate(part);
  }

  void clearStreamingInputs() {
    _inputStreams.clear();
  }

  void applyInputStart(ToolInputStartEvent event) {
    _inputStreams.start(event);
    _parts.upsert(
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
    final partial = _inputStreams.appendDelta(event);
    _parts.upsert(
      _buildPart(
        toolCallId: event.toolCallId,
        state: ToolUiPartState.inputStreaming,
        setInput: true,
        input: partial.input,
        setInputText: true,
        inputText: partial.text,
        callProviderMetadata: event.providerMetadata,
      ),
    );
  }

  void applyInputEnd(ToolInputEndEvent event) {
    final partial = _inputStreams.end(event);
    _parts.upsert(
      _buildPart(
        toolCallId: event.toolCallId,
        state: ToolUiPartState.inputAvailable,
        setInput: true,
        input: partial.input,
        setInputText: true,
        inputText: partial.text,
        callProviderMetadata: event.providerMetadata,
      ),
    );
  }

  void applyInputError(ToolInputErrorEvent event) {
    final partial = _inputStreams.fail(event);
    final input = event.input ?? partial?.input;
    final inputText = partial?.text ?? stringifyStreamingToolValue(input);
    _parts.upsert(
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
    _inputStreams.remove(event.toolCall.toolCallId);
    _parts.upsert(
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
    _parts.require(
      event.toolCallId,
      chunkType: 'tool-approval-request',
      message:
          'Received tool-approval-request for missing tool call with ID "${event.toolCallId}". '
          'Ensure a tool-input-start or tool-call event is applied first.',
    );
    _parts.upsert(
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
    _inputStreams.remove(event.toolResult.toolCallId);
    _parts.require(
      event.toolResult.toolCallId,
      chunkType: 'tool-result',
      message:
          'Received tool-result for missing tool call with ID "${event.toolResult.toolCallId}". '
          'Ensure a tool-input-start or tool-call event is applied first.',
    );
    _parts.upsert(
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
            ? stringifyStreamingToolValue(event.toolResult.output)
            : null,
        preliminary: event.toolResult.preliminary,
        isDynamic: event.toolResult.isDynamic,
        resultProviderMetadata: event.providerMetadata,
      ),
    );
  }

  void applyOutputDenied(ToolOutputDeniedEvent event) {
    _parts.require(
      event.toolCallId,
      chunkType: 'tool-output-denied',
      message:
          'Received tool-output-denied for missing tool call with ID "${event.toolCallId}". '
          'Ensure a tool-input-start or tool-call event is applied first.',
    );
    _parts.upsert(
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
  }) =>
      ChatUiToolPartBuilder(
        current: _parts.get(toolCallId),
        partial: _inputStreams.get(toolCallId),
      ).build(
        toolCallId: toolCallId,
        toolName: toolName,
        state: state,
        input: input,
        setInput: setInput,
        inputText: inputText,
        setInputText: setInputText,
        output: output,
        setOutput: setOutput,
        toolOutput: toolOutput,
        setToolOutput: setToolOutput,
        errorText: errorText,
        setErrorText: setErrorText,
        providerExecuted: providerExecuted,
        isDynamic: isDynamic,
        preliminary: preliminary,
        title: title,
        setTitle: setTitle,
        approval: approval,
        setApproval: setApproval,
        callProviderMetadata: callProviderMetadata,
        resultProviderMetadata: resultProviderMetadata,
      );
}
