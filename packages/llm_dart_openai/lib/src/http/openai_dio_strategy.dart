import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/openai_config.dart';

/// OpenAI-specific Dio strategy implementation for the OpenAI subpackage.
class OpenAIDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'OpenAI';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final openaiConfig = config as OpenAIConfig;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${openaiConfig.apiKey}',
    };
  }
}
