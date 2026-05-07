part of 'provider_compat.dart';

mixin OpenAIProviderHelpersMixin {
  OpenAIClient get _client;
  OpenAIResponses? get _responses;
  OpenAIProviderSupport get _support;

  /// Get the underlying client for advanced usage.
  OpenAIClient get client => _client;

  /// Get the Responses API module, when `useResponsesAPI` is enabled.
  OpenAIResponses? get responses => _responses;

  /// Get embedding dimensions for the configured model.
  Future<int> getEmbeddingDimensions() async {
    return _support.getEmbeddingDimensions();
  }

  /// Check if a model is valid and accessible.
  Future<({bool valid, String? error})> checkModel() async {
    return _support.checkModel();
  }

  /// Generate suggestions for follow-up questions.
  Future<List<String>> generateSuggestions(List<ChatMessage> messages) async {
    return _support.generateSuggestions(messages);
  }
}
