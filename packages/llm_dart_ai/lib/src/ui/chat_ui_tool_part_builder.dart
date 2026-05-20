import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../common/tool_input_stream_state.dart';
import 'chat_ui_message.dart';
import 'chat_ui_stream_error.dart';

final class ChatUiToolPartBuilder {
  final ToolUiPart? current;
  final StreamingToolInputState? partial;

  const ChatUiToolPartBuilder({
    required this.current,
    required this.partial,
  });

  ToolUiPart build({
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
}
