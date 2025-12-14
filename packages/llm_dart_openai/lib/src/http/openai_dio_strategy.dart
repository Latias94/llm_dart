import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/openai_config.dart';

/// OpenAI-specific Dio strategy implementation for the OpenAI subpackage.
class OpenAIDioStrategy extends BaseProviderDioStrategy<OpenAIConfig> {
  @override
  String get providerName => 'OpenAI';

  @override
  Map<String, String> buildHeaders(OpenAIConfig config) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    };
  }
}
