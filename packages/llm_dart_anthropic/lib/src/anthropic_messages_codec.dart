import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_generate_text_options.dart';
import 'anthropic_model_settings.dart';
import 'anthropic_prompt_blocks.dart';
import 'anthropic_request_options_encoder.dart';

final class AnthropicMessagesRequest {
  final Map<String, Object?> body;
  final List<String> betaFeatures;
  final List<ModelWarning> warnings;

  AnthropicMessagesRequest({
    required Map<String, Object?> body,
    List<String> betaFeatures = const [],
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        betaFeatures = List.unmodifiable(betaFeatures),
        warnings = List.unmodifiable(warnings);
}

final class AnthropicMessagesCodec {
  static const AnthropicPromptBlockEncoder _promptEncoder =
      AnthropicPromptBlockEncoder();
  static const AnthropicRequestOptionsEncoder _requestOptionsEncoder =
      AnthropicRequestOptionsEncoder();

  const AnthropicMessagesCodec();

  AnthropicMessagesRequest encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required AnthropicChatModelSettings settings,
    required AnthropicGenerateTextOptions providerOptions,
    required bool stream,
  }) {
    final warnings = <ModelWarning>[];
    final encodedPrompt = _promptEncoder.encode(
      prompt,
      warnings: warnings,
    );

    final encodedRequest = _requestOptionsEncoder.buildMessagesRequest(
      modelId: modelId,
      prompt: encodedPrompt,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      settings: settings,
      providerOptions: providerOptions,
      stream: stream,
      warnings: warnings,
    );

    return AnthropicMessagesRequest(
      body: encodedRequest.body,
      betaFeatures: encodedRequest.betaFeatures,
      warnings: encodedRequest.warnings,
    );
  }

  AnthropicMessagesRequest encodeTokenCountRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required AnthropicChatModelSettings settings,
    required AnthropicGenerateTextOptions providerOptions,
  }) {
    final baseRequest = encodeRequest(
      modelId: modelId,
      prompt: prompt,
      tools: tools,
      toolChoice: toolChoice,
      options: const GenerateTextOptions(),
      settings: settings,
      providerOptions: providerOptions,
      stream: false,
    );
    final encodedRequest = _requestOptionsEncoder.buildTokenCountRequest(
      baseBody: baseRequest.body,
      baseBetaFeatures: baseRequest.betaFeatures,
      baseWarnings: baseRequest.warnings,
      providerOptions: providerOptions,
    );

    return AnthropicMessagesRequest(
      body: encodedRequest.body,
      betaFeatures: encodedRequest.betaFeatures,
      warnings: encodedRequest.warnings,
    );
  }
}
