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
    return headers;
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

    // Add interleaved thinking if enabled (Claude 4 only)
    if (config.interleavedThinking) {
      betaFeatures.add('interleaved-thinking-2025-05-14');
    }

    // Add files API beta for file-related endpoints
    if (endpoint.startsWith('files')) {
      betaFeatures.add('files-api-2025-04-14');
    }

    // Add MCP connector beta if MCP servers are configured
    final mcpServers = config.mcpServers;
    if (mcpServers != null && mcpServers.isNotEmpty) {
      betaFeatures.add('mcp-client-2025-04-04');
    }

    // Add extended-cache-ttl beta header only when caching is requested.
    if (_requestUsesCacheControl(config, requestData)) {
      betaFeatures.add('extended-cache-ttl-2025-04-11');
    }

    // Add web fetch beta header when provider-native web fetch is enabled.
    if (config.webFetchEnabled) {
      betaFeatures.add('web-fetch-2025-09-10');
    }

    // Structured outputs + advanced tool use are beta-gated and are driven by
    // request payload shape (tools definitions).
    if (_requestUsesStructuredOutputs(requestData)) {
      betaFeatures.add('structured-outputs-2025-11-13');
    }

    if (_requestUsesAdvancedToolUse(requestData)) {
      betaFeatures.add('advanced-tool-use-2025-11-20');
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
      _toolsContainKey(data, 'defer_loading');

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
