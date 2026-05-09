import '../models/chat_models.dart';
import '../models/tool_models.dart';

/// Unified configuration class for all LLM providers
///
/// This class provides a common configuration interface while allowing
/// provider-specific extensions through the [extensions] map.
class LLMConfig {
  /// API key for authentication (if required)
  final String? apiKey;

  /// Base URL for API requests
  final String baseUrl;

  /// Model identifier/name to use
  final String model;

  /// Maximum tokens to generate in responses
  final int? maxTokens;

  /// Temperature parameter for controlling response randomness (0.0-1.0)
  final double? temperature;

  /// System prompt/context to guide model behavior
  final String? systemPrompt;

  /// Request timeout duration
  final Duration? timeout;

  /// Top-p (nucleus) sampling parameter
  final double? topP;

  /// Top-k sampling parameter
  final int? topK;

  /// Function tools available to the model
  final List<Tool>? tools;

  /// Tool choice strategy
  final ToolChoice? toolChoice;

  /// Stop sequences for generation
  final List<String>? stopSequences;

  /// User identifier for tracking and analytics
  final String? user;

  /// Service tier for API requests
  final ServiceTier? serviceTier;

  /// Provider-specific configuration extensions
  ///
  /// This map allows providers to store their unique configuration
  /// without polluting the common interface. Examples:
  /// - OpenAI: {'reasoningEffort': 'medium', 'voice': 'alloy'}
  /// - Anthropic: {'reasoning': true, 'thinkingBudgetTokens': 16000}
  /// - Ollama: {'keepAlive': '5m', 'numCtx': 4096}
  final Map<String, dynamic> extensions;

  const LLMConfig({
    this.apiKey,
    required this.baseUrl,
    required this.model,
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.topP,
    this.topK,
    this.tools,
    this.toolChoice,
    this.stopSequences,
    this.user,
    this.serviceTier,
    this.extensions = const {},
  });

  /// Get a provider-specific extension value
  T? getExtension<T>(String key) => extensions[key] as T?;

  /// Check if an extension exists
  bool hasExtension(String key) => extensions.containsKey(key);

  /// Create a new config with additional extensions
  LLMConfig withExtensions(Map<String, dynamic> newExtensions) {
    return LLMConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      maxTokens: maxTokens,
      temperature: temperature,
      systemPrompt: systemPrompt,
      timeout: timeout,
      topP: topP,
      topK: topK,
      tools: tools,
      toolChoice: toolChoice,
      stopSequences: stopSequences,
      user: user,
      serviceTier: serviceTier,
      extensions: {...extensions, ...newExtensions},
    );
  }

  /// Create a new config with a single extension
  LLMConfig withExtension(String key, dynamic value) {
    return withExtensions({key: value});
  }

  /// Create a copy with modified common parameters
  LLMConfig copyWith({
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
    List<String>? stopSequences,
    String? user,
    ServiceTier? serviceTier,
    Map<String, dynamic>? extensions,
  }) {
    return LLMConfig(
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
      stopSequences: stopSequences ?? this.stopSequences,
      user: user ?? this.user,
      serviceTier: serviceTier ?? this.serviceTier,
      extensions: extensions ?? this.extensions,
    );
  }

  /// Convert to JSON representation
  Map<String, dynamic> toJson() => {
        if (apiKey != null) 'apiKey': apiKey,
        'baseUrl': baseUrl,
        'model': model,
        if (maxTokens != null) 'maxTokens': maxTokens,
        if (temperature != null) 'temperature': temperature,
        if (systemPrompt != null) 'systemPrompt': systemPrompt,
        if (timeout != null) 'timeout': timeout!.inMilliseconds,
        if (topP != null) 'topP': topP,
        if (topK != null) 'topK': topK,
        if (tools != null) 'tools': tools!.map((t) => t.toJson()).toList(),
        if (toolChoice != null) 'toolChoice': toolChoice!.toJson(),
        if (stopSequences != null) 'stopSequences': stopSequences,
        if (user != null) 'user': user,
        if (serviceTier != null) 'serviceTier': serviceTier!.value,
        'extensions': extensions,
      };

  /// Create from JSON representation
  factory LLMConfig.fromJson(Map<String, dynamic> json) => LLMConfig(
        apiKey: json['apiKey'] as String?,
        baseUrl: json['baseUrl'] as String,
        model: json['model'] as String,
        maxTokens: json['maxTokens'] as int?,
        temperature: json['temperature'] as double?,
        systemPrompt: json['systemPrompt'] as String?,
        timeout: json['timeout'] != null
            ? Duration(milliseconds: json['timeout'] as int)
            : null,
        topP: json['topP'] as double?,
        topK: json['topK'] as int?,
        tools: json['tools'] != null
            ? (json['tools'] as List)
                .map((t) => Tool.fromJson(t as Map<String, dynamic>))
                .toList()
            : null,
        toolChoice: json['toolChoice'] != null
            ? _parseToolChoice(json['toolChoice'] as Map<String, dynamic>)
            : null,
        stopSequences: json['stopSequences'] != null
            ? List<String>.from(json['stopSequences'] as List)
            : null,
        user: json['user'] as String?,
        serviceTier: ServiceTier.fromString(json['serviceTier'] as String?),
        extensions: json['extensions'] as Map<String, dynamic>? ?? {},
      );

  @override
  String toString() =>
      'LLMConfig(model: $model, baseUrl: $baseUrl, extensions: ${extensions.keys})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LLMConfig &&
          runtimeType == other.runtimeType &&
          apiKey == other.apiKey &&
          baseUrl == other.baseUrl &&
          model == other.model &&
          maxTokens == other.maxTokens &&
          temperature == other.temperature &&
          systemPrompt == other.systemPrompt &&
          timeout == other.timeout &&
          topP == other.topP &&
          topK == other.topK &&
          _listEquals(tools, other.tools) &&
          toolChoice == other.toolChoice &&
          _listEquals(stopSequences, other.stopSequences) &&
          user == other.user &&
          serviceTier == other.serviceTier &&
          _mapEquals(extensions, other.extensions);

  @override
  int get hashCode => Object.hash(
        apiKey,
        baseUrl,
        model,
        maxTokens,
        temperature,
        systemPrompt,
        timeout,
        topP,
        topK,
        tools,
        toolChoice,
        stopSequences,
        user,
        serviceTier,
        extensions,
      );
}

ToolChoice _parseToolChoice(Map<String, dynamic> json) {
  final type = json['type'] as String;
  switch (type) {
    case 'auto':
      return const AutoToolChoice();
    case 'required':
      return const AnyToolChoice();
    case 'none':
      return const NoneToolChoice();
    case 'function':
      final functionName = json['function']['name'] as String;
      return SpecificToolChoice(functionName);
    default:
      throw ArgumentError('Unknown tool choice type: $type');
  }
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}
