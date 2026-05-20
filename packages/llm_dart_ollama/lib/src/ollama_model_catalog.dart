import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'ollama_api.dart';
import 'ollama_model_call_support.dart';
import 'ollama_model_catalog_models.dart';
export 'ollama_model_catalog_models.dart'
    show OllamaInstalledModel, OllamaInstalledModelDetails;

final class OllamaCatalogSettings {
  final Map<String, String> headers;

  const OllamaCatalogSettings({
    this.headers = const {},
  });
}

final class OllamaModelCatalogClient {
  final String? apiKey;
  final String baseUrl;
  final TransportClient transport;
  final OllamaCatalogSettings settings;

  OllamaModelCatalogClient({
    required this.transport,
    String? apiKey,
    String? baseUrl,
    this.settings = const OllamaCatalogSettings(),
  })  : apiKey = normalizeOllamaApiKey(apiKey),
        baseUrl = normalizeOllamaBaseUrl(baseUrl);

  Uri get tagsUri => resolveOllamaUri(baseUrl, '/api/tags');

  Future<List<OllamaInstalledModel>> listModels({
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return sendOllamaModelRequest(
      transport: transport,
      request: TransportRequest(
        uri: tagsUri,
        method: TransportMethod.get,
        headers: buildOllamaHeaders(
          apiKey: apiKey,
          headers: {
            ...settings.headers,
            if (headers != null) ...headers,
          },
        ),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
      decode: (body, _) {
        final json = decodeOllamaJsonObject(
          body,
          responseName: 'model catalog response',
        );
        return decodeOllamaInstalledModelsList(json);
      },
    );
  }
}
