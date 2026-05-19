import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_assistant_prompt_projection.dart';
import 'openai_chat_completions_request_tool_codec.dart';
import 'openai_chat_completions_user_prompt_encoder.dart';
import 'openai_options.dart';

final class OpenAIChatCompletionsPromptCodec {
  final String providerNamespace;
  final OpenAIChatCompletionsRequestToolCodec toolCodec;

  const OpenAIChatCompletionsPromptCodec({
    this.providerNamespace = 'openai',
    this.toolCodec = const OpenAIChatCompletionsRequestToolCodec(),
  });

  List<Map<String, Object?>> encodePromptMessage(
    PromptMessage message,
    List<ModelWarning> warnings, {
    required OpenAISystemMessageMode systemMessageMode,
  }) {
    if (message is SystemPromptMessage) {
      if (systemMessageMode == OpenAISystemMessageMode.remove) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.other,
            field: 'prompt.system',
            message: 'system messages are removed for this model',
          ),
        );
        return const [];
      }

      return [
        {
          'role': systemMessageMode.value,
          'content': joinOpenAIChatCompletionsTextParts(
            role: 'system',
            parts: message.parts,
          ),
        },
      ];
    }

    if (message is UserPromptMessage) {
      return [
        OpenAIChatCompletionsUserPromptEncoder(
          providerNamespace: providerNamespace,
        ).encode(message),
      ];
    }

    if (message is AssistantPromptMessage) {
      return const OpenAIChatCompletionsAssistantPromptProjection().encode(
        message,
        warnings,
      );
    }

    if (message is ToolPromptMessage) {
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
              ModelWarning(
                type: ModelWarningType.unsupported,
                field: 'prompt.tool.parts',
                message:
                    'Chat-completions replay dropped unsupported tool prompt part: ${part.runtimeType}.',
              ),
            );
        }
      }

      return encoded;
    }

    throw UnsupportedError(
      'Unsupported prompt message type: ${message.runtimeType}.',
    );
  }
}
