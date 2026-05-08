import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../../src/compatibility/http/header_utils.dart';
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
    return CompatHeaderUtils.buildBearerAuthHeaders(xaiConfig.apiKey);
  }
}
