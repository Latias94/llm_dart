import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/xai_config.dart';

class XAIDioStrategy extends BaseProviderDioStrategy<XAIConfig> {
  @override
  String get providerName => 'xAI';

  @override
  Map<String, String> buildHeaders(XAIConfig config) {
    return {
      'Authorization': 'Bearer ${config.apiKey}',
      'Content-Type': 'application/json',
    };
  }
}
