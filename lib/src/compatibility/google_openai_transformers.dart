import '../../core/config.dart';
import 'config/legacy_config_keys.dart';
import 'config/legacy_provider_options.dart';
import 'openai_compatible_provider_config.dart';

/// Google-specific request body transformer for OpenAI-compatible interface
///
/// This transformer handles Google Gemini's specific thinking/reasoning
/// parameters when using the legacy OpenAI-compatible alias.
class GoogleRequestBodyTransformer implements RequestBodyTransformer {
  const GoogleRequestBodyTransformer();

  @override
  Map<String, dynamic> transform(
    Map<String, dynamic> body,
    LLMConfig config,
    OpenAICompatibleProviderConfig providerConfig,
  ) {
    final transformedBody = Map<String, dynamic>.from(body);

    _addThinkingConfig(transformedBody, config);
    _addReasoningEffort(transformedBody, config);

    return transformedBody;
  }

  void _addThinkingConfig(Map<String, dynamic> body, LLMConfig config) {
    final reasoning = getLegacyProviderOption<bool>(
          config,
          LegacyProviderOptionNamespaces.google,
          LegacyExtensionKeys.reasoning,
        ) ??
        false;
    final includeThoughts = getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.google,
      LegacyExtensionKeys.includeThoughts,
    );
    final thinkingBudgetTokens = getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.google,
      LegacyExtensionKeys.thinkingBudgetTokens,
    );

    if (reasoning || includeThoughts != null || thinkingBudgetTokens != null) {
      final extraBody = body['extra_body'] as Map<String, dynamic>? ?? {};
      final configSection = extraBody['config'] as Map<String, dynamic>? ?? {};
      final thinkingConfig = <String, dynamic>{};

      if (includeThoughts != null) {
        thinkingConfig['includeThoughts'] = includeThoughts;
      } else if (reasoning) {
        thinkingConfig['includeThoughts'] = true;
      }

      if (thinkingBudgetTokens != null) {
        thinkingConfig['thinkingBudget'] = thinkingBudgetTokens;
      }

      if (thinkingConfig.isNotEmpty) {
        configSection['thinkingConfig'] = thinkingConfig;
        body['extra_body'] = extraBody;
      }
    }
  }

  void _addReasoningEffort(Map<String, dynamic> body, LLMConfig config) {
    final reasoningEffortString = getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.google,
      LegacyExtensionKeys.reasoningEffort,
    );
    if (reasoningEffortString != null && reasoningEffortString.isNotEmpty) {
      final extraBody = body['extra_body'] as Map<String, dynamic>? ?? {};
      extraBody['reasoning_effort'] = reasoningEffortString;
      body['extra_body'] = extraBody;
    }
  }
}

/// Google-specific headers transformer for OpenAI-compatible interface.
class GoogleHeadersTransformer implements HeadersTransformer {
  const GoogleHeadersTransformer();

  @override
  Map<String, String> transform(
    Map<String, String> headers,
    LLMConfig config,
    OpenAICompatibleProviderConfig providerConfig,
  ) {
    final transformedHeaders = Map<String, String>.from(headers);

    _addThinkingHeaders(transformedHeaders, config);

    return transformedHeaders;
  }

  void _addThinkingHeaders(Map<String, String> headers, LLMConfig config) {
    final reasoning = getLegacyProviderOption<bool>(
          config,
          LegacyProviderOptionNamespaces.google,
          LegacyExtensionKeys.reasoning,
        ) ??
        false;
    final includeThoughts = getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.google,
      LegacyExtensionKeys.includeThoughts,
    );

    if (reasoning || includeThoughts == true) {
      headers['X-Goog-Include-Thoughts'] = 'true';
    }
  }
}

/// Factory for creating Google OpenAI-compatible transformers.
class GoogleTransformers {
  static RequestBodyTransformer createRequestBodyTransformer() {
    return const GoogleRequestBodyTransformer();
  }

  static HeadersTransformer createHeadersTransformer() {
    return const GoogleHeadersTransformer();
  }

  static (RequestBodyTransformer, HeadersTransformer) createTransformers() {
    return (
      createRequestBodyTransformer(),
      createHeadersTransformer(),
    );
  }
}
