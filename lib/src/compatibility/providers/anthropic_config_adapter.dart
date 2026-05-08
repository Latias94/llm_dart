import '../../../core/config.dart';
import '../../../core/web_search.dart';
import '../../../models/tool_models.dart';
import '../../../providers/anthropic/config.dart';
import '../../../providers/anthropic/mcp_models.dart';
import '../config/legacy_config_keys.dart';
import '../config/legacy_provider_options.dart';
import 'community_provider_config_adapters.dart';

/// Adapts a legacy root `LLMConfig` into an Anthropic provider config.
AnthropicConfig createLegacyAnthropicConfig(LLMConfig config) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.anthropic,
  );
  final webSearchConfig = _createLegacyAnthropicWebSearchConfig(options);

  return AnthropicConfig(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    model: config.model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt,
    timeout: config.timeout,
    dioOverrides: createLegacyDioClientOverrides(config),
    topP: config.topP,
    topK: config.topK,
    tools: _addLegacyWebSearchTool(config.tools, webSearchConfig),
    toolChoice: config.toolChoice,
    stopSequences: config.stopSequences,
    user: config.user,
    serviceTier: config.serviceTier,
    reasoning: options.get<bool>(LegacyExtensionKeys.reasoning) ?? false,
    thinkingBudgetTokens: options.get<int>(
      LegacyExtensionKeys.thinkingBudgetTokens,
    ),
    interleavedThinking:
        options.get<bool>(LegacyExtensionKeys.interleavedThinking) ?? false,
    metadata: options.get<Map<String, dynamic>>(
      LegacyExtensionKeys.metadata,
    ),
    container: options.get<String>(LegacyExtensionKeys.container),
    mcpServers: options.get<List<AnthropicMCPServer>>(
      LegacyExtensionKeys.mcpServers,
    ),
    webSearchConfig: webSearchConfig,
  );
}

WebSearchConfig? _createLegacyAnthropicWebSearchConfig(
  LegacyProviderOptionView options,
) {
  final webSearchConfig = options.get<WebSearchConfig>(
    LegacyExtensionKeys.webSearchConfig,
  );
  if (webSearchConfig != null) {
    return webSearchConfig;
  }

  if (options.get<bool>(LegacyExtensionKeys.webSearchEnabled) == true) {
    return const WebSearchConfig();
  }

  return null;
}

List<Tool>? _addLegacyWebSearchTool(
  List<Tool>? existingTools,
  WebSearchConfig? webSearchConfig,
) {
  if (webSearchConfig?.enabled != true) {
    return existingTools;
  }

  final tools = List<Tool>.from(existingTools ?? const []);
  final hasWebSearchTool =
      tools.any((tool) => tool.function.name == 'web_search');
  if (hasWebSearchTool) {
    return tools;
  }

  tools.add(
    Tool.function(
      name: 'web_search',
      description: 'Search the web for current information',
      parameters: const ParametersSchema(
        schemaType: 'object',
        properties: {
          'query': ParameterProperty(
            propertyType: 'string',
            description: 'The search query to execute',
          ),
        },
        required: ['query'],
      ),
    ),
  );
  return tools;
}
