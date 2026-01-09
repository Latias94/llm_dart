import 'package:dio/dio.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
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

    final providerId = openaiConfig.providerId.toLowerCase().trim();
    final isAzure = providerId == 'azure' ||
        providerId == 'azure-openai' ||
        providerId.startsWith('azure.');

    final headers = isAzure
        ? ConfigUtils.buildHeaders(
            apiKey: openaiConfig.apiKey,
            authHeaderName: 'api-key',
          )
        : ConfigUtils.buildOpenAIHeaders(openaiConfig.apiKey);
    final extra = openaiConfig.extraHeaders;
    if (extra != null && extra.isNotEmpty) {
      headers.addAll(extra);
    }
    return headers;
  }

  @override
  List<DioEnhancer> getEnhancers(dynamic config) {
    final openaiConfig = config as OpenAIRequestConfig;
    final providerId = openaiConfig.providerId.toLowerCase().trim();
    final isAzure = providerId == 'azure' ||
        providerId == 'azure-openai' ||
        providerId.startsWith('azure.');

    if (!isAzure) return const [];

    final apiVersion = openaiConfig.getProviderOption<String>('apiVersion');
    if (apiVersion == null || apiVersion.isEmpty) return const [];

    return [
      InterceptorEnhancer(
        _AzureApiVersionQueryInterceptor(apiVersion),
        'AzureOpenAIApiVersionQuery',
      ),
    ];
  }
}

class _AzureApiVersionQueryInterceptor extends Interceptor {
  final String apiVersion;

  _AzureApiVersionQueryInterceptor(this.apiVersion);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.queryParameters.putIfAbsent('api-version', () => apiVersion);
    super.onRequest(options, handler);
  }
}
