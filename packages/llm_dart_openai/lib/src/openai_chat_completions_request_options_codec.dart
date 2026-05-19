import 'openai_generate_text_options.dart';
import 'openai_model_capabilities.dart';
import 'resolved_openai_options.dart';

final class OpenAIChatCompletionsRequestOptionsCodec {
  const OpenAIChatCompletionsRequestOptionsCodec();

  void validateUnsupportedProviderOptions(
    ResolvedOpenAIGenerateTextOptions providerOptions,
  ) {
    if (providerOptions.common.previousResponseId != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support previousResponseId. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.builtInTools case final builtInTools?
        when builtInTools.isNotEmpty) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support OpenAI built-in tools. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.instructions != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support instructions. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.maxToolCalls != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support maxToolCalls. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.metadata != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support metadata. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.truncation != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support truncation. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.include case final include?
        when include.isNotEmpty) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support include. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.promptCacheKey != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support promptCacheKey in the current family-safe mainline. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.promptCacheRetention != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support promptCacheRetention in the current family-safe mainline. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.safetyIdentifier != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support safetyIdentifier in the current family-safe mainline. Use the Responses API mainline instead.',
      );
    }
  }

  OpenAISystemMessageMode resolveSystemMessageMode(
    String modelId,
    OpenAIGenerateTextOptions options,
  ) {
    if (options.systemMessageMode case final mode?) {
      return mode;
    }

    final capabilities = getOpenAIModelCapabilities(modelId);
    final isReasoningModel =
        options.forceReasoning ?? capabilities.isReasoningModel;

    return isReasoningModel
        ? OpenAISystemMessageMode.developer
        : capabilities.systemMessageMode;
  }
}
