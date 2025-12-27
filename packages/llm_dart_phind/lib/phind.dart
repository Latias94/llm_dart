/// Modular Phind Provider (OpenAI-compatible)
///
/// Phind is treated as an OpenAI-compatible API surface. This package keeps a
/// thin provider wrapper and delegates request/stream parsing to
/// `llm_dart_openai_compatible`.
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart_phind/llm_dart_phind.dart';
///
/// final provider = PhindProvider(PhindConfig(
///   apiKey: 'your-api-key',
///   model: 'Phind-70B',
/// ));
/// ```
library;

import 'package:llm_dart_core/core/provider_defaults.dart';

import 'config.dart';
import 'provider.dart';

export 'config.dart';
export 'provider.dart';

PhindProvider createPhindProvider({
  required String apiKey,
  String model = 'Phind-70B',
  String baseUrl = ProviderDefaults.phindBaseUrl,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = PhindConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: baseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return PhindProvider(config);
}

PhindProvider createPhindCodeProvider({
  required String apiKey,
  String model = 'Phind-70B',
  double? temperature = 0.1,
  int? maxTokens = 4000,
  String? systemPrompt =
      'You are an expert programmer. Provide clear, well-commented code solutions.',
}) {
  final config = PhindConfig(
    apiKey: apiKey,
    model: model,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return PhindProvider(config);
}

PhindProvider createPhindExplainerProvider({
  required String apiKey,
  String model = 'Phind-70B',
  double? temperature = 0.3,
  int? maxTokens = 2000,
  String? systemPrompt =
      'You are a coding tutor. Explain code concepts clearly and provide examples.',
}) {
  final config = PhindConfig(
    apiKey: apiKey,
    model: model,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return PhindProvider(config);
}
