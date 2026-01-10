import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// OpenAI-compatible provider builder for configuring OpenAI-compatible presets.
///
/// This wrapper is provided by the **umbrella** `llm_dart` package. Provider
/// subpackages do not depend on `llm_dart_builder`.
class OpenAICompatibleBuilder {
  final LLMBuilder _baseBuilder;
  final String _providerId;

  OpenAICompatibleBuilder(this._baseBuilder, this._providerId);

  /// Additional request headers merged into the OpenAI-compatible request.
  ///
  /// This is applied via `LLMConfig.providerOptions[providerId].headers`.
  OpenAICompatibleBuilder headers(Map<String, String> headers) {
    _baseBuilder.providerOption(_providerId, 'headers', headers);
    return this;
  }

  /// Additional request headers merged after `headers` (override).
  OpenAICompatibleBuilder extraHeaders(Map<String, String> headers) {
    _baseBuilder.providerOption(_providerId, 'extraHeaders', headers);
    return this;
  }

  /// Additional URL query parameters appended to all requests.
  OpenAICompatibleBuilder queryParams(Map<String, String> queryParams) {
    _baseBuilder.providerOption(_providerId, 'queryParams', queryParams);
    return this;
  }

  /// Optional path prefix inserted before every endpoint path.
  ///
  /// Example: DeepInfra mounts OpenAI routes under `/openai/*`.
  OpenAICompatibleBuilder endpointPrefix(String prefix) {
    _baseBuilder.providerOption(_providerId, 'endpointPrefix', prefix);
    return this;
  }

  /// Include usage information for streaming responses.
  OpenAICompatibleBuilder includeUsage([bool enabled = true]) {
    _baseBuilder.providerOption(_providerId, 'includeUsage', enabled);
    return this;
  }

  /// Whether the provider supports structured outputs.
  OpenAICompatibleBuilder supportsStructuredOutputs([bool enabled = true]) {
    _baseBuilder.providerOption(
        _providerId, 'supportsStructuredOutputs', enabled);
    return this;
  }

  Future<ChatCapability> build() => _baseBuilder.build();
}
