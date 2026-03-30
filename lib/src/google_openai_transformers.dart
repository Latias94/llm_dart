import '../core/config.dart';

/// Google-specific request body transformer for OpenAI-compatible interface
///
/// This transformer handles Google Gemini's specific thinking/reasoning parameters
/// when using the OpenAI-compatible interface, ensuring proper configuration
/// without modifying the core OpenAI provider.
class GoogleRequestBodyTransformer implements RequestBodyTransformer {
  const GoogleRequestBodyTransformer();

  @override
  Map<String, dynamic> transform(
    Map<String, dynamic> body,
    LLMConfig config,
    OpenAICompatibleProviderConfig providerConfig,
  ) {
    final transformedBody = Map<String, dynamic>.from(body);

    // Handle Google-specific thinking configuration
    _addThinkingConfig(transformedBody, config);

    // Handle Google-specific reasoning effort mapping
    _addReasoningEffort(transformedBody, config);

    return transformedBody;
  }

  /// Add Google-specific thinking configuration to request body
  void _addThinkingConfig(Map<String, dynamic> body, LLMConfig config) {
    // Check if reasoning is enabled or thinking parameters are set
    final reasoning = config.getExtension<bool>('reasoning') ?? false;
    final includeThoughts = config.getExtension<bool>('includeThoughts');
    final thinkingBudgetTokens =
        config.getExtension<int>('thinkingBudgetTokens');

    if (reasoning || includeThoughts != null || thinkingBudgetTokens != null) {
      // For Google's OpenAI-compatible interface, thinking config goes in config.thinkingConfig
      final extraBody = body['extra_body'] as Map<String, dynamic>? ?? {};
      final configSection = extraBody['config'] as Map<String, dynamic>? ?? {};
      final thinkingConfig = <String, dynamic>{};

      // Include thoughts in response (for getting thinking summaries)
      if (includeThoughts != null) {
        thinkingConfig['includeThoughts'] = includeThoughts;
      } else if (reasoning) {
        // Auto-enable for reasoning
        thinkingConfig['includeThoughts'] = true;
      }

      // Set thinking budget (token limit for thinking)
      if (thinkingBudgetTokens != null) {
        thinkingConfig['thinkingBudget'] = thinkingBudgetTokens;
      }

      if (thinkingConfig.isNotEmpty) {
        configSection['thinkingConfig'] = thinkingConfig;
        // extraBody['config'] = configSection;
        body['extra_body'] = extraBody;
      }
    }
  }

  /// Add Google-specific reasoning effort mapping
  void _addReasoningEffort(Map<String, dynamic> body, LLMConfig config) {
    // Get reasoning effort as string (stored by LLMBuilder.reasoningEffort())
    final reasoningEffortString =
        config.getExtension<String>('reasoningEffort');
    if (reasoningEffortString != null && reasoningEffortString.isNotEmpty) {
      // For Google's OpenAI-compatible interface, reasoning effort goes in extra_body
      final extraBody = body['extra_body'] as Map<String, dynamic>? ?? {};
      extraBody['reasoning_effort'] = reasoningEffortString;
      body['extra_body'] = extraBody;
    }
  }
}

/// Google-specific headers transformer for OpenAI-compatible interface
///
/// This transformer handles Google Gemini's specific headers when using
/// the OpenAI-compatible interface.
class GoogleHeadersTransformer implements HeadersTransformer {
  const GoogleHeadersTransformer();

  @override
  Map<String, String> transform(
    Map<String, String> headers,
    LLMConfig config,
    OpenAICompatibleProviderConfig providerConfig,
  ) {
    final transformedHeaders = Map<String, String>.from(headers);

    // Google Gemini OpenAI-compatible API uses standard Bearer token authentication
    // The Authorization header is correctly set by the OpenAI headers builder

    // Add Google-specific thinking headers if needed
    _addThinkingHeaders(transformedHeaders, config);

    return transformedHeaders;
  }

  /// Add Google-specific thinking headers
  void _addThinkingHeaders(Map<String, String> headers, LLMConfig config) {
    final reasoning = config.getExtension<bool>('reasoning') ?? false;
    final includeThoughts = config.getExtension<bool>('includeThoughts');

    // Add thinking-related headers if reasoning is enabled
    if (reasoning || includeThoughts == true) {
      // Google may require specific headers for thinking functionality
      // This can be extended based on Google's API requirements
      headers['X-Goog-Include-Thoughts'] = 'true';
    }

    // Note: Streaming thinking headers are now handled at method call time
    // since stream parameter has been removed from config
  }
}

/// Factory for creating Google transformers
class GoogleTransformers {
  /// Create request body transformer for Google
  static RequestBodyTransformer createRequestBodyTransformer() {
    return const GoogleRequestBodyTransformer();
  }

  /// Create headers transformer for Google
  static HeadersTransformer createHeadersTransformer() {
    return const GoogleHeadersTransformer();
  }

  /// Create both transformers for Google
  static (RequestBodyTransformer, HeadersTransformer) createTransformers() {
    return (
      createRequestBodyTransformer(),
      createHeadersTransformer(),
    );
  }
}
