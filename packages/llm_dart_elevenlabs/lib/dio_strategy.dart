import 'package:llm_dart_provider_utils/utils/dio_client_factory.dart';

import 'config.dart';

/// ElevenLabs-specific Dio strategy implementation.
class ElevenLabsDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'ElevenLabs';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final elevenLabsConfig = config as ElevenLabsConfig;
    return {
      'Content-Type': 'application/json',
      'xi-api-key': elevenLabsConfig.apiKey,
    };
  }

  @override
  Duration? getTimeout(dynamic config) {
    final elevenLabsConfig = config as ElevenLabsConfig;
    return elevenLabsConfig.timeout ?? const Duration(seconds: 60);
  }
}
