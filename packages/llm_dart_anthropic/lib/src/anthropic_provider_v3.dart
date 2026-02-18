import 'package:llm_dart_anthropic_compatible/config.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../defaults.dart';
import '../provider.dart';

class AnthropicProviderSettings {
  final Object? apiKey;
  final Object? baseUrl;
  final Map<String, String>? headers;
  final Duration? timeout;

  /// Provider id used in `providerMetadata` namespaces and provider options.
  ///
  /// Defaults to `anthropic`. Use a custom id for Anthropic-compatible proxies.
  final String name;

  /// Optional provider constructor override (useful for tests).
  final AnthropicProvider Function(AnthropicConfig config)? providerFactory;

  const AnthropicProviderSettings({
    required this.apiKey,
    this.baseUrl,
    this.headers,
    this.timeout,
    this.name = 'anthropic',
    this.providerFactory,
  });
}

/// Anthropic provider factory (AI SDK v3 style).
///
/// Mirrors the upstream `@ai-sdk/anthropic` shape:
/// - `createAnthropic(...)` returns a callable provider object
/// - calling the provider with a model id returns a language model
class AnthropicProviderV3 with ProviderV3Defaults implements ProviderV3 {
  final AnthropicProviderSettings settings;

  const AnthropicProviderV3(this.settings);

  AnthropicProvider call(String modelId) =>
      languageModel(modelId) as AnthropicProvider;

  AnthropicConfig _configForModel(String modelId) {
    final apiKey = loadApiKey(
      apiKey: settings.apiKey,
      apiKeyParameterName: 'apiKey',
      environmentVariableName: 'ANTHROPIC_API_KEY',
      description: 'Anthropic',
    );

    final baseUrl =
        withoutTrailingSlash(
          loadOptionalSetting(
            settingValue: settings.baseUrl,
            environmentVariableName: 'ANTHROPIC_BASE_URL',
          ),
        ) ??
        withoutTrailingSlash(anthropicBaseUrl)!;

    final name = settings.name.trim();

    return AnthropicConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: modelId,
      providerId: name.isEmpty ? 'anthropic' : name,
      extraHeaders: settings.headers,
      timeout: settings.timeout,
    );
  }

  AnthropicProvider _newProvider(AnthropicConfig config) {
    final factory = settings.providerFactory;
    if (factory == null) return AnthropicProvider(config);
    return factory(config);
  }

  @override
  ChatCapability languageModel(String modelId) => _newProvider(
        _configForModel(modelId),
      );
}
