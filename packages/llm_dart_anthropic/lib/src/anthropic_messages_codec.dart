import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_code_execution_replay.dart';
import 'anthropic_options.dart';
import 'anthropic_tool_configuration.dart';

part 'anthropic_content_encoder.dart';
part 'anthropic_prompt_blocks.dart';
part 'anthropic_request_options_encoder.dart';
part 'anthropic_tool_replay_encoder.dart';

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
    final encodedPrompt = _encodeAnthropicPrompt(
      prompt,
      warnings: warnings,
    );

    return _buildAnthropicMessagesRequest(
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
  }

  AnthropicMessagesRequest encodeTokenCountRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required AnthropicChatModelSettings settings,
    required AnthropicGenerateTextOptions providerOptions,
  }) {
    return _buildAnthropicTokenCountRequest(
      codec: this,
      modelId: modelId,
      prompt: prompt,
      tools: tools,
      toolChoice: toolChoice,
      settings: settings,
      providerOptions: providerOptions,
    );
  }
}
