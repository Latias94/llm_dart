import 'package:llm_dart_anthropic_compatible/mcp_models.dart';
import 'package:llm_dart_anthropic_compatible/provider_tools.dart';
import 'package:llm_dart_anthropic_compatible/web_fetch_tool_options.dart';
import 'package:llm_dart_anthropic_compatible/web_search_tool_options.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';

/// Anthropic-specific LLM builder with provider-specific configuration methods.
///
/// This stays in the umbrella package so provider subpackages do not need to
/// depend on `llm_dart_builder`.
class AnthropicBuilder {
  final LLMBuilder _baseBuilder;

  AnthropicBuilder(this._baseBuilder);

  AnthropicBuilder metadata(Map<String, dynamic> data) {
    _baseBuilder.option('metadata', data);
    return this;
  }

  AnthropicBuilder container(String containerId) {
    _baseBuilder.option('container', containerId);
    return this;
  }

  AnthropicBuilder mcpServers(List<AnthropicMCPServer> servers) {
    _baseBuilder.option('mcpServers', servers);
    return this;
  }

  /// Enables Anthropic provider-native web search as a provider tool.
  AnthropicBuilder webSearchTool({
    String toolType = 'web_search_20250305',
    AnthropicWebSearchToolOptions? options,
  }) {
    _baseBuilder.providerTool(
      AnthropicProviderTools.webSearch(
        toolType: toolType,
        options: options,
      ),
    );
    return this;
  }

  /// Enables Anthropic provider-native web fetch as a provider tool.
  AnthropicBuilder webFetchTool({
    String toolType = 'web_fetch_20250910',
    AnthropicWebFetchToolOptions? options,
  }) {
    _baseBuilder.providerTool(
      AnthropicProviderTools.webFetch(toolType: toolType, options: options),
    );
    return this;
  }
}
