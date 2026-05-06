import 'package:llm_dart_transport/llm_dart_transport.dart'
    show DioClientOverrides, HasDioClientOverrides;

import '../../models/tool_models.dart';

/// Phind provider configuration
///
/// This class contains all configuration options for the Phind providers.
/// Phind is a coding-focused AI assistant with specialized models.
class PhindConfig implements HasDioClientOverrides {
  final String apiKey;
  final String baseUrl;
  final String model;
  final int? maxTokens;
  final double? temperature;
  final String? systemPrompt;
  final Duration? timeout;
  @override
  final DioClientOverrides? dioOverrides;

  final double? topP;
  final int? topK;
  final List<Tool>? tools;
  final ToolChoice? toolChoice;

  const PhindConfig({
    required this.apiKey,
    this.baseUrl = 'https://https.extension.phind.com/agent/',
    this.model = 'Phind-70B',
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.dioOverrides,
    this.topP,
    this.topK,
    this.tools,
    this.toolChoice,
  });

  /// Check if this model supports tool calling
  bool get supportsToolCalling {
    // Phind doesn't support tool calling yet
    return false;
  }

  /// Check if this model supports vision
  bool get supportsVision {
    // Phind doesn't support vision yet
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
    DioClientOverrides? dioOverrides,
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
        dioOverrides: dioOverrides ?? this.dioOverrides,
        topP: topP ?? this.topP,
        topK: topK ?? this.topK,
        tools: tools ?? this.tools,
        toolChoice: toolChoice ?? this.toolChoice,
      );
}
