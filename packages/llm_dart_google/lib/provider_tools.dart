library;

import 'package:llm_dart_core/models/tool_models.dart';

import 'web_search_tool_options.dart';

/// Typed factories for Google Gemini provider-native tools.
///
/// These tools are **provider-executed** (server-side) and are represented as
/// [ProviderTool] in `LLMConfig.providerTools`.
class GoogleProviderTools {
  static ProviderTool webSearch({
    GoogleWebSearchToolOptions? options,
  }) {
    final toolOptions =
        (options ?? const GoogleWebSearchToolOptions()).toJson();
    return ProviderTool(
      id: 'google.google_search',
      options: {
        ...toolOptions,
        'enabled': true,
      },
    );
  }

  /// Enables Gemini code execution as a provider-native tool.
  ///
  /// This tool is only supported for Gemini 2.0+ models.
  static ProviderTool codeExecution() {
    return const ProviderTool(
      id: 'google.code_execution',
      options: {},
    );
  }

  /// Enables Gemini URL context as a provider-native tool.
  ///
  /// This tool is only supported for Gemini 2.0+ models.
  static ProviderTool urlContext() {
    return const ProviderTool(
      id: 'google.url_context',
      options: {},
    );
  }
}
