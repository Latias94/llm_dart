import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_language_model.dart';
import 'anthropic_options.dart';

final class Anthropic {
  static const String defaultBaseUrl = 'https://api.anthropic.com/v1';

  final String apiKey;
  final String baseUrl;
  final TransportClient transport;

  Anthropic({
    required this.apiKey,
    TransportClient? transport,
    String? baseUrl,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        transport = transport ?? DioTransportClient();

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
}
