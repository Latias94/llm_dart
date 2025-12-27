import 'package:llm_dart_provider_utils/utils/config_utils.dart';
import 'package:llm_dart_provider_utils/utils/dio_client_factory.dart';
import 'openai_request_config.dart';

/// OpenAI-specific Dio strategy implementation
///
/// Handles OpenAI's standard Bearer token authentication
/// and OpenAI-compatible provider configurations.
class OpenAIDioStrategy extends BaseProviderDioStrategy {
  @override
  final String providerName;

  OpenAIDioStrategy({this.providerName = 'OpenAI'});

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final openaiConfig = config as OpenAIRequestConfig;
    final headers = ConfigUtils.buildOpenAIHeaders(openaiConfig.apiKey);
    final extra = openaiConfig.extraHeaders;
    if (extra != null && extra.isNotEmpty) {
      headers.addAll(extra);
    }
    return headers;
  }
}
