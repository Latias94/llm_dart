import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_embedding_model_request.dart';
import 'google_embedding_model_response.dart';
import 'google_embedding_model_transport.dart';
import 'google_model_describer.dart';
import 'google_model_settings.dart';

final class GoogleEmbeddingModel
    implements EmbeddingModel, CapabilityDescribedModel {
  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final GoogleEmbeddingModelSettings settings;

  @override
  final String modelId;

  GoogleEmbeddingModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    String? baseUrl,
    ProviderModelOptions settings = const GoogleEmbeddingModelSettings(),
  })  : settings = resolveGoogleEmbeddingModelSettings(settings),
        baseUrl = baseUrl ?? 'https://generativelanguage.googleapis.com/v1beta';

  @override
  String get providerId => 'google';

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeGoogleEmbeddingModel(modelId);
  }

  @override
  int get maxEmbeddingsPerCall => 2048;

  @override
  bool get supportsParallelCalls => true;

  Uri get embedContentUri => resolveGoogleEmbeddingRouteUri(
        baseUrl: baseUrl,
        modelId: modelId,
        batch: false,
      );

  Uri get batchEmbedContentsUri => resolveGoogleEmbeddingRouteUri(
        baseUrl: baseUrl,
        modelId: modelId,
        batch: true,
      );

  @override
  Future<EmbedResult> doEmbed(EmbedRequest request) async {
    final options = resolveGoogleEmbeddingProviderOptions(request.callOptions);
    final batch = request.values.length != 1;
    final body = buildGoogleEmbeddingRequestBody(
      modelId: modelId,
      request: request,
      options: options,
    );
    final response = await transport.send(
      buildGoogleEmbeddingTransportRequest(
        baseUrl: baseUrl,
        modelId: modelId,
        request: request,
        batch: batch,
        body: body,
        apiKey: apiKey,
        settings: settings,
      ),
    );

    return decodeGoogleEmbeddingResponse(
      body: response.body,
      batch: batch,
      modelId: modelId,
      headers: response.headers,
    );
  }
}
