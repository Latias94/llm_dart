import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../../src/compatibility/http/header_utils.dart';
import 'config.dart';

/// DeepSeek-specific Dio strategy implementation
///
/// Uses OpenAI-compatible authentication (Bearer token).
class DeepSeekDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'DeepSeek';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final deepSeekConfig = config as DeepSeekConfig;
    return CompatHeaderUtils.buildBearerAuthHeaders(deepSeekConfig.apiKey);
  }
}
