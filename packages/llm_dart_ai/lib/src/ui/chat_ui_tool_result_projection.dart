import 'package:llm_dart_provider/llm_dart_provider.dart'
    hide ToolApprovalRequestEvent, ToolResultEvent;

import '../common/tool_input_stream_state.dart';
import '../stream/text_stream_event.dart';
import 'chat_ui_message.dart';
import 'chat_ui_tool_part_builder.dart';
import 'chat_ui_tool_part_index.dart';

final class ChatUiToolResultProjection {
  final ChatUiToolPartIndex _parts;

  ChatUiToolResultProjection(this._parts);

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
    Object? output,
    bool setOutput = false,
    ToolOutput? toolOutput,
    bool setToolOutput = false,
    String? errorText,
    bool setErrorText = false,
    bool? isDynamic,
    bool? preliminary,
    ToolApprovalUiState? approval,
    bool setApproval = false,
    ProviderMetadata? callProviderMetadata,
    ProviderMetadata? resultProviderMetadata,
  }) =>
      ChatUiToolPartBuilder(
        current: _parts.get(toolCallId),
        partial: null,
      ).build(
        toolCallId: toolCallId,
        toolName: toolName,
        state: state,
        output: output,
        setOutput: setOutput,
        toolOutput: toolOutput,
        setToolOutput: setToolOutput,
        errorText: errorText,
        setErrorText: setErrorText,
        isDynamic: isDynamic,
        preliminary: preliminary,
        approval: approval,
        setApproval: setApproval,
        callProviderMetadata: callProviderMetadata,
        resultProviderMetadata: resultProviderMetadata,
      );
}
