import 'package:llm_dart_core/llm_dart_core.dart';

import 'anthropic_mcp_models.dart';
import 'anthropic_tools.dart';

final class AnthropicChatModelSettings implements ProviderModelOptions {
  final String anthropicVersion;
  final Map<String, String> headers;
  final List<String> betaFeatures;
  final List<AnthropicNativeTool> tools;

  const AnthropicChatModelSettings({
    this.anthropicVersion = '2023-06-01',
    this.headers = const {},
    this.betaFeatures = const [],
    this.tools = const [],
  });
}

final class AnthropicGenerateTextOptions implements ProviderInvocationOptions {
  final bool? extendedThinking;
  final int? thinkingBudgetTokens;
  final bool? interleavedThinking;
  final String? serviceTier;
  final Map<String, Object?>? metadata;
  final String? container;
  final List<AnthropicMcpServer>? mcpServers;
  final List<AnthropicNativeTool>? tools;

  const AnthropicGenerateTextOptions({
    this.extendedThinking,
    this.thinkingBudgetTokens,
    this.interleavedThinking,
    this.serviceTier,
    this.metadata,
    this.container,
    this.mcpServers,
    this.tools,
  });
}
