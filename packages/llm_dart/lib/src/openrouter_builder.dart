import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// OpenRouter-specific LLM builder with provider-specific configuration methods.
///
/// This wrapper is provided by the **umbrella** `llm_dart` package. Provider
/// subpackages do not depend on `llm_dart_builder`.
class OpenRouterBuilder {
  final LLMBuilder _baseBuilder;

  OpenRouterBuilder(this._baseBuilder);

  OpenRouterBuilder webSearch({
    int maxResults = 5,
    String? searchPrompt,
    bool useOnlineShortcut = true,
  }) {
    final webSearch = <String, dynamic>{
      'enabled': true,
      'max_results': maxResults,
      if (searchPrompt != null && searchPrompt.trim().isNotEmpty)
        'search_prompt': searchPrompt,
      'strategy': 'plugin',
      'search_type': 'web',
    };

    _baseBuilder.providerOption('openrouter', 'webSearch', webSearch);
    _baseBuilder.providerOption('openrouter', 'webSearchEnabled', true);
    _baseBuilder.providerOption(
        'openrouter', 'useOnlineShortcut', useOnlineShortcut);
    return this;
  }

  OpenRouterBuilder searchPrompt(String prompt) {
    final current = _currentWebSearchJson() ?? const <String, dynamic>{};
    final updated = <String, dynamic>{
      ...current,
      'enabled': true,
      'search_prompt': prompt,
    };
    _baseBuilder.providerOption('openrouter', 'webSearch', updated);
    _baseBuilder.providerOption('openrouter', 'webSearchEnabled', true);
    return this;
  }

  @Deprecated(
    'LLM Dart does not rewrite models automatically. '
    'Set `:online` explicitly in the model string if needed.',
  )
  OpenRouterBuilder useOnlineShortcut(bool enabled) {
    _baseBuilder.providerOption('openrouter', 'useOnlineShortcut', enabled);
    return this;
  }

  OpenRouterBuilder maxSearchResults(int maxResults) {
    final current = _currentWebSearchJson() ?? const <String, dynamic>{};
    final updated = <String, dynamic>{
      ...current,
      'enabled': true,
      'max_results': maxResults,
    };
    _baseBuilder.providerOption('openrouter', 'webSearch', updated);
    _baseBuilder.providerOption('openrouter', 'webSearchEnabled', true);
    return this;
  }

  Map<String, dynamic>? _currentWebSearchJson() {
    final raw = _baseBuilder.currentConfig.getProviderOption<dynamic>(
      'openrouter',
      'webSearch',
    );
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<ChatCapability> build() async => _baseBuilder.build();
}
