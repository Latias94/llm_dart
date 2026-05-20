import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../provider/openai_family_profile.dart';
import '../provider/openai_family_url_support.dart';
import 'openai_embedding_model_body.dart';
import 'openai_embedding_model_request.dart';
import 'openai_embedding_model_response.dart';
import 'openai_embedding_model_transport.dart';
import '../provider/openai_model_describer.dart';
import '../provider/openai_model_settings.dart';
import '../common/openai_non_text_model_support.dart';

final class OpenAIEmbeddingModel
    implements EmbeddingModel, CapabilityDescribedModel {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAIEmbeddingModelSettings settings;

  @override
  final String modelId;

  OpenAIEmbeddingModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    required this.profile,
    String? baseUrl,
    ProviderModelOptions settings = const OpenAIEmbeddingModelSettings(),
  })  : settings = resolveOpenAIEmbeddingModelSettings(settings),
        baseUrl = normalizeOpenAIFamilyBaseUrl(baseUrl, profile);

  @override
  String get providerId => profile.providerId;

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeOpenAIEmbeddingModel(
      modelId,
      profile: profile,
    );
  }

  @override
  int get maxEmbeddingsPerCall => openAIMaxEmbeddingsPerCall;

  @override
  bool get supportsParallelCalls => true;

  Uri get embeddingsUri => resolveOpenAIEmbeddingRouteUri(baseUrl: baseUrl);

  Map<String, String> get defaultHeaders => buildOpenAIEmbeddingDefaultHeaders(
        profile: profile,
        apiKey: apiKey,
        settings: settings,
      );

  @override
  Future<EmbedResult> doEmbed(EmbedRequest request) async {
    final options = resolveOpenAIEmbeddingProviderOptions(request.callOptions);
    validateOpenAIEmbeddingValueCount(
      request.values,
      maxEmbeddingsPerCall: maxEmbeddingsPerCall,
    );
    final body = buildOpenAIEmbeddingRequestBody(
      modelId: modelId,
      request: request,
      options: options,
    );
    return sendOpenAIFamilyModelRequest(
      transport: transport,
      request: buildOpenAIEmbeddingTransportRequest(
        baseUrl: baseUrl,
        request: request,
        body: body,
        defaultHeaders: defaultHeaders,
      ),
      decode: (body, headers) => decodeOpenAIEmbeddingResponse(
        body: body,
        modelId: modelId,
        headers: headers,
      ),
    );
  }
}
