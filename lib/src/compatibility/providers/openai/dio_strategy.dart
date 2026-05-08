import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../../../../providers/openai/config.dart';
import '../../http/header_utils.dart';

/// OpenAI-specific Dio strategy implementation
///
/// Handles OpenAI's standard Bearer token authentication
/// and OpenAI-compatible provider configurations.
class OpenAIDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'OpenAI';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final openaiConfig = config as OpenAIConfig;
    return CompatHeaderUtils.buildBearerAuthHeaders(openaiConfig.apiKey);
  }
}
