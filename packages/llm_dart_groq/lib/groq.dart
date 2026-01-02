/// Modular Groq Provider.
library;

import 'package:llm_dart_core/llm_dart_core.dart';

import 'config.dart';
import 'defaults.dart';
import 'provider.dart';

export 'config.dart';
export 'provider.dart';

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
