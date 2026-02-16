/// (Tier 3 / opt-in) Anthropic-compatible Dio strategy used by `llm_dart_provider_utils`.
///
/// This library powers `llm_dart_anthropic_compatible`, but is intentionally not
/// exported from the recommended entrypoint.
library;

import 'package:dio/dio.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'config.dart';

/// Anthropic-specific Dio strategy implementation
///
/// Handles Anthropic's unique requirements:
/// - Beta headers for new features
/// - Endpoint-specific header modifications
/// - MCP connector support
/// - Interleaved thinking configuration
class AnthropicDioStrategy extends BaseProviderDioStrategy {
  final String _providerName;

  AnthropicDioStrategy({String providerName = 'Anthropic'})
      : _providerName = providerName;

  @override
  String get providerName => _providerName;

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final anthropicConfig = config as AnthropicConfig;
    final headers = ConfigUtils.buildAnthropicHeaders(anthropicConfig.apiKey);
    final extra = anthropicConfig.extraHeaders;
    if (extra != null && extra.isNotEmpty) {
      headers.addAll(extra);
    }

    return withUserAgentSuffix(
      headers,
      defaultUserAgentSuffixPartsForProvider(anthropicConfig.providerId),
    );
  }

  @override
  List<DioEnhancer> getEnhancers(dynamic config) {
    final anthropicConfig = config as AnthropicConfig;

    return [
      // Always add the endpoint-specific headers interceptor
      InterceptorEnhancer(
        _createEndpointHeadersInterceptor(anthropicConfig),
        'AnthropicEndpointHeaders',
      ),
    ];
  }

  /// Create interceptor for endpoint-specific headers
  ///
  /// This interceptor dynamically adds beta headers based on:
  /// - The specific endpoint being called
  /// - Configuration settings (interleaved thinking, MCP servers)
  /// - Request content (caching features)
  /// - Available features
  InterceptorsWrapper _createEndpointHeadersInterceptor(
      AnthropicConfig config) {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // Build headers based on endpoint and configuration
        final endpoint = options.path;
        final requestData = options.data;
        final headers =
            _buildEndpointSpecificHeaders(config, endpoint, requestData);
        options.headers.addAll(headers);
        handler.next(options);
      },
    );
  }

  /// Build headers specific to the endpoint and configuration
  Map<String, String> _buildEndpointSpecificHeaders(
    AnthropicConfig config,
    String endpoint, [
    dynamic requestData,
  ]) {
    // For Anthropic-compatible providers (e.g. MiniMax) we avoid sending
    // Anthropic beta headers by default. Users can still opt in via
    // `providerOptions[providerId].extraHeaders['anthropic-beta']`.
    if (config.providerId != 'anthropic') return const {};

    final headers = <String, String>{};
    final betaFeatures = <String>[];

    void addBeta(String feature) {
      if (feature.isEmpty) return;
      if (betaFeatures.contains(feature)) return;
      betaFeatures.add(feature);
    }

    // Add interleaved thinking if enabled (Claude 4 only)
    if (config.interleavedThinking) {
      addBeta('interleaved-thinking-2025-05-14');
    }

    // Add files API beta for file-related endpoints
    if (endpoint.startsWith('files')) {
      addBeta('files-api-2025-04-14');
    }

    // Add MCP connector beta if MCP servers are configured
    final mcpServers = config.mcpServers;
    if (mcpServers != null && mcpServers.isNotEmpty) {
      addBeta('mcp-client-2025-04-04');
    }

    // Add extended-cache-ttl beta header only when caching is requested.
    if (_requestUsesCacheControl(config, requestData)) {
      addBeta('extended-cache-ttl-2025-04-11');
    }

    // Keep the legacy config-driven web fetch signal for cases where request
    // payload inspection is unavailable (e.g. tests or custom transports).
    if (config.webFetchEnabled) {
      addBeta('web-fetch-2025-09-10');
    }

    // Add beta headers for provider-defined tools present in the request.
    //
    // We infer them from `tools[].type` (Anthropic server tools / built-ins).
    final toolTypes = _extractToolTypes(requestData);
    for (final feature in _betaFeaturesForToolTypes(toolTypes)) {
      addBeta(feature);
    }

    // Add PDF support beta header when PDF documents are present in the request.
    if (_requestUsesPdfDocuments(requestData)) {
      addBeta('pdfs-2024-09-25');
    }

    // Structured outputs + advanced tool use are beta-gated and are driven by
    // request payload shape (tools definitions).
    if (_requestUsesStructuredOutputs(requestData)) {
      addBeta('structured-outputs-2025-11-13');
    }

    if (_requestUsesAdvancedToolUse(requestData)) {
      addBeta('advanced-tool-use-2025-11-20');
    }

    // Add beta header if any features are enabled
    if (betaFeatures.isNotEmpty) {
      headers['anthropic-beta'] = betaFeatures.join(',');
    }

    return headers;
  }

  static bool _requestUsesCacheControl(AnthropicConfig config, dynamic data) {
    if (config.cacheControl != null) return true;
    return _containsCacheControlKey(data);
  }

  static bool _containsCacheControlKey(dynamic value) {
    if (value is Map) {
      if (value.containsKey('cache_control')) return true;
      for (final v in value.values) {
        if (_containsCacheControlKey(v)) return true;
      }
    } else if (value is List) {
      for (final v in value) {
        if (_containsCacheControlKey(v)) return true;
      }
    }
    return false;
  }

  static bool _requestUsesStructuredOutputs(dynamic data) =>
      _toolsContainKey(data, 'strict');

  static bool _requestUsesAdvancedToolUse(dynamic data) =>
      _toolsContainKey(data, 'input_examples') ||
      _toolsContainKey(data, 'allowed_callers') ||
      _toolsContainKey(data, 'defer_loading') ||
      _toolsContainProviderToolSearch(data);

  static bool _toolsContainProviderToolSearch(dynamic data) {
    if (data is! Map) return false;
    final tools = data['tools'];
    if (tools is! List) return false;
    for (final tool in tools) {
      if (tool is! Map) continue;
      final type = tool['type'];
      if (type is! String) continue;
      if (type.startsWith('tool_search_tool_')) return true;
    }
    return false;
  }

  static Set<String> _extractToolTypes(dynamic data) {
    if (data is! Map) return const {};
    final tools = data['tools'];
    if (tools is! List) return const {};

    final types = <String>{};
    for (final tool in tools) {
      if (tool is! Map) continue;
      final type = tool['type'];
      if (type is String && type.trim().isNotEmpty) {
        types.add(type.trim());
      }
    }
    return types;
  }

  static Iterable<String> _betaFeaturesForToolTypes(
      Set<String> toolTypes) sync* {
    if (toolTypes.isEmpty) return;

    // Code execution betas (type-based).
    if (toolTypes.contains('code_execution_20250522')) {
      yield 'code-execution-2025-05-22';
    }
    if (toolTypes.contains('code_execution_20250825')) {
      yield 'code-execution-2025-08-25';
    }

    // Computer use betas (shared across computer/text editor/bash variants).
    final hasComputerUse20241022 = toolTypes.contains('computer_20241022') ||
        toolTypes.contains('text_editor_20241022') ||
        toolTypes.contains('bash_20241022');
    if (hasComputerUse20241022) {
      yield 'computer-use-2024-10-22';
    }

    final hasComputerUse20250124 = toolTypes.contains('computer_20250124') ||
        toolTypes.contains('text_editor_20250124') ||
        toolTypes.contains('text_editor_20250429') ||
        toolTypes.contains('bash_20250124');
    if (hasComputerUse20250124) {
      yield 'computer-use-2025-01-24';
    }

    if (toolTypes.contains('computer_20251124')) {
      yield 'computer-use-2025-11-24';
    }

    // Context management beta for memory tool.
    if (toolTypes.contains('memory_20250818')) {
      yield 'context-management-2025-06-27';
    }

    // Web fetch beta (tool-based).
    if (toolTypes.contains('web_fetch_20250910')) {
      yield 'web-fetch-2025-09-10';
    }

    // Tool search is part of advanced tool use.
    if (toolTypes.contains('tool_search_tool_regex_20251119') ||
        toolTypes.contains('tool_search_tool_bm25_20251119')) {
      yield 'advanced-tool-use-2025-11-20';
    }
  }

  static bool _requestUsesPdfDocuments(dynamic data) =>
      _containsPdfDocumentBlock(data);

  static bool _containsPdfDocumentBlock(dynamic value) {
    if (value is Map) {
      final type = value['type'];
      if (type == 'document') {
        final source = value['source'];
        if (source is Map) {
          final mediaType = source['media_type'];
          if (mediaType == 'application/pdf') return true;

          final sourceType = source['type'];
          if (sourceType == 'url') {
            final url = source['url'];
            if (url is String) {
              final trimmed = url.trim();
              final parsed = Uri.tryParse(trimmed);
              final path = parsed?.path ?? trimmed;
              if (path.toLowerCase().endsWith('.pdf')) return true;
            }
          }
        }
      }

      for (final v in value.values) {
        if (_containsPdfDocumentBlock(v)) return true;
      }
    } else if (value is List) {
      for (final v in value) {
        if (_containsPdfDocumentBlock(v)) return true;
      }
    }

    return false;
  }

  static bool _toolsContainKey(dynamic data, String key) {
    if (data is! Map) return false;
    final tools = data['tools'];
    if (tools is! List) return false;
    for (final tool in tools) {
      if (tool is Map && tool.containsKey(key)) return true;
    }
    return false;
  }
}
