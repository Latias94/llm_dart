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
  final webSearchConfig = _createLegacyAnthropicWebSearchConfig(config);

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
    reasoning: getLegacyProviderOption<bool>(
          config,
          LegacyProviderOptionNamespaces.anthropic,
          LegacyExtensionKeys.reasoning,
        ) ??
        false,
    thinkingBudgetTokens: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.anthropic,
      LegacyExtensionKeys.thinkingBudgetTokens,
    ),
    interleavedThinking: getLegacyProviderOption<bool>(
          config,
          LegacyProviderOptionNamespaces.anthropic,
          LegacyExtensionKeys.interleavedThinking,
        ) ??
        false,
    metadata: getLegacyProviderOption<Map<String, dynamic>>(
      config,
      LegacyProviderOptionNamespaces.anthropic,
      LegacyExtensionKeys.metadata,
    ),
    container: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.anthropic,
      LegacyExtensionKeys.container,
    ),
    mcpServers: getLegacyProviderOption<List<AnthropicMCPServer>>(
      config,
      LegacyProviderOptionNamespaces.anthropic,
      LegacyExtensionKeys.mcpServers,
    ),
    webSearchConfig: webSearchConfig,
  );
}

WebSearchConfig? _createLegacyAnthropicWebSearchConfig(LLMConfig config) {
  final webSearchConfig = getLegacyProviderOption<WebSearchConfig>(
    config,
    LegacyProviderOptionNamespaces.anthropic,
    LegacyExtensionKeys.webSearchConfig,
  );
  if (webSearchConfig != null) {
    return webSearchConfig;
  }

  if (getLegacyProviderOption<bool>(
        config,
        LegacyProviderOptionNamespaces.anthropic,
        LegacyExtensionKeys.webSearchEnabled,
      ) ==
      true) {
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
