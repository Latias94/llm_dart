import 'package:llm_dart_anthropic_compatible/computer_tool_options.dart';
import 'package:llm_dart_anthropic_compatible/mcp_models.dart';
import 'package:llm_dart_anthropic_compatible/provider_tools.dart';
import 'package:llm_dart_anthropic_compatible/text_editor_tool_options.dart';
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

  /// Configure Anthropic prompt caching (`cache_control`) via `providerOptions`.
  ///
  /// This writes to `providerOptions['anthropic']['cacheControl']`.
  ///
  /// Note: This is provider-specific. Other providers ignore this option.
  AnthropicBuilder cacheControl(Map<String, dynamic> cacheControl) {
    _baseBuilder.option('cacheControl', cacheControl);
    return this;
  }

  /// Convenience helper for Anthropic ephemeral prompt caching.
  ///
  /// Example payload:
  /// - `{ "type": "ephemeral", "ttl": "1h" }`
  ///
  /// The `ttl` format is Anthropic-specific (string).
  AnthropicBuilder cacheControlEphemeral({String? ttl}) {
    return cacheControl(<String, dynamic>{
      'type': 'ephemeral',
      if (ttl != null) 'ttl': ttl,
    });
  }

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

  /// Enables Anthropic provider-native code execution (server tool).
  AnthropicBuilder codeExecutionTool({
    String toolType = 'code_execution_20250825',
  }) {
    _baseBuilder.providerTool(
      AnthropicProviderTools.codeExecution(toolType: toolType),
    );
    return this;
  }

  /// Enables Anthropic provider-native computer use (client-executed tool).
  ///
  /// Note: You must provide local tool handlers for `computer` tool calls.
  AnthropicBuilder computerTool({
    String toolType = 'computer_20250124',
    required AnthropicComputerToolOptions options,
  }) {
    _baseBuilder.providerTool(
      AnthropicProviderTools.computer(toolType: toolType, options: options),
    );
    return this;
  }

  /// Enables Anthropic provider-native text editor (client-executed tool).
  ///
  /// Note: You must provide local tool handlers for `str_replace_editor` or
  /// `str_replace_based_edit_tool` tool calls (depending on tool version).
  AnthropicBuilder textEditorTool({
    String toolType = 'text_editor_20250728',
    AnthropicTextEditorToolOptions? options,
  }) {
    _baseBuilder.providerTool(
      AnthropicProviderTools.textEditor(toolType: toolType, options: options),
    );
    return this;
  }

  /// Enables Anthropic provider-native bash (client-executed tool).
  ///
  /// Note: You must provide local tool handlers for `bash` tool calls.
  AnthropicBuilder bashTool({
    String toolType = 'bash_20250124',
  }) {
    _baseBuilder.providerTool(
      AnthropicProviderTools.bash(toolType: toolType),
    );
    return this;
  }

  /// Enables Anthropic provider-native memory (client-executed tool).
  ///
  /// Note: You must provide local tool handlers for `memory` tool calls.
  AnthropicBuilder memoryTool({
    String toolType = 'memory_20250818',
  }) {
    _baseBuilder.providerTool(
      AnthropicProviderTools.memory(toolType: toolType),
    );
    return this;
  }

  /// Enables Anthropic provider-native tool search (regex) (server tool).
  AnthropicBuilder toolSearchRegexTool({
    String toolType = 'tool_search_regex_20251119',
  }) {
    _baseBuilder.providerTool(
      AnthropicProviderTools.toolSearchRegex(toolType: toolType),
    );
    return this;
  }

  /// Enables Anthropic provider-native tool search (BM25) (server tool).
  AnthropicBuilder toolSearchBm25Tool({
    String toolType = 'tool_search_bm25_20251119',
  }) {
    _baseBuilder.providerTool(
      AnthropicProviderTools.toolSearchBm25(toolType: toolType),
    );
    return this;
  }
}
