import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_request_encoding_util.dart';

final class OpenAIChatCompletionsAssistantPromptProjection {
  const OpenAIChatCompletionsAssistantPromptProjection();

  List<Map<String, Object?>> encode(
    AssistantPromptMessage message,
    List<ModelWarning> warnings,
  ) {
    final textParts = <String>[];
    final encodedToolCalls = <Map<String, Object?>>[];

    for (final part in message.parts) {
      switch (part) {
        case TextPromptPart(:final text):
          textParts.add(text);
        case ToolCallPromptPart(
            :final toolCallId,
            :final toolName,
            :final input,
            :final providerExecuted,
            :final isDynamic,
          ):
          if (providerExecuted || isDynamic) {
            warnings.add(
              const ModelWarning(
                type: ModelWarningType.unsupported,
                field: 'prompt.assistant.parts',
                message:
                    'Chat-completions replay drops provider-executed or dynamic assistant tool calls.',
              ),
            );
            continue;
          }

          encodedToolCalls.add({
            'id': toolCallId,
            'type': 'function',
            'function': {
              'name': toolName,
              'arguments': encodeOpenAIJsonString(input),
            },
          });
        case ReasoningPromptPart():
        case ReasoningFilePromptPart():
        case CustomPromptPart():
        case ToolApprovalRequestPromptPart():
        case ToolApprovalResponsePromptPart():
        case ImagePromptPart():
        case FilePromptPart():
        case ToolResultPromptPart():
          warnings.add(
            ModelWarning(
              type: ModelWarningType.unsupported,
              field: 'prompt.assistant.parts',
              message:
                  'Chat-completions replay dropped unsupported assistant part: ${part.runtimeType}.',
            ),
          );
      }
    }

    if (textParts.isEmpty && encodedToolCalls.isEmpty) {
      return const [];
    }

    final encodedText = textParts.join();
    return [
      {
        'role': 'assistant',
        'content': encodedText,
        if (encodedToolCalls.isNotEmpty) 'tool_calls': encodedToolCalls,
      },
    ];
  }
}
