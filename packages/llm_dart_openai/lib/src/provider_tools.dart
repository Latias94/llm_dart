library;

import 'package:llm_dart_core/llm_dart_core.dart';

import 'package:llm_dart_openai_compatible/web_search_context_size.dart';

/// Typed factories for OpenAI provider-native tools (Responses API built-ins).
///
/// These tools are represented as [ProviderTool] in `LLMConfig.providerTools`.
///
/// Note: Some OpenAI "provider-native" tools are client-executed (e.g. `shell`,
/// `local_shell`, `apply_patch`). The OpenAI Responses streaming parser marks
/// these as `providerExecuted=false` so tool loops can execute them locally.
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

  /// OpenAI web search preview tool (`web_search_preview`).
  ///
  /// Mirrors Vercel AI SDK `openaiTools.webSearchPreview(...)`:
  /// - tool id: `openai.web_search_preview`
  /// - canonical tool name: `webSearch`
  static ProviderTool webSearchPreview({
    OpenAIWebSearchContextSize? contextSize,
    Map<String, dynamic>? userLocation,
  }) {
    return ProviderTool(
      id: '${_prefix}web_search_preview',
      name: 'webSearch',
      options: {
        if (contextSize != null) 'searchContextSize': contextSize.apiValue,
        if (userLocation != null && userLocation.isNotEmpty)
          'userLocation': userLocation,
      },
    );
  }

  /// Back-compat alias for older code paths in this repo.
  @Deprecated('Use webSearchPreview(...) for `web_search_preview`.')
  static ProviderTool webSearch({OpenAIWebSearchContextSize? contextSize}) =>
      webSearchPreview(contextSize: contextSize);

  /// OpenAI web search tool (`web_search`).
  ///
  /// Mirrors Vercel AI SDK `openaiTools.webSearch(...)`.
  static ProviderTool webSearchFull({
    List<String>? allowedDomains,
    bool? externalWebAccess,
    OpenAIWebSearchContextSize? contextSize,
    Map<String, dynamic>? userLocation,
    Map<String, dynamic>? parameters,
  }) {
    return ProviderTool(
      id: '${_prefix}web_search',
      name: 'webSearch',
      options: {
        if (externalWebAccess != null) 'externalWebAccess': externalWebAccess,
        if (allowedDomains != null && allowedDomains.isNotEmpty)
          'filters': {'allowedDomains': allowedDomains},
        if (contextSize != null) 'searchContextSize': contextSize.apiValue,
        if (userLocation != null && userLocation.isNotEmpty)
          'userLocation': userLocation,
        ...?parameters,
      },
    );
  }

  /// Vercel-style name alias.
  static ProviderTool webSearchFullTool({
    List<String>? allowedDomains,
    bool? externalWebAccess,
    OpenAIWebSearchContextSize? contextSize,
    Map<String, dynamic>? userLocation,
    Map<String, dynamic>? parameters,
  }) =>
      webSearchFull(
        allowedDomains: allowedDomains,
        externalWebAccess: externalWebAccess,
        contextSize: contextSize,
        userLocation: userLocation,
        parameters: parameters,
      );

  /// Vercel-style name alias for `web_search`.
  static ProviderTool webSearchTool({
    List<String>? allowedDomains,
    bool? externalWebAccess,
    OpenAIWebSearchContextSize? contextSize,
    Map<String, dynamic>? userLocation,
    Map<String, dynamic>? parameters,
  }) =>
      webSearchFull(
        allowedDomains: allowedDomains,
        externalWebAccess: externalWebAccess,
        contextSize: contextSize,
        userLocation: userLocation,
        parameters: parameters,
      );

  static ProviderTool fileSearch({
    List<String>? vectorStoreIds,
    int? maxNumResults,
    Map<String, dynamic>? ranking,
    Object? filters,
    Map<String, dynamic>? parameters,
  }) {
    return ProviderTool(
      id: '${_prefix}file_search',
      name: 'fileSearch',
      options: {
        if (vectorStoreIds != null && vectorStoreIds.isNotEmpty)
          'vectorStoreIds': vectorStoreIds,
        if (maxNumResults != null) 'maxNumResults': maxNumResults,
        if (ranking != null && ranking.isNotEmpty) 'ranking': ranking,
        if (filters != null) 'filters': filters,
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
      name: 'computerUse',
      options: {
        'displayWidth': displayWidth,
        'displayHeight': displayHeight,
        'environment': environment,
        ...?parameters,
      },
    );
  }

  static ProviderTool codeInterpreter({
    /// Container configuration for the code interpreter.
    ///
    /// Mirrors Vercel AI SDK:
    /// - `String` container id, or
    /// - `{ "fileIds": [...] }` to attach uploaded files.
    Object? container,
    Map<String, dynamic>? parameters,
  }) {
    return ProviderTool(
      id: '${_prefix}code_interpreter',
      name: 'codeExecution',
      supportsDeferredResults: true,
      options: {
        if (container != null) 'container': container,
        ...?parameters,
      },
    );
  }

  static ProviderTool imageGeneration({
    String? background,
    String? inputFidelity,
    Map<String, dynamic>? inputImageMask,
    String? model,
    String? moderation,
    int? partialImages,
    String? quality,
    int? outputCompression,
    String? outputFormat,
    String? size,
    Map<String, dynamic>? parameters,
  }) {
    return ProviderTool(
      id: '${_prefix}image_generation',
      name: 'generateImage',
      options: {
        if (background != null) 'background': background,
        if (inputFidelity != null) 'inputFidelity': inputFidelity,
        if (inputImageMask != null && inputImageMask.isNotEmpty)
          'inputImageMask': inputImageMask,
        if (model != null) 'model': model,
        if (moderation != null) 'moderation': moderation,
        if (partialImages != null) 'partialImages': partialImages,
        if (quality != null) 'quality': quality,
        if (outputCompression != null) 'outputCompression': outputCompression,
        if (outputFormat != null) 'outputFormat': outputFormat,
        if (size != null) 'size': size,
        ...?parameters,
      },
    );
  }

  static ProviderTool mcp({
    String? serverLabel,
    Object? allowedTools,
    String? authorization,
    String? connectorId,
    Map<String, dynamic>? headers,
    Object? requireApproval,
    String? serverDescription,
    String? serverUrl,
    Map<String, dynamic>? parameters,
  }) {
    return ProviderTool(
      id: '${_prefix}mcp',
      name: 'mcp',
      options: {
        if (serverLabel != null) 'serverLabel': serverLabel,
        if (allowedTools != null) 'allowedTools': allowedTools,
        if (authorization != null) 'authorization': authorization,
        if (connectorId != null) 'connectorId': connectorId,
        if (headers != null && headers.isNotEmpty) 'headers': headers,
        if (requireApproval != null) 'requireApproval': requireApproval,
        if (serverDescription != null) 'serverDescription': serverDescription,
        if (serverUrl != null) 'serverUrl': serverUrl,
        ...?parameters,
      },
    );
  }

  static ProviderTool applyPatch() =>
      const ProviderTool(id: '${_prefix}apply_patch', name: 'apply_patch');

  static ProviderTool shell() =>
      const ProviderTool(id: '${_prefix}shell', name: 'shell');

  static ProviderTool localShell() =>
      const ProviderTool(id: '${_prefix}local_shell', name: 'shell');
}
