import 'package:llm_dart_core/llm_dart_core.dart';

/// Anthropic provider configuration (sub-package version).
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

  final LLMConfig? _originalConfig;

  static const String _defaultBaseUrl = 'https://api.anthropic.com/v1/';
  static const String _defaultModel = 'claude-sonnet-4-20250514';

  const AnthropicConfig({
    required this.apiKey,
    this.baseUrl = _defaultBaseUrl,
    this.model = _defaultModel,
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

  factory AnthropicConfig.fromLLMConfig(LLMConfig config) {
    List<Tool>? tools = config.tools;

    final webSearchEnabled =
        config.getExtension<bool>('webSearchEnabled') == true;
    final webSearchConfig = config.getExtension<dynamic>('webSearchConfig');
    if (webSearchEnabled || webSearchConfig != null) {
      tools = _addWebSearchTool(tools, webSearchConfig);
    }

    return AnthropicConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl.isNotEmpty ? config.baseUrl : _defaultBaseUrl,
      model: config.model.isNotEmpty ? config.model : _defaultModel,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,
      topP: config.topP,
      topK: config.topK,
      tools: tools,
      toolChoice: config.toolChoice,
      stopSequences: config.stopSequences,
      user: config.user,
      serviceTier: config.serviceTier,
      reasoning: config.getExtension<bool>('reasoning') ?? false,
      thinkingBudgetTokens: config.getExtension<int>('thinkingBudgetTokens'),
      interleavedThinking:
          config.getExtension<bool>('interleavedThinking') ?? false,
      originalConfig: config,
    );
  }

  static List<Tool> _addWebSearchTool(
    List<Tool>? existingTools,
    dynamic config,
  ) {
    final tools = List<Tool>.from(existingTools ?? []);

    final hasWebSearchTool =
        tools.any((tool) => tool.function.name == 'web_search');
    if (hasWebSearchTool) {
      return tools;
    }

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

  T? getExtension<T>(String key) => _originalConfig?.getExtension<T>(key);

  LLMConfig? get originalConfig => _originalConfig;

  bool get supportsReasoning {
    return model == 'claude-opus-4-20250514' ||
        model == 'claude-sonnet-4-20250514' ||
        model == 'claude-3-7-sonnet-20250219' ||
        model.contains('claude-3-7-sonnet') ||
        model.contains('claude-opus-4') ||
        model.contains('claude-sonnet-4');
  }

  bool get supportsVision {
    return model.contains('claude-3') ||
        model.contains('claude-opus-4') ||
        model.contains('claude-sonnet-4');
  }

  bool get supportsToolCalling {
    return !model.contains('claude-1') && !model.contains('claude-2');
  }

  bool get supportsInterleavedThinking {
    return model.contains('claude-opus-4') || model.contains('claude-sonnet-4');
  }

  bool get supportsPDF {
    return model.contains('claude-3') ||
        model.contains('claude-opus-4') ||
        model.contains('claude-sonnet-4');
  }

  int get maxThinkingBudgetTokens {
    if (supportsReasoning) {
      return 32000;
    }
    return 0;
  }

  String? validateThinkingConfig() {
    if (thinkingBudgetTokens != null) {
      if (thinkingBudgetTokens! < 1024) {
        return 'Thinking budget tokens must be at least 1024, got $thinkingBudgetTokens';
      }

      if (thinkingBudgetTokens! > maxThinkingBudgetTokens) {
        return 'Thinking budget tokens ($thinkingBudgetTokens) exceeds maximum ($maxThinkingBudgetTokens) for model $model';
      }
    }

    return null;
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
