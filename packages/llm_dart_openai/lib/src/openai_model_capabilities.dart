import 'openai_options.dart';

final class OpenAIModelCapabilities {
  final bool isReasoningModel;
  final OpenAISystemMessageMode systemMessageMode;
  final bool supportsFlexProcessing;
  final bool supportsPriorityProcessing;
  final bool supportsNonReasoningParameters;

  const OpenAIModelCapabilities({
    required this.isReasoningModel,
    required this.systemMessageMode,
    required this.supportsFlexProcessing,
    required this.supportsPriorityProcessing,
    required this.supportsNonReasoningParameters,
  });
}

OpenAIModelCapabilities getOpenAIModelCapabilities(String modelId) {
  final supportsFlexProcessing = modelId.startsWith('o3') ||
      modelId.startsWith('o4-mini') ||
      (modelId.startsWith('gpt-5') && !isOpenAIChatOptimizedModel(modelId));

  final supportsPriorityProcessing = modelId.startsWith('gpt-4') ||
      (modelId.startsWith('gpt-5') &&
          !isOpenAIChatOptimizedModel(modelId) &&
          !modelId.startsWith('gpt-5-nano') &&
          !modelId.startsWith('gpt-5.4-nano')) ||
      modelId.startsWith('o3') ||
      modelId.startsWith('o4-mini');

  final isReasoningModel = modelId.startsWith('o1') ||
      modelId.startsWith('o3') ||
      modelId.startsWith('o4-mini') ||
      (modelId.startsWith('gpt-5') && !isOpenAIChatOptimizedModel(modelId));

  final supportsNonReasoningParameters = modelId.startsWith('gpt-5.1') ||
      modelId.startsWith('gpt-5.2') ||
      modelId.startsWith('gpt-5.3') ||
      modelId.startsWith('gpt-5.4') ||
      modelId.startsWith('gpt-5.5');

  return OpenAIModelCapabilities(
    isReasoningModel: isReasoningModel,
    systemMessageMode: isReasoningModel
        ? OpenAISystemMessageMode.developer
        : OpenAISystemMessageMode.system,
    supportsFlexProcessing: supportsFlexProcessing,
    supportsPriorityProcessing: supportsPriorityProcessing,
    supportsNonReasoningParameters: supportsNonReasoningParameters,
  );
}

bool isOpenAIChatOptimizedModel(String modelId) {
  return modelId.startsWith('gpt-5-chat');
}
