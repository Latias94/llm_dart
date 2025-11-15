import '../../utils/config_utils.dart';
import '../../utils/dio_client_factory.dart';
import 'config.dart';

/// DeepSeek-specific Dio strategy implementation (legacy).
///
/// The canonical DeepSeek HTTP strategy lives in the `llm_dart_deepseek`
/// subpackage. This class is retained for backwards compatibility and
/// testing of `DioClientFactory`.
@Deprecated(
  'DeepSeekDioStrategy in the main package is legacy. '
  'DeepSeek HTTP configuration now lives in the llm_dart_deepseek package.',
)
class DeepSeekDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'DeepSeek';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final deepSeekConfig = config as DeepSeekConfig;
    return ConfigUtils.buildOpenAIHeaders(deepSeekConfig.apiKey);
  }
}
