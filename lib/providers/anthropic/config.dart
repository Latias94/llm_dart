import '../../models/tool_models.dart';
import '../../models/chat_models.dart';
import '../../core/config.dart';
import '../../core/provider_defaults.dart';
import '../../core/web_search.dart';

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
class AnthropicConfig {
  final String apiKey;
  final String baseUrl;
  final String model;
  final int? maxTokens;
  final double? temperature;
  final String? systemPrompt;
  final Duration? timeout;
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

  /// Reference to original LLMConfig for accessing extensions
  final LLMConfig? _originalConfig;

  const AnthropicConfig({
    required this.apiKey,
    this.baseUrl = ProviderDefaults.anthropicBaseUrl,
    this.model = ProviderDefaults.anthropicDefaultModel,
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
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
    LLMConfig? originalConfig,
  }) : _originalConfig = originalConfig;

  /// Create AnthropicConfig from unified LLMConfig
  factory AnthropicConfig.fromLLMConfig(LLMConfig config) {
    // Handle web search configuration
    List<Tool>? tools = config.tools;

    // Check for webSearchEnabled flag
    final webSearchEnabled = config.getExtension<bool>('webSearchEnabled');
    if (webSearchEnabled == true) {
      tools = _addWebSearchTool(tools, null);
    }

    // Check for webSearchConfig and convert to web_search tool
    final webSearchConfig =
        config.getExtension<WebSearchConfig>('webSearchConfig');
    if (webSearchConfig != null) {
      tools = _addWebSearchTool(tools, webSearchConfig);
    }

    return AnthropicConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl,
      model: config.model,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,

      topP: config.topP,
      topK: config.topK,
      tools: tools,
      toolChoice: config.toolChoice,
      // Common parameters
      stopSequences: config.stopSequences,
      user: config.user,
      serviceTier: config.serviceTier,
      // Anthropic-specific extensions
      reasoning: config.getExtension<bool>('reasoning') ?? false,
      thinkingBudgetTokens: config.getExtension<int>('thinkingBudgetTokens'),
      interleavedThinking:
          config.getExtension<bool>('interleavedThinking') ?? false,
      originalConfig: config,
    );
  }

  /// Add web search tool to the tools list
  static List<Tool> _addWebSearchTool(
      List<Tool>? existingTools, WebSearchConfig? config) {
    final tools = List<Tool>.from(existingTools ?? []);

    // Check if web search tool already exists
    final hasWebSearchTool =
        tools.any((tool) => tool.function.name == 'web_search');
    if (hasWebSearchTool) {
      return tools; // Don't add duplicate
    }

    // Create web search tool based on Anthropic's specification
    // Note: For Anthropic, we need to create a special tool that will be handled differently
    // in the chat implementation to use the web_search_20250305 tool type
    final webSearchTool = Tool.function(
      name: 'web_search',
      description: 'Search the web for current information',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: {
          'query': ParameterProperty(
            propertyType: 'string',
            description: 'The search query to execute',
          ),
        },
        required: ['query'],
      ),
    );

    tools.add(webSearchTool);
    return tools;
  }

  /// Get extension value from original config
  T? getExtension<T>(String key) => _originalConfig?.getExtension<T>(key);

  /// Get the original LLMConfig for HTTP configuration
  LLMConfig? get originalConfig => _originalConfig;

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

  /// Check if this model supports prompt caching
  ///
  /// **Reference:** https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching
  ///
  /// Prompt caching is supported on:
  /// - Claude Opus 4
  /// - Claude Sonnet 4
  /// - Claude Sonnet 3.7
  /// - Claude Sonnet 3.5
  /// - Claude Haiku 3.5
  /// - Claude Haiku 3
  /// - Claude Opus 3
  bool get supportsPromptCaching {
    return model == 'claude-opus-4-20250514' ||
        model == 'claude-sonnet-4-20250514' ||
        model == 'claude-3-7-sonnet-20250219' ||
        model == 'claude-3-5-sonnet-20241022' ||
        model == 'claude-3-5-sonnet-20240620' ||
        model == 'claude-3-5-haiku-20241022' ||
        model == 'claude-3-haiku-20240307' ||
        model == 'claude-3-opus-20240229' ||
        model.contains('claude-opus-4') ||
        model.contains('claude-sonnet-4') ||
        model.contains('claude-3-7-sonnet') ||
        model.contains('claude-3-5-sonnet') ||
        model.contains('claude-3-5-haiku') ||
        model.contains('claude-3-haiku') ||
        model.contains('claude-3-opus');
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
  }) =>
      AnthropicConfig(
        apiKey: apiKey ?? this.apiKey,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        maxTokens: maxTokens ?? this.maxTokens,
        temperature: temperature ?? this.temperature,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        timeout: timeout ?? this.timeout,
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
      );
}
