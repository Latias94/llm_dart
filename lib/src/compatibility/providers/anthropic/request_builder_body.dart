part of 'request_builder.dart';

void _addAnthropicSystemContent(
  Map<String, dynamic> body,
  AnthropicConfig config,
  ProcessedMessages data,
) {
  final allSystemContent = <Map<String, dynamic>>[];

  if (config.systemPrompt != null && config.systemPrompt!.isNotEmpty) {
    allSystemContent.add({
      'type': 'text',
      'text': config.systemPrompt!,
    });
  }

  allSystemContent.addAll(data.systemContentBlocks);

  for (final message in data.systemMessages) {
    allSystemContent.add({
      'type': 'text',
      'text': message,
    });
  }

  if (allSystemContent.isNotEmpty) {
    body['system'] = allSystemContent;
  }
}

void _addAnthropicTools(
  Map<String, dynamic> body,
  AnthropicConfig config,
  ProcessedTools processedTools,
) {
  if (processedTools.tools.isEmpty) {
    return;
  }

  final convertedTools = processedTools.tools
      .map((tool) => _convertAnthropicTool(config, tool))
      .toList();

  if (processedTools.cacheControl != null && convertedTools.isNotEmpty) {
    convertedTools.last['cache_control'] = processedTools.cacheControl;
  }

  body['tools'] = convertedTools;

  if (config.toolChoice != null) {
    body['tool_choice'] = _convertAnthropicToolChoice(config.toolChoice!);
  }
}

void _addAnthropicOptionalParameters(
  Map<String, dynamic> body,
  AnthropicConfig config,
) {
  if (config.temperature != null) {
    body['temperature'] = config.temperature;
  }

  if (config.topP != null) {
    body['top_p'] = config.topP;
  }

  if (config.topK != null) {
    body['top_k'] = config.topK;
  }

  final thinkingConfig = _buildAnthropicThinkingConfig(config);
  if (thinkingConfig != null) {
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
  if (customMetadata != null) {
    metadata.addAll(customMetadata);
  }

  if (metadata.isNotEmpty) {
    body['metadata'] = metadata;
  }

  final container = config.container;
  if (container != null) {
    body['container'] = container;
  }

  final mcpServers = config.mcpServers;
  if (mcpServers != null && mcpServers.isNotEmpty) {
    body['mcp_servers'] = mcpServers.map((server) => server.toJson()).toList();
  }
}

Map<String, dynamic>? _buildAnthropicThinkingConfig(AnthropicConfig config) {
  if (!config.reasoning) {
    return null;
  }

  final thinkingConfig = <String, dynamic>{
    'type': 'enabled',
  };

  if (config.thinkingBudgetTokens != null) {
    thinkingConfig['budget_tokens'] = config.thinkingBudgetTokens;
  }

  return thinkingConfig;
}
