import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_beta_feature_inference.dart';
import 'anthropic_generate_text_options.dart';
import 'anthropic_model_settings.dart';
import 'anthropic_prompt_blocks.dart';
import 'anthropic_request_json.dart';
import 'anthropic_thinking_policy.dart';
import 'anthropic_token_count_request_projection.dart';
import 'anthropic_tool_configuration.dart';

final class AnthropicEncodedMessagesRequest {
  final Map<String, Object?> body;
  final List<String> betaFeatures;
  final List<ModelWarning> warnings;

  AnthropicEncodedMessagesRequest({
    required Map<String, Object?> body,
    List<String> betaFeatures = const [],
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        betaFeatures = List.unmodifiable(betaFeatures),
        warnings = List.unmodifiable(warnings);
}

final class AnthropicRequestOptionsEncoder {
  static const AnthropicThinkingPolicy _thinkingPolicy =
      AnthropicThinkingPolicy();
  static const AnthropicBetaFeatureInference _betaFeatureInference =
      AnthropicBetaFeatureInference();
  static const AnthropicTokenCountRequestProjector _tokenCountProjector =
      AnthropicTokenCountRequestProjector();

  const AnthropicRequestOptionsEncoder();

  AnthropicEncodedMessagesRequest buildMessagesRequest({
    required String modelId,
    required AnthropicEncodedPrompt prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required AnthropicChatModelSettings settings,
    required AnthropicGenerateTextOptions providerOptions,
    required bool stream,
    required List<ModelWarning> warnings,
  }) {
    final betaFeatures = <String>{};
    final mcpServers = providerOptions.mcpServers;
    final nativeTools = providerOptions.tools ?? settings.tools;
    final deferredToolNames =
        providerOptions.deferredToolNames ?? settings.deferredToolNames;
    final thinkingSampling = _thinkingPolicy.project(
      options: options,
      providerOptions: providerOptions,
      warnings: warnings,
    );

    _betaFeatureInference.collectThinkingFeatures(
      providerOptions: providerOptions,
      extendedThinking: thinkingSampling.extendedThinking,
      betaFeatures: betaFeatures,
      warnings: warnings,
    );
    betaFeatures.addAll(prompt.betaFeatures);

    validateAnthropicThinkingCompatibleToolChoice(
      extendedThinking: thinkingSampling.extendedThinking,
      toolChoice: toolChoice,
    );

    final toolConfiguration = resolveAnthropicToolConfiguration(
      tools: tools,
      nativeTools: nativeTools,
      toolChoice: toolChoice,
      deferredToolNames: deferredToolNames,
      functionToolOptions: providerOptions.functionToolOptions,
      defaultEagerInputStreaming:
          stream && providerOptions.toolStreaming != false,
      toolsCacheControl: providerOptions.toolsCacheControl,
      warnings: warnings,
    );
    betaFeatures.addAll(toolConfiguration.betaFeatures);

    final body = <String, Object?>{
      'model': modelId,
      'messages': prompt.messages,
      'max_tokens': thinkingSampling.maxTokens,
      'stream': stream,
      if (prompt.system.isNotEmpty) 'system': prompt.system,
      if (!thinkingSampling.extendedThinking &&
          thinkingSampling.temperature != null)
        'temperature': thinkingSampling.temperature,
      if (options.stopSequences != null && options.stopSequences!.isNotEmpty)
        'stop_sequences': options.stopSequences,
      if (thinkingSampling.topP != null) 'top_p': thinkingSampling.topP,
      if (thinkingSampling.topK != null) 'top_k': thinkingSampling.topK,
      if (thinkingSampling.thinking != null)
        'thinking': thinkingSampling.thinking,
      if (providerOptions.serviceTier != null)
        'service_tier': providerOptions.serviceTier,
      if (providerOptions.metadata != null &&
          providerOptions.metadata!.isNotEmpty)
        'metadata': normalizeAnthropicJsonObject(
          providerOptions.metadata!,
          path: 'metadata',
        ),
      if (providerOptions.container != null)
        'container': providerOptions.container,
      if (mcpServers != null && mcpServers.isNotEmpty)
        'mcp_servers': mcpServers.map((server) => server.toJson()).toList(),
      if (toolConfiguration.tools != null) 'tools': toolConfiguration.tools,
      if (toolConfiguration.toolChoice != null)
        'tool_choice': toolConfiguration.toolChoice,
    };

    _betaFeatureInference.collectProviderOptionFeatures(
      providerOptions: providerOptions,
      betaFeatures: betaFeatures,
    );

    return AnthropicEncodedMessagesRequest(
      body: body,
      betaFeatures: _betaFeatureInference.sorted(betaFeatures),
      warnings: warnings,
    );
  }

  AnthropicEncodedMessagesRequest buildTokenCountRequest({
    required Map<String, Object?> baseBody,
    required List<String> baseBetaFeatures,
    required List<ModelWarning> baseWarnings,
    required AnthropicGenerateTextOptions providerOptions,
  }) {
    final projection = _tokenCountProjector.project(
      baseBody: baseBody,
      baseBetaFeatures: baseBetaFeatures,
      baseWarnings: baseWarnings,
      providerOptions: providerOptions,
    );

    return AnthropicEncodedMessagesRequest(
      body: projection.body,
      betaFeatures: projection.betaFeatures,
      warnings: projection.warnings,
    );
  }
}
