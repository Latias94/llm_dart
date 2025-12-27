import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_core/core/provider_defaults.dart';
import 'package:llm_dart_core/core/provider_options.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';
import 'mcp_models.dart';
import 'web_fetch_tool_options.dart';
import 'web_search_tool_options.dart';

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
  final String providerId;
  final Map<String, dynamic>? extraBody;
  final Map<String, String>? extraHeaders;
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

  /// Optional Anthropic request metadata.
  ///
  /// This is sourced from `LLMConfig.providerOptions[providerId]['metadata']`,
  /// with an optional fallback to `providerOptions['anthropic']['metadata']`
  /// for Anthropic-compatible providers.
  final Map<String, dynamic>? metadata;

  /// Optional Anthropic Workbench container identifier.
  ///
  /// This is sourced from `LLMConfig.providerOptions[providerId]['container']`,
  /// with an optional fallback to `providerOptions['anthropic']['container']`
  /// for Anthropic-compatible providers.
  final String? container;

  /// Optional Anthropic MCP connector servers configuration.
  ///
  /// This is sourced from `LLMConfig.providerOptions[providerId]['mcpServers']`,
  /// with an optional fallback to `providerOptions['anthropic']['mcpServers']`
  /// for Anthropic-compatible providers.
  final List<AnthropicMCPServer>? mcpServers;

  /// Default prompt caching configuration for Anthropic.
  ///
  /// This is sourced from `LLMConfig.providerOptions['anthropic']['cacheControl']`.
  /// Expected shape (Anthropic API-compatible):
  /// - `{'type': 'ephemeral'}` or `{'type': 'ephemeral', 'ttl': '1h'}`.
  final Map<String, dynamic>? cacheControl;

  /// Provider-native web search tool configuration.
  ///
  /// This is sourced from:
  /// - `providerOptions[providerId]['webSearch']` (preferred), with optional
  ///   fallback to `providerOptions['anthropic']['webSearch']` for
  ///   Anthropic-compatible providers, and
  ///
  /// When enabled (via `webSearchEnabled` or `webSearch.enabled`),
  /// `AnthropicRequestBuilder` injects the correct `web_search_*` built-in tool
  /// into the outgoing request JSON.
  final String? webSearchToolType;

  /// Options for the Anthropic `web_search_*` server tool.
  ///
  /// These options map 1:1 to Anthropic's server tool JSON shape (e.g.
  /// `max_uses`, `allowed_domains`, `blocked_domains`, `user_location`).
  final AnthropicWebSearchToolOptions? webSearchToolOptions;

  /// Provider-native web fetch tool configuration.
  ///
  /// This is sourced from:
  /// - `providerOptions[providerId]['webFetch']` (preferred), with optional
  ///   fallback to `providerOptions['anthropic']['webFetch']` for
  ///   Anthropic-compatible providers, and
  /// - `LLMConfig.providerTools` entries like `anthropic.web_fetch_*`.
  ///
  /// When enabled, `AnthropicRequestBuilder` injects the correct
  /// `web_fetch_*` built-in tool into the outgoing request JSON.
  final String? webFetchToolType;

  /// Options for the Anthropic `web_fetch_*` server tool.
  ///
  /// These options map 1:1 to Anthropic's server tool JSON shape (e.g.
  /// `max_uses`, `allowed_domains`, `citations`, `max_content_tokens`).
  final AnthropicWebFetchToolOptions? webFetchToolOptions;

  /// Reference to original LLMConfig for accessing provider options.
  final LLMConfig? _originalConfig;

  const AnthropicConfig({
    required this.apiKey,
    this.baseUrl = ProviderDefaults.anthropicBaseUrl,
    this.model = ProviderDefaults.anthropicDefaultModel,
    this.providerId = 'anthropic',
    this.extraBody,
    this.extraHeaders,
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
    this.metadata,
    this.container,
    this.mcpServers,
    this.cacheControl,
    this.webSearchToolType,
    this.webSearchToolOptions,
    this.webFetchToolType,
    this.webFetchToolOptions,
    LLMConfig? originalConfig,
  }) : _originalConfig = originalConfig;

  /// Create AnthropicConfig from unified LLMConfig
  ///
  /// By default, provider options are sourced from `providerOptions['anthropic']`.
  ///
  /// For Anthropic-compatible providers (e.g. MiniMax), pass
  /// [providerOptionsNamespace] (e.g. `'minimax'`) to read options from that
  /// namespace first, with a fallback to `'anthropic'`.
  factory AnthropicConfig.fromLLMConfig(
    LLMConfig config, {
    String providerOptionsNamespace = 'anthropic',
  }) {
    final providerOptions = config.providerOptions;
    final fallbackProviderId =
        providerOptionsNamespace == 'anthropic' ? null : 'anthropic';

    Map<String, String>? parseStringMap(Map<String, dynamic>? raw) {
      if (raw == null || raw.isEmpty) return null;
      final result = <String, String>{};
      for (final entry in raw.entries) {
        final value = entry.value;
        if (value is String) {
          result[entry.key] = value;
        }
      }
      return result.isEmpty ? null : result;
    }

    final webSearchEnabledFromProviderOptions = readProviderOption<bool>(
      providerOptions,
      providerOptionsNamespace,
      'webSearchEnabled',
      fallbackProviderId: fallbackProviderId,
    );

    final webSearchConfigFromProviderOptions = _parseWebSearchConfig(
      readProviderOptionMap(
            providerOptions,
            providerOptionsNamespace,
            'webSearch',
            fallbackProviderId: fallbackProviderId,
          ) ??
          readProviderOption<dynamic>(
            providerOptions,
            providerOptionsNamespace,
            'webSearch',
            fallbackProviderId: fallbackProviderId,
          ),
    );

    final effectiveWebSearchEnabled = webSearchEnabledFromProviderOptions ??
        webSearchConfigFromProviderOptions?.enabled;

    final enabledWebSearchConfig = effectiveWebSearchEnabled == true
        ? (webSearchConfigFromProviderOptions ?? const _WebSearchConfig())
        : null;

    final providerToolWebSearchConfig = _buildWebSearchConfigFromProviderTools(
      config,
      providerOptionsNamespace: providerOptionsNamespace,
    );

    final mergedWebSearchConfig = _mergeWebSearchConfigs(
      enabledWebSearchConfig,
      providerToolWebSearchConfig,
    );
    final effectiveWebSearchToolType = mergedWebSearchConfig == null
        ? null
        : (mergedWebSearchConfig.toolType ?? 'web_search_20250305');

    final webFetchEnabledFromProviderOptions = readProviderOption<bool>(
      providerOptions,
      providerOptionsNamespace,
      'webFetchEnabled',
      fallbackProviderId: fallbackProviderId,
    );

    final webFetchConfigFromProviderOptions = _parseWebFetchConfig(
      readProviderOptionMap(
            providerOptions,
            providerOptionsNamespace,
            'webFetch',
            fallbackProviderId: fallbackProviderId,
          ) ??
          readProviderOption<dynamic>(
            providerOptions,
            providerOptionsNamespace,
            'webFetch',
            fallbackProviderId: fallbackProviderId,
          ),
    );

    final effectiveWebFetchEnabled = webFetchEnabledFromProviderOptions ??
        webFetchConfigFromProviderOptions?.enabled;

    final enabledWebFetchConfig = effectiveWebFetchEnabled == true
        ? (webFetchConfigFromProviderOptions ?? const _WebFetchConfig())
        : null;

    final providerToolWebFetchConfig = _buildWebFetchConfigFromProviderTools(
      config,
      providerOptionsNamespace: providerOptionsNamespace,
    );

    final mergedWebFetchConfig = _mergeWebFetchConfigs(
      enabledWebFetchConfig,
      providerToolWebFetchConfig,
    );

    final cacheControl = _parseCacheControl(
      readProviderOptionMap(
            providerOptions,
            providerOptionsNamespace,
            'cacheControl',
            fallbackProviderId: fallbackProviderId,
          ) ??
          readProviderOption<dynamic>(
            providerOptions,
            providerOptionsNamespace,
            'cacheControl',
            fallbackProviderId: fallbackProviderId,
          ),
    );

    final extraBody = readProviderOptionMap(
      providerOptions,
      providerOptionsNamespace,
      'extraBody',
      fallbackProviderId: fallbackProviderId,
    );

    final extraHeaders = parseStringMap(
      readProviderOptionMap(
        providerOptions,
        providerOptionsNamespace,
        'extraHeaders',
        fallbackProviderId: fallbackProviderId,
      ),
    );

    final metadata = _parseMetadata(
      readProviderOptionMap(
        providerOptions,
        providerOptionsNamespace,
        'metadata',
        fallbackProviderId: fallbackProviderId,
      ),
    );

    final container = _parseContainer(
      readProviderOption<String>(
        providerOptions,
        providerOptionsNamespace,
        'container',
        fallbackProviderId: fallbackProviderId,
      ),
    );

    final mcpServers = _parseMcpServers(
      readProviderOptionList(
        providerOptions,
        providerOptionsNamespace,
        'mcpServers',
        fallbackProviderId: fallbackProviderId,
      ),
    );

    final reasoning = readProviderOption<bool>(
          providerOptions,
          providerOptionsNamespace,
          'reasoning',
          fallbackProviderId: fallbackProviderId,
        ) ??
        false;

    final thinkingBudgetTokens = readProviderOption<int>(
      providerOptions,
      providerOptionsNamespace,
      'thinkingBudgetTokens',
      fallbackProviderId: fallbackProviderId,
    );

    final interleavedThinking = readProviderOption<bool>(
          providerOptions,
          providerOptionsNamespace,
          'interleavedThinking',
          fallbackProviderId: fallbackProviderId,
        ) ??
        false;

    return AnthropicConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl,
      model: config.model,
      providerId: providerOptionsNamespace,
      extraBody: extraBody,
      extraHeaders: extraHeaders,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,

      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      toolChoice: config.toolChoice,
      // Common parameters
      stopSequences: config.stopSequences,
      user: config.user,
      serviceTier: config.serviceTier,
      // Anthropic-specific provider options (namespaced)
      reasoning: reasoning,
      thinkingBudgetTokens: thinkingBudgetTokens,
      interleavedThinking: interleavedThinking,
      metadata: metadata,
      container: container,
      mcpServers: mcpServers,
      cacheControl: cacheControl,
      webSearchToolType: effectiveWebSearchToolType,
      webSearchToolOptions: mergedWebSearchConfig?.options,
      webFetchToolType: mergedWebFetchConfig?.toolType,
      webFetchToolOptions: mergedWebFetchConfig?.options,
      originalConfig: config,
    );
  }

  /// Get the original LLMConfig for HTTP configuration
  LLMConfig? get originalConfig => _originalConfig;

  static Map<String, dynamic>? _parseCacheControl(dynamic raw) {
    if (raw == null) return null;

    if (raw == true) {
      return const {'type': 'ephemeral'};
    }

    if (raw is String) {
      final type = raw.trim();
      if (type.isEmpty) return null;
      return {'type': type};
    }

    if (raw is Map<String, dynamic>) {
      final type = raw['type'];
      if (type is! String || type.trim().isEmpty) return null;
      return raw;
    }

    return null;
  }

  static _WebSearchConfig? _parseWebSearchConfig(dynamic raw) {
    if (raw == null) return null;

    if (raw is _WebSearchConfig) return raw;

    if (raw == true) {
      return const _WebSearchConfig(enabled: true);
    }

    if (raw is String) {
      final type = raw.trim();
      if (type.isEmpty) return null;
      return _WebSearchConfig(enabled: true, toolType: type);
    }

    if (raw is Map<String, dynamic>) return _WebSearchConfig.fromJson(raw);

    return null;
  }

  static _WebFetchConfig? _parseWebFetchConfig(dynamic raw) {
    if (raw == null) return null;
    if (raw is _WebFetchConfig) return raw;

    if (raw == true) {
      return const _WebFetchConfig(enabled: true);
    }

    if (raw is String) {
      final type = raw.trim();
      if (type.isEmpty) return null;
      return _WebFetchConfig(enabled: true, toolType: type);
    }

    if (raw is Map<String, dynamic>) return _WebFetchConfig.fromJson(raw);

    return null;
  }

  static _WebSearchConfig? _buildWebSearchConfigFromProviderTools(
    LLMConfig config, {
    required String providerOptionsNamespace,
  }) {
    final providerTools = config.providerTools;
    if (providerTools == null || providerTools.isEmpty) return null;

    ProviderTool? tool;
    for (final candidate in providerTools) {
      final id = candidate.id;
      if (id.startsWith('$providerOptionsNamespace.web_search_') ||
          id.startsWith('anthropic.web_search_')) {
        tool = candidate;
        break;
      }
    }
    if (tool == null) return null;

    final rawEnabled = tool.options['enabled'];
    final enabled = rawEnabled is bool ? rawEnabled : true;
    if (!enabled) return null;

    final idSuffix = tool.id.split('.').last;
    final normalizedType =
        idSuffix.startsWith('web_search_') ? idSuffix : 'web_search_20250305';

    final options = tool.options.isNotEmpty
        ? AnthropicWebSearchToolOptions.fromJson(
            Map<String, dynamic>.from(tool.options),
          )
        : null;

    return _WebSearchConfig(
      enabled: true,
      toolType: normalizedType,
      options: options,
    );
  }

  static _WebFetchConfig? _buildWebFetchConfigFromProviderTools(
    LLMConfig config, {
    required String providerOptionsNamespace,
  }) {
    final providerTools = config.providerTools;
    if (providerTools == null || providerTools.isEmpty) return null;

    ProviderTool? tool;
    for (final candidate in providerTools) {
      final id = candidate.id;
      if (id.startsWith('$providerOptionsNamespace.web_fetch_') ||
          id.startsWith('anthropic.web_fetch_')) {
        tool = candidate;
        break;
      }
    }
    if (tool == null) return null;

    final rawEnabled = tool.options['enabled'];
    final enabled = rawEnabled is bool ? rawEnabled : true;
    if (!enabled) return null;

    final idSuffix = tool.id.split('.').last;
    final normalizedType =
        idSuffix.startsWith('web_fetch_') ? idSuffix : 'web_fetch_20250910';

    final options = tool.options.isNotEmpty
        ? AnthropicWebFetchToolOptions.fromJson(
            Map<String, dynamic>.from(tool.options),
          )
        : null;

    return _WebFetchConfig(
      enabled: true,
      toolType: normalizedType,
      options: options,
    );
  }

  static _WebSearchConfig? _mergeWebSearchConfigs(
    _WebSearchConfig? primary,
    _WebSearchConfig? secondary,
  ) {
    if (primary == null) return secondary;
    if (secondary == null) return primary;

    final mergedOptions = _mergeWebSearchToolOptions(
      primary.options,
      secondary.options,
    );

    final mergedType =
        (primary.toolType != null && primary.toolType!.isNotEmpty)
            ? primary.toolType
            : secondary.toolType;

    return _WebSearchConfig(
      enabled: true,
      toolType: mergedType,
      options: mergedOptions,
    );
  }

  static AnthropicWebSearchToolOptions? _mergeWebSearchToolOptions(
    AnthropicWebSearchToolOptions? primary,
    AnthropicWebSearchToolOptions? secondary,
  ) {
    if (primary == null) return secondary;
    if (secondary == null) return primary;

    return AnthropicWebSearchToolOptions(
      maxUses: primary.maxUses ?? secondary.maxUses,
      allowedDomains: primary.allowedDomains ?? secondary.allowedDomains,
      blockedDomains: primary.blockedDomains ?? secondary.blockedDomains,
      userLocation: primary.userLocation ?? secondary.userLocation,
    );
  }

  static _WebFetchConfig? _mergeWebFetchConfigs(
    _WebFetchConfig? primary,
    _WebFetchConfig? secondary,
  ) {
    if (primary == null) return secondary;
    if (secondary == null) return primary;

    final mergedOptions = _mergeWebFetchToolOptions(
      primary.options,
      secondary.options,
    );

    final mergedType =
        (primary.toolType != null && primary.toolType!.isNotEmpty)
            ? primary.toolType
            : secondary.toolType;

    return _WebFetchConfig(
      enabled: true,
      toolType: mergedType ?? 'web_fetch_20250910',
      options: mergedOptions,
    );
  }

  static AnthropicWebFetchToolOptions? _mergeWebFetchToolOptions(
    AnthropicWebFetchToolOptions? primary,
    AnthropicWebFetchToolOptions? secondary,
  ) {
    if (primary == null) return secondary;
    if (secondary == null) return primary;

    return AnthropicWebFetchToolOptions(
      maxUses: primary.maxUses ?? secondary.maxUses,
      allowedDomains: primary.allowedDomains ?? secondary.allowedDomains,
      blockedDomains: primary.blockedDomains ?? secondary.blockedDomains,
      citations: primary.citations ?? secondary.citations,
      maxContentTokens: primary.maxContentTokens ?? secondary.maxContentTokens,
    );
  }

  static Map<String, dynamic>? _parseMetadata(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static String? _parseContainer(dynamic raw) {
    if (raw is String && raw.trim().isNotEmpty) return raw;
    return null;
  }

  static List<AnthropicMCPServer>? _parseMcpServers(dynamic raw) {
    if (raw == null) return null;
    if (raw is List<AnthropicMCPServer>) return raw;
    if (raw is List) {
      final servers = <AnthropicMCPServer>[];
      for (final item in raw) {
        if (item is AnthropicMCPServer) {
          servers.add(item);
          continue;
        }
        if (item is Map<String, dynamic>) {
          servers.add(AnthropicMCPServer.fromJson(item));
          continue;
        }
        if (item is Map) {
          servers.add(
            AnthropicMCPServer.fromJson(Map<String, dynamic>.from(item)),
          );
          continue;
        }
      }
      return servers.isEmpty ? null : servers;
    }
    return null;
  }

  /// Check if this model supports reasoning/thinking
  ///
  /// **Reference:** https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
  ///
  /// Note: `llm_dart` does not maintain per-model capability matrices. This is
  /// a best-effort hint and should not be used for strict validation.
  bool get supportsReasoning {
    return true;
  }

  /// Check if this model supports vision
  ///
  /// **Reference:** https://docs.anthropic.com/en/docs/build-with-claude/vision
  bool get supportsVision {
    return true;
  }

  /// Check if this model supports tool calling
  ///
  /// **Reference:** https://docs.anthropic.com/en/docs/tool-use
  bool get supportsToolCalling {
    return true;
  }

  /// Check if this model supports interleaved thinking
  ///
  /// **Reference:** https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
  bool get supportsInterleavedThinking {
    return true;
  }

  /// Check if this model supports PDF documents
  ///
  /// **Reference:** https://docs.anthropic.com/en/docs/build-with-claude/pdf-support
  bool get supportsPDF {
    return true;
  }

  /// Get the maximum thinking budget tokens for this model
  int get maxThinkingBudgetTokens {
    return 32000;
  }

  /// Validate thinking configuration
  ///
  /// `llm_dart` does not enforce per-model constraints.
  String? validateThinkingConfig() {
    return null;
  }

  bool get webFetchEnabled => webFetchToolType != null;

  bool get webSearchEnabled => webSearchToolType != null;

  AnthropicConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    String? providerId,
    Map<String, dynamic>? extraBody,
    Map<String, String>? extraHeaders,
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
    Map<String, dynamic>? metadata,
    String? container,
    List<AnthropicMCPServer>? mcpServers,
    Map<String, dynamic>? cacheControl,
    String? webSearchToolType,
    AnthropicWebSearchToolOptions? webSearchToolOptions,
    String? webFetchToolType,
    AnthropicWebFetchToolOptions? webFetchToolOptions,
    bool clearWebSearchTool = false,
    bool clearWebFetchTool = false,
    LLMConfig? originalConfig,
  }) =>
      AnthropicConfig(
        apiKey: apiKey ?? this.apiKey,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        providerId: providerId ?? this.providerId,
        extraBody: extraBody ?? this.extraBody,
        extraHeaders: extraHeaders ?? this.extraHeaders,
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
        metadata: metadata ?? this.metadata,
        container: container ?? this.container,
        mcpServers: mcpServers ?? this.mcpServers,
        cacheControl: cacheControl ?? this.cacheControl,
        webSearchToolType: clearWebSearchTool
            ? null
            : (webSearchToolType ?? this.webSearchToolType),
        webSearchToolOptions: clearWebSearchTool
            ? null
            : (webSearchToolOptions ?? this.webSearchToolOptions),
        webFetchToolType: clearWebFetchTool
            ? null
            : (webFetchToolType ?? this.webFetchToolType),
        webFetchToolOptions: clearWebFetchTool
            ? null
            : (webFetchToolOptions ?? this.webFetchToolOptions),
        originalConfig: originalConfig ?? _originalConfig,
      );
}

class _WebSearchConfig {
  final bool enabled;
  final String? toolType;
  final AnthropicWebSearchToolOptions? options;

  const _WebSearchConfig({
    this.enabled = true,
    this.toolType,
    this.options,
  });

  factory _WebSearchConfig.fromJson(Map<String, dynamic> json) {
    final rawEnabled = json['enabled'];
    final enabled = rawEnabled is bool ? rawEnabled : true;

    final rawType = json['toolType'] ??
        json['tool_type'] ??
        json['type'] ??
        json['tool'] ??
        json['toolName'] ??
        json['mode'];

    final toolType =
        rawType is String && rawType.trim().isNotEmpty ? rawType.trim() : null;

    final normalizedType =
        (toolType != null && toolType.startsWith('web_search_'))
            ? toolType
            : null;

    final options = AnthropicWebSearchToolOptions.fromJson(json);

    return _WebSearchConfig(
      enabled: enabled,
      toolType: normalizedType,
      options: options,
    );
  }
}

class _WebFetchConfig {
  final bool enabled;
  final String? toolType;
  final AnthropicWebFetchToolOptions? options;

  const _WebFetchConfig({
    this.enabled = true,
    this.toolType = 'web_fetch_20250910',
    this.options,
  });

  factory _WebFetchConfig.fromJson(Map<String, dynamic> json) {
    final rawEnabled = json['enabled'];
    final enabled = rawEnabled is bool ? rawEnabled : true;

    final rawType = json['toolType'] ??
        json['tool_type'] ??
        json['type'] ??
        json['tool'] ??
        json['toolName'];

    final toolType = rawType is String && rawType.trim().isNotEmpty
        ? rawType.trim()
        : (json['mode'] is String ? (json['mode'] as String).trim() : null);

    final options = AnthropicWebFetchToolOptions.fromJson(json);

    final normalizedType =
        (toolType != null && toolType.startsWith('web_fetch_'))
            ? toolType
            : 'web_fetch_20250910';

    return _WebFetchConfig(
      enabled: enabled,
      toolType: normalizedType,
      options: options,
    );
  }
}
