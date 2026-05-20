import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_tool_output_support.dart';

final class ChatPromptToolPartProjector {
  final List<ChatUiPart> parts;
  final String fallbackToolName;

  const ChatPromptToolPartProjector({
    required this.parts,
    required this.fallbackToolName,
  });

  void applyToolCall(ToolCallPromptPart part) {
    upsertToolPart(
      part.toolCallId,
      (current) => ToolUiPart(
        toolCallId: part.toolCallId,
        toolName: part.toolName,
        state: current?.approval != null
            ? ToolUiPartState.approvalRequested
            : ToolUiPartState.inputAvailable,
        input: part.input,
        inputText: current?.inputText,
        output: current?.output,
        toolOutput: current?.toolOutput,
        errorText: current?.errorText,
        providerExecuted:
            part.providerExecuted || current?.providerExecuted == true,
        isDynamic: part.isDynamic || current?.isDynamic == true,
        preliminary: current?.preliminary ?? false,
        title: part.title ?? current?.title,
        approval: current?.approval,
        callProviderMetadata: ProviderMetadata.mergeNullable(
          current?.callProviderMetadata,
          providerReplayMetadataFromOptions(part.providerOptions),
        ),
        resultProviderMetadata: current?.resultProviderMetadata,
      ),
    );
  }

  void applyApprovalRequest(ToolApprovalRequestPromptPart part) {
    upsertToolPart(
      part.toolCallId,
      (current) => ToolUiPart(
        toolCallId: part.toolCallId,
        toolName: current?.toolName ?? fallbackToolName,
        state: ToolUiPartState.approvalRequested,
        input: current?.input,
        inputText: current?.inputText,
        output: current?.output,
        toolOutput: current?.toolOutput,
        errorText: current?.errorText,
        providerExecuted: current?.providerExecuted ?? false,
        isDynamic: current?.isDynamic ?? false,
        preliminary: current?.preliminary ?? false,
        title: current?.title,
        approval: ToolApprovalUiState(
          approvalId: part.approvalId,
        ),
        callProviderMetadata: ProviderMetadata.mergeNullable(
          current?.callProviderMetadata,
          providerReplayMetadataFromOptions(part.providerOptions),
        ),
        resultProviderMetadata: current?.resultProviderMetadata,
      ),
    );
  }

  void applyToolResult(ToolResultPromptPart part) {
    upsertToolPart(
      part.toolCallId,
      (current) => ToolUiPart(
        toolCallId: part.toolCallId,
        toolName: part.toolName,
        state: chatToolOutputState(part.toolOutput),
        input: current?.input,
        inputText: current?.inputText,
        output: part.output,
        toolOutput: part.toolOutput,
        errorText:
            part.isError ? chatStringifyToolOutputValue(part.toolOutput) : null,
        providerExecuted: current?.providerExecuted ?? false,
        isDynamic: current?.isDynamic ?? false,
        preliminary: false,
        title: current?.title,
        approval: current?.approval,
        callProviderMetadata: current?.callProviderMetadata,
        resultProviderMetadata: ProviderMetadata.mergeNullable(
          current?.resultProviderMetadata,
          providerReplayMetadataFromOptions(part.providerOptions),
        ),
      ),
    );
  }

  void applyApprovalResponse(ToolApprovalResponsePromptPart part) {
    upsertToolPart(
      part.toolCallId,
      (current) => ToolUiPart(
        toolCallId: part.toolCallId,
        toolName: current?.toolName ?? fallbackToolName,
        state: part.approved
            ? ToolUiPartState.approvalResponded
            : ToolUiPartState.outputDenied,
        input: current?.input,
        inputText: current?.inputText,
        output: current?.output,
        toolOutput: part.approved
            ? current?.toolOutput
            : ExecutionDeniedToolOutput(
                part.reason,
              ),
        errorText: current?.errorText,
        providerExecuted: current?.providerExecuted ?? false,
        isDynamic: current?.isDynamic ?? false,
        preliminary: current?.preliminary ?? false,
        title: current?.title,
        approval: ToolApprovalUiState(
          approvalId: part.approvalId,
          approved: part.approved,
          reason: part.reason,
        ),
        callProviderMetadata: ProviderMetadata.mergeNullable(
          current?.callProviderMetadata,
          providerReplayMetadataFromOptions(part.providerOptions),
        ),
        resultProviderMetadata: current?.resultProviderMetadata,
      ),
    );
  }

  void upsertToolPart(
    String toolCallId,
    ToolUiPart Function(ToolUiPart? current) build,
  ) {
    final index = parts.lastIndexWhere(
      (part) => part is ToolUiPart && part.toolCallId == toolCallId,
    );
    final current = index == -1 ? null : parts[index] as ToolUiPart;
    final next = build(current);

    if (index == -1) {
      parts.add(next);
    } else {
      parts[index] = next;
    }
  }
}
