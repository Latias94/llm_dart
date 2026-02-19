library;

import 'package:llm_dart_core/llm_dart_core.dart';

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
      name: 'google_search',
      args: {
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
      name: 'code_execution',
      supportsDeferredResults: true,
    );
  }

  /// Enables Gemini URL context as a provider-native tool.
  ///
  /// This tool is only supported for Gemini 2.0+ models.
  static ProviderTool urlContext() {
    return const ProviderTool(
      id: 'google.url_context',
      name: 'url_context',
    );
  }

  /// Enables Gemini enterprise web search as a provider-native tool.
  ///
  /// This tool is only supported for Gemini 2.0+ models.
  static ProviderTool enterpriseWebSearch() {
    return const ProviderTool(
      id: 'google.enterprise_web_search',
      name: 'enterprise_web_search',
    );
  }

  /// Enables Gemini Google Maps grounding as a provider-native tool.
  ///
  /// This tool is only supported for Gemini 2.0+ models.
  static ProviderTool googleMaps() {
    return const ProviderTool(
      id: 'google.google_maps',
      name: 'google_maps',
    );
  }

  /// Enables Gemini file search as a provider-native tool.
  ///
  /// This tool is only supported for Gemini 2.5 models and Gemini 3 models.
  static ProviderTool fileSearch({
    required List<String> fileSearchStoreNames,
    String? metadataFilter,
    int? topK,
  }) {
    return ProviderTool(
      id: 'google.file_search',
      name: 'file_search',
      args: {
        'fileSearchStoreNames': fileSearchStoreNames,
        if (metadataFilter != null) 'metadataFilter': metadataFilter,
        if (topK != null) 'topK': topK,
      },
    );
  }

  /// Enables Vertex RAG store retrieval tool (provider-native).
  ///
  /// This tool is only supported for Gemini 2.0+ models.
  static ProviderTool vertexRagStore({
    required String ragCorpus,
    int? topK,
  }) {
    return ProviderTool(
      id: 'google.vertex_rag_store',
      name: 'vertex_rag_store',
      args: {
        'ragCorpus': ragCorpus,
        if (topK != null) 'topK': topK,
      },
    );
  }
}
