import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/xai_config.dart';

class XAIDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'xAI';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final xaiConfig = config as XAIConfig;
    return {
      'Authorization': 'Bearer ${xaiConfig.apiKey}',
      'Content-Type': 'application/json',
    };
  }
}
