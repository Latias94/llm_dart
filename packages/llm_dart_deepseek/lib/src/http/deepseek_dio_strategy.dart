import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/deepseek_config.dart';

/// DeepSeek-specific Dio strategy implementation.
///
/// Uses OpenAI-compatible authentication (Bearer token).
class DeepSeekDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'DeepSeek';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final deepSeekConfig = config as DeepSeekConfig;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${deepSeekConfig.apiKey}',
    };
  }
}
