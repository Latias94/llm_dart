library;

import 'package:llm_dart_core/models/tool_models.dart';

import 'web_search_context_size.dart';

/// Typed factories for OpenAI provider-native tools (Responses API built-ins).
///
/// These tools are **provider-executed** (server-side) and are represented as
/// [ProviderTool] in `LLMConfig.providerTools`.
///
/// Stable ids follow the Vercel-style convention:
/// - `openai.web_search_preview`
/// - `openai.file_search`
/// - `openai.computer_use_preview`
class OpenAIProviderTools {
  static const String _prefix = 'openai.';

  static ProviderTool webSearch({OpenAIWebSearchContextSize? contextSize}) {
    return ProviderTool(
      id: '${_prefix}web_search_preview',
      options: {
        if (contextSize != null) 'search_context_size': contextSize.apiValue,
      },
    );
  }

  static ProviderTool fileSearch({
    List<String>? vectorStoreIds,
    Map<String, dynamic>? parameters,
  }) {
    return ProviderTool(
      id: '${_prefix}file_search',
      options: {
        if (vectorStoreIds != null && vectorStoreIds.isNotEmpty)
          'vector_store_ids': vectorStoreIds,
        ...?parameters,
      },
    );
  }

  static ProviderTool computerUse({
    required int displayWidth,
    required int displayHeight,
    required String environment,
    Map<String, dynamic>? parameters,
  }) {
    return ProviderTool(
      id: '${_prefix}computer_use_preview',
      options: {
        'display_width': displayWidth,
        'display_height': displayHeight,
        'environment': environment,
        ...?parameters,
      },
    );
  }
}
