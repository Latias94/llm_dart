import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_core/core/provider_defaults.dart';
import 'package:llm_dart_core/models/tool_models.dart';

/// Phind provider configuration.
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

  final LLMConfig? _originalConfig;

  const PhindConfig({
    required this.apiKey,
    this.baseUrl = ProviderDefaults.phindBaseUrl,
    this.model = ProviderDefaults.phindDefaultModel,
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

  factory PhindConfig.fromLLMConfig(LLMConfig config) {
    return PhindConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl,
      model: config.model,
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

  LLMConfig? get originalConfig => _originalConfig;

  bool get supportsToolCalling => true;

  bool get supportsVision => false;

  bool get supportsReasoning => false;

  bool get supportsCodeGeneration => false;

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
