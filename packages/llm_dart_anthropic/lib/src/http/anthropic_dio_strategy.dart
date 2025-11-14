import 'package:dio/dio.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/anthropic_config.dart';

/// Anthropic-specific Dio strategy implementation.
class AnthropicDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'Anthropic';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final anthropicConfig = config as AnthropicConfig;
    return {
      'Content-Type': 'application/json',
      'x-api-key': anthropicConfig.apiKey,
      'anthropic-version': '2023-06-01',
    };
  }

  @override
  List<DioEnhancer> getEnhancers(dynamic config) {
    final anthropicConfig = config as AnthropicConfig;

    return [
      InterceptorEnhancer(
        _createEndpointHeadersInterceptor(anthropicConfig),
        'AnthropicEndpointHeaders',
      ),
    ];
  }

  InterceptorsWrapper _createEndpointHeadersInterceptor(
    AnthropicConfig config,
  ) {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final endpoint = options.path;
        final headers =
            _buildEndpointSpecificHeaders(config, endpoint, options.data);
        options.headers.addAll(headers);
        handler.next(options);
      },
    );
  }

  Map<String, String> _buildEndpointSpecificHeaders(
    AnthropicConfig config,
    String endpoint, [
    dynamic requestData,
  ]) {
    final headers = <String, String>{};
    final betaFeatures = <String>[];

    if (config.interleavedThinking && config.supportsInterleavedThinking) {
      betaFeatures.add('interleaved-thinking-2025-05-14');
    }

    if (endpoint.startsWith('files')) {
      betaFeatures.add('files-api-2025-04-14');
    }

    final mcpServers = config.getExtension<List>('mcpServers');
    if (mcpServers != null && mcpServers.isNotEmpty) {
      betaFeatures.add('mcp-client-2025-04-04');
    }

    betaFeatures.add('extended-cache-ttl-2025-04-11');

    if (betaFeatures.isNotEmpty) {
      headers['anthropic-beta'] = betaFeatures.join(',');
    }

    return headers;
  }
}
