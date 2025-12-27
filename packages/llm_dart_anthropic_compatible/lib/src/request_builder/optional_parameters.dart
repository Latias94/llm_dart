part of 'package:llm_dart_anthropic_compatible/request_builder.dart';

extension _AnthropicRequestBuilderOptionalParameters
    on AnthropicRequestBuilder {
  void _addOptionalParameters(Map<String, dynamic> body) {
    if (config.temperature != null) {
      body['temperature'] = config.temperature;
    }

    if (config.topP != null) {
      body['top_p'] = config.topP;
    }

    if (config.topK != null) {
      body['top_k'] = config.topK;
    }

    if (config.reasoning) {
      final thinkingConfig = <String, dynamic>{
        'type': 'enabled',
      };

      if (config.thinkingBudgetTokens != null) {
        thinkingConfig['budget_tokens'] = config.thinkingBudgetTokens;
      }

      body['thinking'] = thinkingConfig;
    }

    if (config.stopSequences != null && config.stopSequences!.isNotEmpty) {
      body['stop_sequences'] = config.stopSequences;
    }

    if (config.serviceTier != null) {
      body['service_tier'] = config.serviceTier!.value;
    }

    final metadata = <String, dynamic>{};
    if (config.user != null) {
      metadata['user_id'] = config.user;
    }

    final customMetadata = config.metadata;
    if (customMetadata != null && customMetadata.isNotEmpty) {
      metadata.addAll(customMetadata);
    }

    if (metadata.isNotEmpty) {
      body['metadata'] = metadata;
    }

    final container = config.container;
    if (container != null && container.isNotEmpty) {
      body['container'] = container;
    }

    final mcpServers = config.mcpServers;
    if (mcpServers != null && mcpServers.isNotEmpty) {
      body['mcp_servers'] =
          mcpServers.map((server) => server.toJson()).toList();
    }
  }
}
