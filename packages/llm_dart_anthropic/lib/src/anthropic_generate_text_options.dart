import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_cache_options.dart';
import 'anthropic_function_tool_options.dart';
import 'anthropic_mcp_models.dart';
import 'anthropic_tools.dart';

final class AnthropicGenerateTextOptions implements ProviderInvocationOptions {
  final bool? extendedThinking;
  final int? thinkingBudgetTokens;
  final bool? interleavedThinking;
  final String? serviceTier;
  final Map<String, Object?>? metadata;
  final String? container;
  final List<AnthropicMcpServer>? mcpServers;
  final List<AnthropicNativeTool>? tools;
  final List<String>? deferredToolNames;
  final Map<String, AnthropicFunctionToolOptions>? functionToolOptions;
  final bool? toolStreaming;
  final AnthropicCacheControl? toolsCacheControl;

  const AnthropicGenerateTextOptions({
    this.extendedThinking,
    this.thinkingBudgetTokens,
    this.interleavedThinking,
    this.serviceTier,
    this.metadata,
    this.container,
    this.mcpServers,
    this.tools,
    this.deferredToolNames,
    this.functionToolOptions,
    this.toolStreaming,
    this.toolsCacheControl,
  });

  AnthropicGenerateTextOptions copyWith({
    bool? extendedThinking,
    int? thinkingBudgetTokens,
    bool? interleavedThinking,
    String? serviceTier,
    Map<String, Object?>? metadata,
    String? container,
    List<AnthropicMcpServer>? mcpServers,
    List<AnthropicNativeTool>? tools,
    List<String>? deferredToolNames,
    Map<String, AnthropicFunctionToolOptions>? functionToolOptions,
    bool? toolStreaming,
    AnthropicCacheControl? toolsCacheControl,
  }) {
    return AnthropicGenerateTextOptions(
      extendedThinking: extendedThinking ?? this.extendedThinking,
      thinkingBudgetTokens: thinkingBudgetTokens ?? this.thinkingBudgetTokens,
      interleavedThinking: interleavedThinking ?? this.interleavedThinking,
      serviceTier: serviceTier ?? this.serviceTier,
      metadata: metadata ?? this.metadata,
      container: container ?? this.container,
      mcpServers: mcpServers ?? this.mcpServers,
      tools: tools ?? this.tools,
      deferredToolNames: deferredToolNames ?? this.deferredToolNames,
      functionToolOptions: functionToolOptions ?? this.functionToolOptions,
      toolStreaming: toolStreaming ?? this.toolStreaming,
      toolsCacheControl: toolsCacheControl ?? this.toolsCacheControl,
    );
  }
}
