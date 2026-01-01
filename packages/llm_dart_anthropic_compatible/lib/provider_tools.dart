library;

import 'package:llm_dart_core/llm_dart_core.dart';

import 'web_fetch_tool_options.dart';
import 'web_search_tool_options.dart';

/// Typed factories for Anthropic provider-native tools.
///
/// These tools are **provider-executed** (server-side) and are represented as
/// [ProviderTool] in `LLMConfig.providerTools`.
class AnthropicProviderTools {
  /// Anthropic provider-native web search tool.
  ///
  /// - [toolType] must be an Anthropic server tool type like `web_search_20250305`.
  /// - The stable tool id is `anthropic.<toolType>`.
  static ProviderTool webSearch({
    String toolType = 'web_search_20250305',
    AnthropicWebSearchToolOptions? options,
  }) {
    final normalizedType =
        toolType.startsWith('web_search_') ? toolType : 'web_search_20250305';

    final toolOptions =
        (options ?? const AnthropicWebSearchToolOptions()).toJson();
    return ProviderTool(
      id: 'anthropic.$normalizedType',
      options: {
        ...toolOptions,
        'enabled': true,
      },
    );
  }

  /// Anthropic provider-native web fetch tool.
  ///
  /// - [toolType] must be an Anthropic server tool type like `web_fetch_20250910`.
  /// - The stable tool id is `anthropic.<toolType>`.
  static ProviderTool webFetch({
    String toolType = 'web_fetch_20250910',
    AnthropicWebFetchToolOptions? options,
  }) {
    final normalizedType =
        toolType.startsWith('web_fetch_') ? toolType : 'web_fetch_20250910';

    return ProviderTool(
      id: 'anthropic.$normalizedType',
      options: {
        ...?options?.toJson(),
        'enabled': true,
      },
    );
  }
}
