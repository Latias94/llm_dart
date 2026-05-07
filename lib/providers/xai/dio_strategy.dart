import '../../utils/config_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'config.dart';

/// xAI-specific Dio strategy implementation
///
/// Handles xAI's Bearer token authentication.
class XAIDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'xAI';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final xaiConfig = config as XAIConfig;
    return ConfigUtils.buildBearerAuthHeaders(xaiConfig.apiKey);
  }
}
