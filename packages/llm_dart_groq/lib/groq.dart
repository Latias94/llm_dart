/// Modular Groq Provider.
library;

import 'package:llm_dart_core/llm_dart_core.dart';

import 'config.dart';
import 'defaults.dart';
import 'provider.dart';
import 'src/groq_provider_v3.dart';

export 'config.dart';
export 'provider.dart';

export 'src/groq_provider_v3.dart' show GroqProviderV3, GroqProviderSettings;

/// Create a Groq provider (AI SDK v3 style).
GroqProviderV3 createGroq({
  Object? apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  Duration? timeout,
  GroqProvider Function(GroqConfig config)? providerFactory,
  GroqProviderClientFactory? clientFactory,
}) {
  return GroqProviderV3(
    GroqProviderSettings(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      timeout: timeout,
      providerFactory: providerFactory,
      clientFactory: clientFactory,
    ),
  );
}

/// Alias for `createGroq(...)` (upstream parity).
GroqProviderV3 groq({
  Object? apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  Duration? timeout,
  GroqProvider Function(GroqConfig config)? providerFactory,
  GroqProviderClientFactory? clientFactory,
}) =>
    createGroq(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      timeout: timeout,
      providerFactory: providerFactory,
      clientFactory: clientFactory,
    );

@Deprecated('Use createGroq()/groq() (ProviderV3) instead.')
GroqProvider createGroqProvider({
  required String apiKey,
  String? model,
  String? baseUrl,
  int? maxTokens,
  double? temperature,
  String? systemPrompt,
  Duration? timeout,
  bool? stream,
  double? topP,
  int? topK,
  List<Tool>? tools,
  ToolChoice? toolChoice,
}) {
  final config = GroqConfig(
    apiKey: apiKey,
    model: model ?? groqDefaultModel,
    baseUrl: baseUrl ?? groqBaseUrl,
    maxTokens: maxTokens,
    temperature: temperature,
    systemPrompt: systemPrompt,
    timeout: timeout,
    topP: topP,
    topK: topK,
    tools: tools,
    toolChoice: toolChoice,
  );

  return GroqProvider(config);
}
