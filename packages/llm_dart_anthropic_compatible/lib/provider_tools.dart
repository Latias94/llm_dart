library;

import 'package:llm_dart_core/llm_dart_core.dart';

import 'computer_tool_options.dart';
import 'text_editor_tool_options.dart';
import 'web_fetch_tool_options.dart';
import 'web_search_tool_options.dart';

/// Typed factories for Anthropic provider-native tools.
///
/// These tools are **provider-executed** (server-side) and are represented as
/// [ProviderTool] in `LLMConfig.providerTools`.
class AnthropicProviderTools {
  static const String _prefix = 'anthropic.';

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
      id: '$_prefix$normalizedType',
      name: 'web_search',
      supportsDeferredResults: true,
      args: {
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
      id: '$_prefix$normalizedType',
      name: 'web_fetch',
      supportsDeferredResults: true,
      args: {
        ...?options?.toJson(),
        'enabled': true,
      },
    );
  }

  /// Anthropic code execution provider-native tool.
  ///
  /// Common tool types include:
  /// - `code_execution_20250825`
  /// - `code_execution_20250522`
  ///
  /// Anthropic may emit tool names like `bash_code_execution` or
  /// `text_editor_code_execution`; streaming parsers normalize them to
  /// `code_execution`, then resolve the configured tool id via prefix match.
  static ProviderTool codeExecution({
    String toolType = 'code_execution_20250825',
  }) {
    final normalizedType = toolType.startsWith('code_execution_')
        ? toolType
        : 'code_execution_20250825';

    return ProviderTool(
      id: '$_prefix$normalizedType',
      name: 'code_execution',
      supportsDeferredResults: true,
      args: const {'enabled': true},
    );
  }

  /// Anthropic computer use tool (provider-native).
  ///
  /// Tool types include:
  /// - `computer_20241022`
  /// - `computer_20250124`
  /// - `computer_20251124` (supports zoom)
  static ProviderTool computer({
    String toolType = 'computer_20250124',
    required AnthropicComputerToolOptions options,
  }) {
    final normalizedType =
        toolType.startsWith('computer_') ? toolType : 'computer_20250124';

    return ProviderTool(
      id: '$_prefix$normalizedType',
      name: 'computer',
      args: {
        ...options.toJson(),
        'enabled': true,
      },
    );
  }

  /// Anthropic text editor tool (provider-native).
  ///
  /// Tool types include:
  /// - `text_editor_20241022` / `text_editor_20250124` (name: `str_replace_editor`)
  /// - `text_editor_20250429` / `text_editor_20250728` (name: `str_replace_based_edit_tool`)
  static ProviderTool textEditor({
    String toolType = 'text_editor_20250728',
    AnthropicTextEditorToolOptions? options,
  }) {
    final normalizedType =
        toolType.startsWith('text_editor_') ? toolType : 'text_editor_20250728';

    final name = switch (normalizedType) {
      'text_editor_20241022' || 'text_editor_20250124' => 'str_replace_editor',
      _ => 'str_replace_based_edit_tool',
    };

    return ProviderTool(
      id: '$_prefix$normalizedType',
      name: name,
      args: {
        ...?options?.toJson(),
        'enabled': true,
      },
    );
  }

  /// Anthropic bash tool (provider-native).
  static ProviderTool bash({
    String toolType = 'bash_20250124',
  }) {
    final normalizedType =
        toolType.startsWith('bash_') ? toolType : 'bash_20250124';

    return ProviderTool(
      id: '$_prefix$normalizedType',
      name: 'bash',
      args: const {'enabled': true},
    );
  }

  /// Anthropic memory tool (provider-native).
  static ProviderTool memory({
    String toolType = 'memory_20250818',
  }) {
    final normalizedType =
        toolType.startsWith('memory_') ? toolType : 'memory_20250818';

    return ProviderTool(
      id: '$_prefix$normalizedType',
      name: 'memory',
      args: const {'enabled': true},
    );
  }

  /// Anthropic tool search (regex) tool (provider-native).
  ///
  /// Note: The Anthropic request tool name is `tool_search_tool_regex`, while
  /// the stable (v3) tool name is `tool_search` (Vercel AI SDK parity).
  static ProviderTool toolSearchRegex({
    String toolType = 'tool_search_regex_20251119',
  }) {
    final normalizedType = toolType.startsWith('tool_search_regex_')
        ? toolType
        : 'tool_search_regex_20251119';

    return ProviderTool(
      id: '$_prefix$normalizedType',
      name: 'tool_search',
      supportsDeferredResults: true,
      args: const {'enabled': true},
    );
  }

  /// Anthropic tool search (BM25) tool (provider-native).
  ///
  /// Note: The Anthropic request tool name is `tool_search_tool_bm25`, while
  /// the stable (v3) tool name is `tool_search` (Vercel AI SDK parity).
  static ProviderTool toolSearchBm25({
    String toolType = 'tool_search_bm25_20251119',
  }) {
    final normalizedType = toolType.startsWith('tool_search_bm25_')
        ? toolType
        : 'tool_search_bm25_20251119';

    return ProviderTool(
      id: '$_prefix$normalizedType',
      name: 'tool_search',
      supportsDeferredResults: true,
      args: const {'enabled': true},
    );
  }
}
