import 'package:llm_dart_core/llm_dart_core.dart';

const String _defaultBaseUrl = 'https://https.extension.phind.com/agent/';
const String _defaultModel = 'Phind-70B';

/// Phind provider configuration
///
/// This class contains all configuration options for the Phind providers.
/// Phind is a coding-focused AI assistant with specialized models.
class PhindConfig {
  final String apiKey;
  final String baseUrl;
  final String model;
  final int? maxTokens;
  final double? temperature;
  final String? systemPrompt;
  final Duration? timeout;

  final double? topP;
  final int? topK;
  final List<Tool>? tools;
  final ToolChoice? toolChoice;

  /// Reference to original LLMConfig for accessing extensions
  final LLMConfig? _originalConfig;

  const PhindConfig({
    required this.apiKey,
    this.baseUrl = _defaultBaseUrl,
    this.model = _defaultModel,
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.topP,
    this.topK,
    this.tools,
    this.toolChoice,
    LLMConfig? originalConfig,
  }) : _originalConfig = originalConfig;

  /// Create PhindConfig from unified LLMConfig
  factory PhindConfig.fromLLMConfig(LLMConfig config) {
    return PhindConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl.isNotEmpty ? config.baseUrl : _defaultBaseUrl,
      model: config.model.isNotEmpty ? config.model : _defaultModel,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,
      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      toolChoice: config.toolChoice,
      originalConfig: config,
    );
  }

  /// Get extension value from original config
  T? getExtension<T>(String key) => _originalConfig?.getExtension<T>(key);

  /// Get the original LLMConfig for HTTP configuration
  LLMConfig? get originalConfig => _originalConfig;

  /// Check if this model supports tool calling
  bool get supportsToolCalling {
    // Phind does not support tool calling yet
    return false;
  }

  /// Check if this model supports vision
  bool get supportsVision {
    // Phind does not support vision yet
    return false;
  }

  /// Check if this model supports reasoning/thinking
  bool get supportsReasoning {
    // Phind models are designed for coding and reasoning
    return true;
  }

  /// Check if this model supports code generation
  bool get supportsCodeGeneration {
    // Phind is specialized for coding tasks
    return true;
  }

  /// Get the model family
  String get modelFamily {
    if (model.contains('Phind')) return 'Phind';
    return 'Unknown';
  }

  PhindConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    int? maxTokens,
    double? temperature,
    String? systemPrompt,
    Duration? timeout,
    double? topP,
    int? topK,
    List<Tool>? tools,
    ToolChoice? toolChoice,
  }) =>
      PhindConfig(
        apiKey: apiKey ?? this.apiKey,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        maxTokens: maxTokens ?? this.maxTokens,
        temperature: temperature ?? this.temperature,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        timeout: timeout ?? this.timeout,
        topP: topP ?? this.topP,
        topK: topK ?? this.topK,
        tools: tools ?? this.tools,
        toolChoice: toolChoice ?? this.toolChoice,
      );
}
