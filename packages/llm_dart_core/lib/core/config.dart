import '../models/chat_models.dart';
import '../models/tool_models.dart';
import 'provider_options.dart';

export 'provider_options.dart' show ProviderOptions, TransportOptions;

/// Unified configuration class for all LLM providers
///
/// This class provides a common configuration interface while allowing
/// provider-only configuration through [providerOptions] and transport settings
/// through [transportOptions].
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

  /// Provider-native tools (provider-executed built-in tools).
  ///
  /// These tools are configured and executed by the provider (server-side) and
  /// are not executed by local tool loops.
  ///
  /// This is an additive surface that will be wired into providers gradually.
  final List<ProviderTool>? providerTools;

  /// Tool choice strategy
  final ToolChoice? toolChoice;

  /// Stop sequences for generation
  final List<String>? stopSequences;

  /// User identifier for tracking and analytics
  final String? user;

  /// Service tier for API requests
  final ServiceTier? serviceTier;

  /// Transport-level options (HTTP config).
  ///
  /// Note: Some entries may be non-JSON values (e.g. a custom HTTP client
  /// instance). Such entries are preserved in memory but may not be
  /// serializable.
  final TransportOptions transportOptions;

  /// Provider-specific options in a namespaced structure.
  ///
  /// This is the preferred long-term mechanism for provider-only features.
  /// It avoids key collisions and keeps the standard surface stable.
  final ProviderOptions providerOptions;

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
    this.providerTools,
    this.toolChoice,
    this.stopSequences,
    this.user,
    this.serviceTier,
    this.transportOptions = const {},
    this.providerOptions = const {},
  });

  /// Get a transport option value (provider-agnostic).
  T? getTransportOption<T>(String key) {
    final raw = transportOptions[key];
    if (raw is T) return raw;
    return null;
  }

  /// Get a provider-specific option value (namespaced).
  T? getProviderOption<T>(String providerId, String key) =>
      readProviderOption<T>(providerOptions, providerId, key);

  /// Check if a transport option exists
  bool hasTransportOption(String key) => transportOptions.containsKey(key);

  /// Check if a provider option exists
  bool hasProviderOption(String providerId, String key) =>
      providerOptions[providerId]?.containsKey(key) ?? false;

  /// Create a new config with transport options merged.
  LLMConfig withTransportOptions(Map<String, dynamic> options) {
    return copyWith(transportOptions: {...transportOptions, ...options});
  }

  /// Create a new config with a single transport option.
  LLMConfig withTransportOption(String key, dynamic value) {
    return withTransportOptions({key: value});
  }

  /// Create a new config with provider options merged for a specific provider.
  LLMConfig withProviderOptions(
      String providerId, Map<String, dynamic> options) {
    final updated = <String, Map<String, dynamic>>{
      ...providerOptions,
      providerId: {
        ...?providerOptions[providerId],
        ...options,
      },
    };
    return copyWith(providerOptions: updated);
  }

  /// Create a new config with a single provider option.
  LLMConfig withProviderOption(String providerId, String key, dynamic value) {
    return withProviderOptions(providerId, {key: value});
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
    List<ProviderTool>? providerTools,
    ToolChoice? toolChoice,
    List<String>? stopSequences,
    String? user,
    ServiceTier? serviceTier,
    TransportOptions? transportOptions,
    ProviderOptions? providerOptions,
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
      providerTools: providerTools ?? this.providerTools,
      toolChoice: toolChoice ?? this.toolChoice,
      stopSequences: stopSequences ?? this.stopSequences,
      user: user ?? this.user,
      serviceTier: serviceTier ?? this.serviceTier,
      transportOptions: transportOptions ?? this.transportOptions,
      providerOptions: providerOptions ?? this.providerOptions,
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
        if (providerTools != null)
          'providerTools': providerTools!.map((t) => t.toJson()).toList(),
        if (toolChoice != null) 'toolChoice': toolChoice!.toJson(),
        if (stopSequences != null) 'stopSequences': stopSequences,
        if (user != null) 'user': user,
        if (serviceTier != null) 'serviceTier': serviceTier!.value,
        'transportOptions': _encodeTransportOptions(transportOptions),
        'providerOptions': providerOptions,
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
        providerTools: json['providerTools'] != null
            ? (json['providerTools'] as List)
                .map((t) => ProviderTool.fromJson(t as Map<String, dynamic>))
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
        transportOptions: _parseTransportOptions(json['transportOptions']),
        providerOptions: _parseProviderOptions(json['providerOptions']),
      );

  static TransportOptions _encodeTransportOptions(TransportOptions raw) {
    if (raw.isEmpty) return const {};

    final result = <String, dynamic>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (_isJsonLike(value)) {
        result[entry.key] = value;
      }
    }
    return result;
  }

  static bool _isJsonLike(Object? value) {
    if (value == null) return true;
    if (value is num || value is String || value is bool) return true;
    if (value is List) {
      for (final item in value) {
        if (!_isJsonLike(item)) return false;
      }
      return true;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        if (entry.key is! String) return false;
        if (!_isJsonLike(entry.value)) return false;
      }
      return true;
    }
    return false;
  }

  static ProviderOptions _parseProviderOptions(dynamic raw) {
    if (raw is! Map) return const {};

    final result = <String, Map<String, dynamic>>{};

    for (final entry in raw.entries) {
      final providerId = entry.key;
      final options = entry.value;

      if (providerId is! String) continue;
      if (options is! Map) continue;

      if (options is Map<String, dynamic>) {
        result[providerId] = options;
        continue;
      }

      final parsed = <String, dynamic>{};
      try {
        options.forEach((k, v) {
          if (k is String) parsed[k] = v;
        });
      } catch (_) {
        continue;
      }
      result[providerId] = parsed;
    }

    return result;
  }

  static TransportOptions _parseTransportOptions(dynamic raw) {
    if (raw is! Map) return const {};
    if (raw is Map<String, dynamic>) return raw;

    final parsed = <String, dynamic>{};
    try {
      raw.forEach((k, v) {
        if (k is String) parsed[k] = v;
      });
    } catch (_) {
      return const {};
    }
    return parsed;
  }

  static ToolChoice _parseToolChoice(Map<String, dynamic> json) {
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

  @override
  String toString() =>
      'LLMConfig(model: $model, baseUrl: $baseUrl, transportOptions: ${transportOptions.keys}, providerOptions: ${providerOptions.keys})';

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
          _listEquals(providerTools, other.providerTools) &&
          toolChoice == other.toolChoice &&
          _listEquals(stopSequences, other.stopSequences) &&
          user == other.user &&
          serviceTier == other.serviceTier &&
          _mapEquals(transportOptions, other.transportOptions) &&
          _mapEquals(providerOptions, other.providerOptions);

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
        providerTools,
        toolChoice,
        stopSequences,
        user,
        serviceTier,
        transportOptions,
        providerOptions,
      );

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
