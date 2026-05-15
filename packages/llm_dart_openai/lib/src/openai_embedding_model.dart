import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_model_describer.dart';
import 'openai_non_text_model_support.dart';
import 'openai_options.dart';

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
  })  : settings = resolveOpenAIModelSettings(
          settings,
          parameterName: 'settings',
          expectedTypeName:
              'OpenAIEmbeddingModelSettings for OpenAI-family embedding models',
        ),
        baseUrl = baseUrl ?? profile.defaultBaseUrl;

  @override
  String get providerId => profile.providerId;

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeOpenAIEmbeddingModel(
      modelId,
      profile: profile,
    );
  }

  int get maxEmbeddingsPerCall => 2048;

  Uri get embeddingsUri => Uri.parse('$baseUrl/embeddings');

  Map<String, String> get defaultHeaders => buildOpenAIFamilyDefaultHeaders(
        profile: profile,
        apiKey: apiKey,
        organization: settings.organization,
        project: settings.project,
        headers: settings.headers,
      );

  @override
  Future<EmbedResult> doEmbed(EmbedRequest request) async {
    final options = resolveOpenAIProviderOptions<OpenAIEmbedOptions>(
      request.callOptions,
      parameterName: 'request.callOptions.providerOptions',
      expectedTypeName: 'OpenAIEmbedOptions for OpenAI-family embedding models',
    );
    if (request.values.length > maxEmbeddingsPerCall) {
      throw ArgumentError.value(
        request.values.length,
        'request.values.length',
        'OpenAI embedding models support at most $maxEmbeddingsPerCall values per call.',
      );
    }

    final response = await transport.send(
      TransportRequest(
        uri: embeddingsUri,
        method: TransportMethod.post,
        headers: {
          ...defaultHeaders,
          'content-type': 'application/json',
          'accept': 'application/json',
          if (request.callOptions.headers case final headers?) ...headers,
        },
        body: {
          'model': modelId,
          'input': request.values,
          if (request.dimensions != null) 'dimensions': request.dimensions,
          'encoding_format': options?.encodingFormat ?? 'float',
          if (options?.user case final user?) 'user': user,
        },
        timeout: request.callOptions.timeout,
        maxRetries: request.callOptions.maxRetries,
        cancellation: request.callOptions.cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return _decodeResponse(
      response.body,
      headers: response.headers,
    );
  }

  EmbedResult _decodeResponse(
    Object? body, {
    required Map<String, String> headers,
  }) {
    final json = decodeOpenAIJsonObject(
      body,
      responseName: 'embeddings response',
    );
    final data = json['data'];
    if (data is! List) {
      throw StateError(
        'Expected an OpenAI embeddings response with a data list.',
      );
    }

    final indexedEmbeddings = <({int index, List<double> embedding})>[];
    for (var index = 0; index < data.length; index += 1) {
      final item = data[index];
      if (item is! Map) {
        throw StateError(
          'Expected OpenAI embedding item $index to be a JSON object.',
        );
      }

      final map = Map<String, Object?>.from(item);
      final embedding = map['embedding'];
      if (embedding is! List) {
        throw StateError(
          'Expected OpenAI embedding item $index to contain an embedding list.',
        );
      }

      indexedEmbeddings.add(
        (
          index: openAIIntOrNull(map['index']) ?? index,
          embedding: List<double>.unmodifiable(
            embedding.map((value) {
              if (value is! num) {
                throw StateError(
                  'Expected OpenAI embedding value to be numeric, got '
                  '${value.runtimeType}.',
                );
              }

              return value.toDouble();
            }),
          ),
        ),
      );
    }

    indexedEmbeddings.sort((left, right) => left.index.compareTo(right.index));

    return EmbedResult(
      embeddings: indexedEmbeddings.map((entry) => entry.embedding).toList(),
      usage: _decodeUsage(json['usage']),
      responseMetadata: ModelResponseMetadata(
        timestamp: DateTime.now().toUtc(),
        modelId: modelId,
        headers: headers,
      ),
    );
  }

  UsageStats? _decodeUsage(Object? usage) {
    if (usage is! Map) {
      return null;
    }

    final map = Map<String, Object?>.from(usage);
    return UsageStats(
      inputTokens: openAIIntOrNull(map['prompt_tokens']),
      totalTokens: openAIIntOrNull(map['total_tokens']),
    );
  }
}
