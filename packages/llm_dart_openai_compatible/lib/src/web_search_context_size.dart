/// OpenAI provider-native web search context size.
///
/// This corresponds to the `search_context_size` parameter for the
/// `web_search_preview` built-in tool in the Responses API.
library;

enum OpenAIWebSearchContextSize {
  low('low'),
  medium('medium'),
  high('high');

  final String apiValue;
  const OpenAIWebSearchContextSize(this.apiValue);

  static OpenAIWebSearchContextSize? tryParse(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final v in values) {
      if (v.apiValue == normalized) return v;
    }
    return null;
  }
}
