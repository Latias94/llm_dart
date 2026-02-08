library;

import 'package:llm_dart_core/llm_dart_core.dart';

import 'file_search_tool_options.dart';
import 'mcp_tool_options.dart';
import 'web_search_tool_options.dart';
import 'x_search_tool_options.dart';

/// Typed factories for xAI provider-native tools (Responses API built-ins).
///
/// These tools are **provider-executed** (server-side) and are represented as
/// [ProviderTool] in `LLMConfig.providerTools`.
///
/// Stable ids follow the Vercel-style convention:
/// - `xai.web_search`
/// - `xai.x_search`
/// - `xai.code_execution`
/// - `xai.view_image`
/// - `xai.view_x_video`
/// - `xai.file_search`
/// - `xai.mcp`
class XAIProviderTools {
  static const String _prefix = 'xai.';

  static ProviderTool webSearch({
    XAIWebSearchToolOptions? options,
    Map<String, dynamic>? parameters,
  }) {
    return ProviderTool(
      id: '${_prefix}web_search',
      options: {
        ...?options?.toJson(),
        ...?parameters,
      },
    );
  }

  static ProviderTool xSearch({
    XAIXSearchToolOptions? options,
    Map<String, dynamic>? parameters,
  }) {
    return ProviderTool(
      id: '${_prefix}x_search',
      options: {
        ...?options?.toJson(),
        ...?parameters,
      },
    );
  }

  static ProviderTool codeExecution() =>
      const ProviderTool(id: '${_prefix}code_execution', options: {});

  static ProviderTool viewImage() =>
      const ProviderTool(id: '${_prefix}view_image', options: {});

  static ProviderTool viewXVideo() =>
      const ProviderTool(id: '${_prefix}view_x_video', options: {});

  static ProviderTool fileSearch({
    XAIFileSearchToolOptions? options,
    Map<String, dynamic>? parameters,
  }) {
    return ProviderTool(
      id: '${_prefix}file_search',
      options: {
        ...?options?.toJson(),
        ...?parameters,
      },
    );
  }

  static ProviderTool mcp({
    XAIMcpToolOptions? options,
    Map<String, dynamic>? parameters,
  }) {
    return ProviderTool(
      id: '${_prefix}mcp',
      options: {
        ...?options?.toJson(),
        ...?parameters,
      },
    );
  }
}
