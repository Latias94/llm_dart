library;

import 'package:llm_dart_core/llm_dart_core.dart';

/// Typed factories for Groq provider-native tools.
///
/// These tools are **provider-executed** (server-side) and are represented as
/// [ProviderTool] in `LLMConfig.providerTools`.
class GroqProviderTools {
  static const String _prefix = 'groq.';

  /// Groq browser search tool.
  ///
  /// This tool is only supported on select Groq models.
  static ProviderTool browserSearch() => const ProviderTool(
        id: '${_prefix}browser_search',
        name: 'browser_search',
      );
}
