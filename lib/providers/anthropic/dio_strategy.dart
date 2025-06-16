import 'package:dio/dio.dart';
import '../../utils/config_utils.dart';
import '../../utils/dio_client_factory.dart';
import 'config.dart';

/// Anthropic-specific Dio strategy implementation
///
/// Handles Anthropic's unique requirements:
/// - Beta headers for new features
/// - Endpoint-specific header modifications
/// - MCP connector support
/// - Interleaved thinking configuration
class AnthropicDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'Anthropic';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final anthropicConfig = config as AnthropicConfig;
    return ConfigUtils.buildAnthropicHeaders(anthropicConfig.apiKey);
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
    final headers = <String, String>{};
    final betaFeatures = <String>[];

    // Add interleaved thinking if enabled (Claude 4 only)
    if (config.interleavedThinking && config.supportsInterleavedThinking) {
      betaFeatures.add('interleaved-thinking-2025-05-14');
    }

    // Add files API beta for file-related endpoints
    if (endpoint.startsWith('files')) {
      betaFeatures.add('files-api-2025-04-14');
    }

    // Add MCP connector beta if MCP servers are configured
    final mcpServers = config.getExtension<List>('mcpServers');
    if (mcpServers != null && mcpServers.isNotEmpty) {
      betaFeatures.add('mcp-client-2025-04-04');
    }

    // Add extended-cache-ttl beta if request contains 1-hour TTL
    if (_hasOneHourCaching(requestData)) {
      betaFeatures.add('extended-cache-ttl-2025-04-11');
    }

    // Add beta header if any features are enabled
    if (betaFeatures.isNotEmpty) {
      headers['anthropic-beta'] = betaFeatures.join(',');
    }

    return headers;
  }

  /// Check if request data contains 1-hour cache TTL
  bool _hasOneHourCaching(dynamic requestData) {
    if (requestData is! Map<String, dynamic>) return false;

    // Check system messages for 1h TTL
    final system = requestData['system'] as List<dynamic>?;
    if (system != null) {
      for (final systemBlock in system) {
        if (systemBlock is Map<String, dynamic>) {
          final cacheControl =
              systemBlock['cache_control'] as Map<String, dynamic>?;
          if (cacheControl != null && cacheControl['ttl'] == '1h') {
            return true;
          }
        }
      }
    }

    // Check messages for 1h TTL
    final messages = requestData['messages'] as List<dynamic>?;
    if (messages != null) {
      for (final message in messages) {
        if (message is! Map<String, dynamic>) continue;

        final content = message['content'];
        if (content is List) {
          for (final block in content) {
            if (block is Map<String, dynamic>) {
              final cacheControl =
                  block['cache_control'] as Map<String, dynamic>?;
              if (cacheControl != null && cacheControl['ttl'] == '1h') {
                return true;
              }
            }
          }
        }
      }
    }

    return false;
  }
}
