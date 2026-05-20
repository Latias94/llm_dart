import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_prompt_limitations.dart';
import 'openai_chat_completions_request_tool_codec.dart';

final class OpenAIChatCompletionsToolPromptProjection {
  final OpenAIChatCompletionsRequestToolCodec toolCodec;

  const OpenAIChatCompletionsToolPromptProjection({
    this.toolCodec = const OpenAIChatCompletionsRequestToolCodec(),
  });

  List<Map<String, Object?>> encode(
    ToolPromptMessage message,
    List<ModelWarning> warnings,
  ) {
    final encoded = <Map<String, Object?>>[];

    for (final part in message.parts) {
      switch (part) {
        case ToolResultPromptPart(
            :final toolCallId,
            :final toolName,
            :final toolOutput,
          ):
          if (toolName.startsWith('mcp.')) {
            warnings.add(
              const ModelWarning(
                type: ModelWarningType.unsupported,
                field: 'prompt.tool.parts',
                message:
                    'Chat-completions replay drops provider-native MCP tool results.',
              ),
            );
            continue;
          }

          encoded.add({
            'role': 'tool',
            'tool_call_id': toolCallId,
            'content': toolCodec.encodeToolOutput(toolOutput),
          });
        case ToolApprovalResponsePromptPart():
          warnings.add(
            const ModelWarning(
              type: ModelWarningType.unsupported,
              field: 'prompt.tool.parts',
              message:
                  'Chat-completions replay does not support tool approval responses.',
            ),
          );
        case TextPromptPart():
        case ReasoningPromptPart():
        case ReasoningFilePromptPart():
        case CustomPromptPart():
        case ToolCallPromptPart():
        case ToolApprovalRequestPromptPart():
        case ImagePromptPart():
        case FilePromptPart():
          warnings.add(
            unsupportedOpenAIChatCompletionsToolPartWarning(part),
          );
      }
    }

    return encoded;
  }
}
