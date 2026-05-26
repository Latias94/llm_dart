import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_api.dart';
import 'anthropic_files.dart';
import 'anthropic_language_model.dart';
import 'anthropic_model_settings.dart';
import 'anthropic_provider_descriptor.dart';

/// Creates an Anthropic provider facade.
Anthropic anthropic({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return Anthropic(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

final class Anthropic implements LanguageModelProvider {
  static const String defaultBaseUrl = anthropicDefaultBaseUrl;

  final String apiKey;
  final String baseUrl;
  final TransportClient transport;

  Anthropic({
    required this.apiKey,
    TransportClient? transport,
    String? baseUrl,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        transport = transport ?? DioTransportClient();

  @override
  String get providerId => providerDescriptor.providerId;

  AnthropicProviderDescriptor get providerDescriptor =>
      const AnthropicProviderDescriptor();

  @override
  ProviderSpecification get specification => providerDescriptor.specification;

  @override
  AnthropicLanguageModel languageModel(
    String modelId, {
    AnthropicChatModelSettings settings = const AnthropicChatModelSettings(),
  }) {
    return chatModel(modelId, settings: settings);
  }

  AnthropicLanguageModel chatModel(
    String modelId, {
    AnthropicChatModelSettings settings = const AnthropicChatModelSettings(),
  }) {
    return AnthropicLanguageModel(
      apiKey: apiKey,
      modelId: modelId,
      transport: transport,
      baseUrl: baseUrl,
      settings: settings,
    );
  }

  AnthropicFiles files({
    AnthropicFilesSettings settings = const AnthropicFilesSettings(),
  }) {
    return AnthropicFiles(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
      settings: settings,
    );
  }
}
