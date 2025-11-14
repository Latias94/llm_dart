import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/elevenlabs_config.dart';

/// ElevenLabs-specific Dio strategy implementation
///
/// Handles ElevenLabs' unique authentication using xi-api-key header.
class ElevenLabsDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'ElevenLabs';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final elevenLabsConfig = config as ElevenLabsConfig;
    return {
      'xi-api-key': elevenLabsConfig.apiKey,
      'Content-Type': 'application/json',
    };
  }

  @override
  Duration? getTimeout(dynamic config) {
    final elevenLabsConfig = config as ElevenLabsConfig;
    return elevenLabsConfig.timeout ?? const Duration(seconds: 60);
  }
}
