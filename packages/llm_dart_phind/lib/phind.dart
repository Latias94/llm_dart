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

import 'defaults.dart';

import 'config.dart';
import 'provider.dart';

export 'config.dart';
export 'provider.dart';

PhindProvider createPhindProvider({
  required String apiKey,
  String model = phindDefaultModel,
  String baseUrl = phindBaseUrl,
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
