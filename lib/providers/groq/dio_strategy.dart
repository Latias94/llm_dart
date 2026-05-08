import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../../src/compatibility/http/header_utils.dart';
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
    return CompatHeaderUtils.buildBearerAuthHeaders(groqConfig.apiKey);
  }
}
