/// Modular Groq Provider.
library;

import 'package:llm_dart_core/models/tool_models.dart';

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

GroqProvider createGroqChatProvider({
  required String apiKey,
  String model = 'llama-3.3-70b-versatile',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGroqProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

GroqProvider createGroqFastProvider({
  required String apiKey,
  String model = 'llama-3.1-8b-instant',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGroqProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

GroqProvider createGroqVisionProvider({
  required String apiKey,
  String model = 'llava-v1.5-7b-4096-preview',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGroqProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

GroqProvider createGroqCodeProvider({
  required String apiKey,
  String model = 'llama-3.1-70b-versatile',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGroqProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature ?? 0.1,
    maxTokens: maxTokens,
  );
}
