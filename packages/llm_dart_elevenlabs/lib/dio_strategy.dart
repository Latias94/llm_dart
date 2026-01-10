/// (Tier 3 / opt-in) ElevenLabs Dio strategy used by `llm_dart_provider_utils`.
///
/// This library is intentionally not part of the recommended provider
/// entrypoints.
library;

import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import 'config.dart';

/// ElevenLabs-specific Dio strategy implementation.
class ElevenLabsDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'ElevenLabs';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final elevenLabsConfig = config as ElevenLabsConfig;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'xi-api-key': elevenLabsConfig.apiKey,
    };

    if (!hasHeaderIgnoreCase(headers, 'user-agent')) {
      headers['User-Agent'] =
          defaultUserAgentForProvider(elevenLabsConfig.providerId);
    }

    return headers;
  }

  @override
  Duration? getTimeout(dynamic config) {
    final elevenLabsConfig = config as ElevenLabsConfig;
    return elevenLabsConfig.timeout ?? const Duration(seconds: 60);
  }
}
