import '../../utils/config_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

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
    return ConfigUtils.buildBearerAuthHeaders(deepSeekConfig.apiKey);
  }
}
