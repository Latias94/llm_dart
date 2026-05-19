import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_assistant_prompt_projection.dart';
import 'openai_chat_completions_request_tool_codec.dart';
import 'openai_chat_completions_tool_prompt_projection.dart';
import 'openai_chat_completions_user_prompt_encoder.dart';
import 'openai_generate_text_options.dart';

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
      return OpenAIChatCompletionsToolPromptProjection(
        toolCodec: toolCodec,
      ).encode(
        message,
        warnings,
      );
    }

    throw UnsupportedError(
      'Unsupported prompt message type: ${message.runtimeType}.',
    );
  }
}
