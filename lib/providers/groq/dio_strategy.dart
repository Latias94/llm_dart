import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import 'config.dart';

/// Groq-specific Dio strategy implementation
///
/// Uses OpenAI-compatible authentication (Bearer token).
class GroqDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'Groq';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final groqConfig = config as GroqConfig;
    return HttpHeaderUtils.buildOpenAIHeaders(groqConfig.apiKey);
  }
}
