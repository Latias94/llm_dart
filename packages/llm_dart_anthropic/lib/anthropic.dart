/// Anthropic provider package entrypoint.
library;

import 'package:llm_dart_anthropic_compatible/config.dart';

import 'provider.dart';
import 'src/anthropic_provider_v3.dart';

// Provider modules
export 'provider.dart';

export 'src/anthropic_provider_v3.dart'
    show
        AnthropicProviderV3,
        AnthropicProviderSettings;
//
// Advanced endpoint wrappers are opt-in:
// - `package:llm_dart_anthropic/files.dart`
// - `package:llm_dart_anthropic/models.dart`

/// Create an Anthropic provider (AI SDK v3 style).
AnthropicProviderV3 createAnthropic({
  required Object? apiKey,
  Object? baseUrl,
  Map<String, String>? headers,
  Duration? timeout,
  String name = 'anthropic',
  AnthropicProvider Function(AnthropicConfig config)? providerFactory,
}) {
  return AnthropicProviderV3(
    AnthropicProviderSettings(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      timeout: timeout,
      name: name,
      providerFactory: providerFactory,
    ),
  );
}

/// Alias for `createAnthropic(...)` (upstream parity).
AnthropicProviderV3 anthropic({
  required Object? apiKey,
  Object? baseUrl,
  Map<String, String>? headers,
  Duration? timeout,
  String name = 'anthropic',
  AnthropicProvider Function(AnthropicConfig config)? providerFactory,
}) =>
    createAnthropic(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      timeout: timeout,
      name: name,
      providerFactory: providerFactory,
    );
