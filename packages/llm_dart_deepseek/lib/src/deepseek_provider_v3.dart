import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../defaults.dart';
import '../config.dart';
import '../provider.dart';

class DeepSeekProviderSettings {
  final Object? apiKey;
  final String? baseUrl;
  final Map<String, String>? headers;
  final Duration? timeout;

  /// Optional provider constructor override (useful for tests).
  final DeepSeekProvider Function(DeepSeekConfig config)? providerFactory;

  const DeepSeekProviderSettings({
    this.apiKey,
    this.baseUrl,
    this.headers,
    this.timeout,
    this.providerFactory,
  });
}

/// DeepSeek provider factory (AI SDK v3 style).
///
/// Mirrors the upstream `@ai-sdk/deepseek` shape:
/// - `createDeepSeek(...)` returns a callable provider object
/// - calling the provider with a model id returns a language model
class DeepSeekProviderV3 with ProviderV3Defaults implements ProviderV3 {
  final DeepSeekProviderSettings settings;

  const DeepSeekProviderV3(this.settings);

  DeepSeekProvider call(String modelId) =>
      languageModel(modelId) as DeepSeekProvider;

  DeepSeekConfig _configForModel(String modelId) {
    final apiKey = loadApiKey(
      apiKey: settings.apiKey,
      apiKeyParameterName: 'apiKey',
      environmentVariableName: 'DEEPSEEK_API_KEY',
      description: 'DeepSeek',
    );

    final baseUrl =
        withoutTrailingSlash(settings.baseUrl) ??
        withoutTrailingSlash(deepseekBaseUrl)!;

    final providerOptions = <String, Map<String, dynamic>>{
      if (settings.headers != null && settings.headers!.isNotEmpty)
        'deepseek': {
          'headers': settings.headers,
        },
    };

    return DeepSeekConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: modelId,
      timeout: settings.timeout,
      originalConfig: LLMConfig(
        apiKey: apiKey,
        baseUrl: baseUrl,
        model: modelId,
        timeout: settings.timeout,
        providerOptions: providerOptions.isEmpty ? const {} : providerOptions,
      ),
    );
  }

  DeepSeekProvider _newProvider(DeepSeekConfig config) {
    final factory = settings.providerFactory;
    if (factory == null) return DeepSeekProvider(config);
    return factory(config);
  }

  @override
  ChatCapability languageModel(String modelId) {
    final config = _configForModel(modelId);
    return _newProvider(config);
  }
}
