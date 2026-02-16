library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/web_search_context_size.dart';

/// Typed factories for Azure OpenAI provider-native tools (Responses API built-ins).
///
/// Azure OpenAI shares the OpenAI Responses API wire format, but uses a distinct
/// provider id (`azure`). Stable ids therefore use the `azure.` prefix for
/// AI SDK parity (e.g. `azure.web_search_preview`).
class AzureOpenAIProviderTools {
  static const String _prefix = 'azure.';

  /// Azure/OpenAI web search preview tool (`web_search_preview`).
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

  /// Azure/OpenAI file search tool (`file_search`).
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

  /// Azure/OpenAI code interpreter tool (`code_interpreter`).
  static ProviderTool codeInterpreter({
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

  /// Azure/OpenAI image generation tool (`image_generation`).
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
}
