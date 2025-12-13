import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/deepseek_config.dart';

/// DeepSeek-specific Dio strategy implementation.
///
/// Uses OpenAI-compatible authentication (Bearer token).
class DeepSeekDioStrategy extends BaseProviderDioStrategy<DeepSeekConfig> {
  @override
  String get providerName => 'DeepSeek';

  @override
  Map<String, String> buildHeaders(DeepSeekConfig config) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    };
  }
}
