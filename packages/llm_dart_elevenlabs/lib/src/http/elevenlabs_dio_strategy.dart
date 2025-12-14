import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/elevenlabs_config.dart';

/// ElevenLabs-specific Dio strategy implementation
///
/// Handles ElevenLabs' unique authentication using xi-api-key header.
class ElevenLabsDioStrategy extends BaseProviderDioStrategy<ElevenLabsConfig> {
  @override
  String get providerName => 'ElevenLabs';

  @override
  Map<String, String> buildHeaders(ElevenLabsConfig config) {
    return {
      'xi-api-key': config.apiKey,
      'Content-Type': 'application/json',
    };
  }

  @override
  Duration? getTimeout(ElevenLabsConfig config) {
    return config.timeout ?? const Duration(seconds: 60);
  }
}
