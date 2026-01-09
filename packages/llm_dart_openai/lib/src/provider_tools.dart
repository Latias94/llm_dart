library;

import 'package:llm_dart_core/llm_dart_core.dart';

import 'web_search_context_size.dart';

/// Typed factories for OpenAI provider-native tools (Responses API built-ins).
///
/// These tools are **provider-executed** (server-side) and are represented as
/// [ProviderTool] in `LLMConfig.providerTools`.
///
/// Stable ids follow the Vercel-style convention:
/// - `openai.web_search_preview`
/// - `openai.web_search`
/// - `openai.file_search`
/// - `openai.computer_use`
/// - `openai.code_interpreter`
/// - `openai.image_generation`
/// - `openai.mcp`
/// - `openai.apply_patch`
/// - `openai.shell`
/// - `openai.local_shell`
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

  static ProviderTool webSearchFull({
    List<String>? allowedDomains,
    bool? externalWebAccess,
    OpenAIWebSearchContextSize? contextSize,
    Map<String, dynamic>? userLocation,
    Map<String, dynamic>? parameters,
  }) {
    final options = <String, dynamic>{
      if (allowedDomains != null && allowedDomains.isNotEmpty)
        'filters': {'allowed_domains': allowedDomains},
      if (externalWebAccess != null) 'external_web_access': externalWebAccess,
      if (contextSize != null) 'search_context_size': contextSize.apiValue,
      if (userLocation != null && userLocation.isNotEmpty)
        'user_location': userLocation,
      ...?parameters,
    };

    return ProviderTool(
      id: '${_prefix}web_search',
      options: options,
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
      id: '${_prefix}computer_use',
      options: {
        'display_width': displayWidth,
        'display_height': displayHeight,
        'environment': environment,
        ...?parameters,
      },
    );
  }

  static ProviderTool codeInterpreter({
    dynamic container,
    Map<String, dynamic>? parameters,
  }) {
    return ProviderTool(
      id: '${_prefix}code_interpreter',
      options: {
        if (container != null) 'container': container,
        ...?parameters,
      },
    );
  }

  static ProviderTool imageGeneration({Map<String, dynamic>? parameters}) {
    return ProviderTool(
      id: '${_prefix}image_generation',
      options: {...?parameters},
    );
  }

  static ProviderTool mcp({Map<String, dynamic>? parameters}) {
    return ProviderTool(
      id: '${_prefix}mcp',
      options: {...?parameters},
    );
  }

  static ProviderTool applyPatch() =>
      const ProviderTool(id: '${_prefix}apply_patch');

  static ProviderTool shell() => const ProviderTool(id: '${_prefix}shell');

  static ProviderTool localShell() =>
      const ProviderTool(id: '${_prefix}local_shell');
}
