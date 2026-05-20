import '../language/openai_generate_text_options.dart';
import '../provider/openai_model_capabilities.dart';

final class OpenAIResponsesRequestContext {
  final OpenAIModelCapabilities capabilities;
  final bool isReasoningModel;
  final bool store;
  final bool hasConversation;
  final OpenAISystemMessageMode systemMessageMode;

  const OpenAIResponsesRequestContext({
    required this.capabilities,
    required this.isReasoningModel,
    required this.store,
    required this.hasConversation,
    required this.systemMessageMode,
  });
}

OpenAIResponsesRequestContext resolveOpenAIResponsesRequestContext({
  required String modelId,
  required OpenAIGenerateTextOptions providerOptions,
}) {
  final capabilities = getOpenAIModelCapabilities(modelId);
  final isReasoningModel =
      providerOptions.forceReasoning ?? capabilities.isReasoningModel;

  return OpenAIResponsesRequestContext(
    capabilities: capabilities,
    isReasoningModel: isReasoningModel,
    store: providerOptions.store ?? true,
    hasConversation: providerOptions.conversation != null,
    systemMessageMode: providerOptions.systemMessageMode ??
        (isReasoningModel
            ? OpenAISystemMessageMode.developer
            : capabilities.systemMessageMode),
  );
}
