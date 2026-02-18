/// DeepSeek Provider (OpenAI-compatible)
///
/// DeepSeek's HTTP API follows an OpenAI-compatible shape. This package keeps a
/// thin provider wrapper and delegates protocol behavior to
/// `llm_dart_openai_compatible` so we don't duplicate request/stream parsing
/// logic across compatible providers.
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart_deepseek/deepseek.dart';
///
/// final provider = DeepSeekProvider(DeepSeekConfig(
///   apiKey: 'your-api-key',
///   model: 'deepseek-chat',
/// ));
///
/// // Use chat capability
/// final response = await provider.chat(messages);
/// ```
library;

import 'config.dart';
import 'defaults.dart';
import 'provider.dart';
import 'src/deepseek_provider_v3.dart';

// Core exports
export 'config.dart';
export 'provider.dart';
// Advanced endpoint wrappers are opt-in:
// - `package:llm_dart_deepseek/models.dart`

export 'src/deepseek_provider_v3.dart'
    show DeepSeekProviderV3, DeepSeekProviderSettings;

/// Create a DeepSeek provider (AI SDK v3 style).
DeepSeekProviderV3 createDeepSeek({
  Object? apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  Duration? timeout,
  DeepSeekProvider Function(DeepSeekConfig config)? providerFactory,
}) {
  return DeepSeekProviderV3(
    DeepSeekProviderSettings(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      timeout: timeout,
      providerFactory: providerFactory,
    ),
  );
}

/// Alias for `createDeepSeek(...)` (upstream parity).
DeepSeekProviderV3 deepseek({
  Object? apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  Duration? timeout,
  DeepSeekProvider Function(DeepSeekConfig config)? providerFactory,
}) =>
    createDeepSeek(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      timeout: timeout,
      providerFactory: providerFactory,
    );

/// Create a DeepSeek provider with default configuration
@Deprecated('Use createDeepSeek()/deepseek() (ProviderV3) instead.')
DeepSeekProvider createDeepSeekProvider({
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
}) {
  final config = DeepSeekConfig(
    apiKey: apiKey,
    model: model ?? deepseekDefaultModel,
    baseUrl: baseUrl ?? deepseekBaseUrl,
    maxTokens: maxTokens,
    temperature: temperature,
    systemPrompt: systemPrompt,
    timeout: timeout,
    topP: topP,
    topK: topK,
  );

  return DeepSeekProvider(config);
}
