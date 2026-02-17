import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// OpenRouter-specific LLM builder with provider-specific configuration methods.
///
/// This wrapper is provided by the **umbrella** `llm_dart` package. Provider
/// subpackages do not depend on `llm_dart_builder`.
class OpenRouterBuilder {
  final LLMBuilder _baseBuilder;

  OpenRouterBuilder(this._baseBuilder);

  /// Set OpenRouter recommended request headers for attribution/rate limiting.
  ///
  /// OpenRouter's docs recommend setting `HTTP-Referer` and `X-Title`.
  OpenRouterBuilder appInfo({
    required String referer,
    required String title,
  }) {
    httpReferer(referer);
    xTitle(title);
    return this;
  }

  /// Set the `HTTP-Referer` header (OpenRouter recommended).
  OpenRouterBuilder httpReferer(String referer) {
    final updated = <String, String>{
      ...?_currentHeaders(),
      'HTTP-Referer': referer,
    };
    _baseBuilder.providerOption('openrouter', 'headers', updated);
    return this;
  }

  /// Set the `X-Title` header (OpenRouter recommended).
  OpenRouterBuilder xTitle(String title) {
    final updated = <String, String>{
      ...?_currentHeaders(),
      'X-Title': title,
    };
    _baseBuilder.providerOption('openrouter', 'headers', updated);
    return this;
  }

  Map<String, String>? _currentHeaders() {
    final raw = _baseBuilder.currentConfig.getProviderOption<dynamic>(
      'openrouter',
      'headers',
    );
    if (raw is Map<String, String>) return Map<String, String>.from(raw);
    if (raw is Map) {
      final result = <String, String>{};
      for (final entry in raw.entries) {
        final key = entry.key?.toString();
        final value = entry.value?.toString();
        if (key == null || key.trim().isEmpty) continue;
        if (value == null) continue;
        result[key] = value;
      }
      return result.isEmpty ? null : result;
    }
    return null;
  }

  Future<ChatCapability> build() async => _baseBuilder.build();
}
