import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_generate_text_options.dart';
import 'anthropic_messages_codec.dart';
import 'anthropic_model_settings.dart';
import 'anthropic_token_count.dart';

AnthropicGenerateTextOptions resolveAnthropicLanguageModelProviderOptions(
  ProviderInvocationOptions? options,
) {
  return resolveProviderInvocationOptions<AnthropicGenerateTextOptions>(
        options,
        parameterName: 'providerOptions',
        expectedTypeName: 'AnthropicGenerateTextOptions',
        usageContext: 'Anthropic language models',
      ) ??
      const AnthropicGenerateTextOptions();
}

AnthropicMessagesRequest encodeAnthropicLanguageModelMessagesRequest({
  required String modelId,
  required GenerateTextRequest request,
  required AnthropicChatModelSettings settings,
  required bool stream,
  AnthropicMessagesCodec messagesCodec = const AnthropicMessagesCodec(),
}) {
  return messagesCodec.encodeRequest(
    modelId: modelId,
    prompt: request.prompt,
    tools: request.tools,
    toolChoice: request.toolChoice,
    options: request.options,
    settings: settings,
    providerOptions: resolveAnthropicLanguageModelProviderOptions(
      request.callOptions.providerOptions,
    ),
    stream: stream,
  );
}

AnthropicMessagesRequest encodeAnthropicLanguageModelTokenCountRequest({
  required String modelId,
  required AnthropicTokenCountRequest request,
  required AnthropicChatModelSettings settings,
  AnthropicMessagesCodec messagesCodec = const AnthropicMessagesCodec(),
}) {
  return messagesCodec.encodeTokenCountRequest(
    modelId: modelId,
    prompt: request.prompt,
    tools: request.tools,
    toolChoice: request.toolChoice,
    settings: settings,
    providerOptions: resolveAnthropicLanguageModelProviderOptions(
      request.callOptions.providerOptions,
    ),
  );
}
