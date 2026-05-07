import 'package:llm_dart_transport/llm_dart_transport.dart'
    show DioClientOverrides, HasDioClientOverrides;

import '../../src/config/provider_defaults.dart';
import '../../core/web_search.dart';
import '../../models/chat_models.dart';
import '../../models/tool_models.dart';
import 'mcp_models.dart';

/// Anthropic provider configuration
///
/// This class contains all configuration options for the Anthropic providers.
/// It's extracted from the main provider to improve modularity and reusability.
///
/// **API Documentation:**
/// - Models Overview: https://docs.anthropic.com/en/docs/models-overview
/// - Extended Thinking: https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
/// - Vision: https://docs.anthropic.com/en/docs/build-with-claude/vision
/// - Tool Use: https://docs.anthropic.com/en/docs/tool-use
/// - PDF Support: https://docs.anthropic.com/en/docs/build-with-claude/pdf-support
class AnthropicConfig implements HasDioClientOverrides {
  final String apiKey;
  final String baseUrl;
  final String model;
  final int? maxTokens;
  final double? temperature;
  final String? systemPrompt;
  final Duration? timeout;
  @override
  final DioClientOverrides? dioOverrides;
  final bool stream;
  final double? topP;
  final int? topK;
  final List<Tool>? tools;
  final ToolChoice? toolChoice;
  final bool reasoning;
  final int? thinkingBudgetTokens;
  final bool interleavedThinking;
  final List<String>? stopSequences;
  final String? user;
  final ServiceTier? serviceTier;
  final Map<String, dynamic>? metadata;
  final String? container;
  final List<AnthropicMCPServer>? mcpServers;
  final WebSearchConfig? webSearchConfig;

  const AnthropicConfig({
    required this.apiKey,
    this.baseUrl = ProviderDefaults.anthropicBaseUrl,
    this.model = ProviderDefaults.anthropicDefaultModel,
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.dioOverrides,
    this.stream = false,
    this.topP,
    this.topK,
    this.tools,
    this.toolChoice,
    this.reasoning = false,
    this.thinkingBudgetTokens,
    this.interleavedThinking = false,
    this.stopSequences,
    this.user,
    this.serviceTier,
    this.metadata,
    this.container,
    this.mcpServers,
    this.webSearchConfig,
  });

  /// Check if this model supports reasoning/thinking
  ///
  /// **Reference:** https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
  ///
  /// Known reasoning models include:
  /// - Claude Opus 4 (claude-opus-4-20250514)
  /// - Claude Sonnet 4 (claude-sonnet-4-20250514)
  /// - Claude Sonnet 3.7 (claude-3-7-sonnet-20250219)
  bool get supportsReasoning {
    return model == 'claude-opus-4-20250514' ||
        model == 'claude-sonnet-4-20250514' ||
        model == 'claude-3-7-sonnet-20250219' ||
        model.contains('claude-3-7-sonnet') ||
        model.contains('claude-opus-4') ||
        model.contains('claude-sonnet-4');
  }

  /// Check if this model supports vision
  ///
  /// **Reference:** https://docs.anthropic.com/en/docs/build-with-claude/vision
  bool get supportsVision {
    // Most Claude 3+ models support vision, including the new naming scheme
    return model.contains('claude-3') ||
        model.contains('claude-opus-4') ||
        model.contains('claude-sonnet-4');
  }

  /// Check if this model supports tool calling
  ///
  /// **Reference:** https://docs.anthropic.com/en/docs/tool-use
  bool get supportsToolCalling {
    // All modern Claude models support tool calling
    return !model.contains('claude-1') && !model.contains('claude-2');
  }

  /// Check if Anthropic native web search is configured.
  bool get webSearchEnabled => webSearchConfig?.enabled == true;

  /// Check if this model supports interleaved thinking
  ///
  /// **Reference:** https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
  bool get supportsInterleavedThinking {
    return model.contains('claude-opus-4') || model.contains('claude-sonnet-4');
  }

  /// Check if this model supports PDF documents
  ///
  /// **Reference:** https://docs.anthropic.com/en/docs/build-with-claude/pdf-support
  bool get supportsPDF {
    // Claude 3+ models support PDF documents, including the new naming scheme
    return model.contains('claude-3') ||
        model.contains('claude-opus-4') ||
        model.contains('claude-sonnet-4');
  }

  /// Get the maximum thinking budget tokens for this model
  int get maxThinkingBudgetTokens {
    // Based on official documentation, thinking budget can be quite large
    // but should be less than max_tokens
    if (supportsReasoning) {
      return 32000; // Conservative upper limit
    }
    return 0;
  }

  /// Validate thinking configuration
  ///
  /// This validation is now more permissive, trusting user configuration
  /// while still providing helpful warnings for obvious misconfigurations.
  String? validateThinkingConfig() {
    // Only validate budget constraints, not model capabilities
    // since users may know better about their specific model setup
    if (thinkingBudgetTokens != null) {
      if (thinkingBudgetTokens! < 1024) {
        return 'Thinking budget tokens must be at least 1024, got $thinkingBudgetTokens';
      }

      if (thinkingBudgetTokens! > maxThinkingBudgetTokens) {
        return 'Thinking budget tokens ($thinkingBudgetTokens) exceeds maximum ($maxThinkingBudgetTokens) for model $model';
      }
    }

    return null; // Valid - trust user configuration for model capabilities
  }

  AnthropicConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    int? maxTokens,
    double? temperature,
    String? systemPrompt,
    Duration? timeout,
    bool? stream,
    double? topP,
    int? topK,
    List<Tool>? tools,
    ToolChoice? toolChoice,
    bool? reasoning,
    int? thinkingBudgetTokens,
    bool? interleavedThinking,
    List<String>? stopSequences,
    String? user,
    ServiceTier? serviceTier,
    DioClientOverrides? dioOverrides,
    Map<String, dynamic>? metadata,
    String? container,
    List<AnthropicMCPServer>? mcpServers,
    WebSearchConfig? webSearchConfig,
  }) =>
      AnthropicConfig(
        apiKey: apiKey ?? this.apiKey,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        maxTokens: maxTokens ?? this.maxTokens,
        temperature: temperature ?? this.temperature,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        timeout: timeout ?? this.timeout,
        dioOverrides: dioOverrides ?? this.dioOverrides,
        stream: stream ?? this.stream,
        topP: topP ?? this.topP,
        topK: topK ?? this.topK,
        tools: tools ?? this.tools,
        toolChoice: toolChoice ?? this.toolChoice,
        reasoning: reasoning ?? this.reasoning,
        thinkingBudgetTokens: thinkingBudgetTokens ?? this.thinkingBudgetTokens,
        interleavedThinking: interleavedThinking ?? this.interleavedThinking,
        stopSequences: stopSequences ?? this.stopSequences,
        user: user ?? this.user,
        serviceTier: serviceTier ?? this.serviceTier,
        metadata: metadata ?? this.metadata,
        container: container ?? this.container,
        mcpServers: mcpServers ?? this.mcpServers,
        webSearchConfig: webSearchConfig ?? this.webSearchConfig,
      );
}
