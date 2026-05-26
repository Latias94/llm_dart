import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'non_text_request_support.dart';

final class EmbeddingRequest {
  final EmbeddingModel model;
  final List<String> values;
  final int? dimensions;
  final CallOptions callOptions;

  EmbeddingRequest({
    required this.model,
    required List<String> values,
    this.dimensions,
    this.callOptions = const CallOptions(),
  }) : values = List.unmodifiable(values) {
    _validate();
  }

  factory EmbeddingRequest.single({
    required EmbeddingModel model,
    required String value,
    int? dimensions,
    CallOptions callOptions = const CallOptions(),
  }) {
    return EmbeddingRequest(
      model: model,
      values: [value],
      dimensions: dimensions,
      callOptions: callOptions,
    );
  }

  bool get isSingleValue => values.length == 1;

  EmbedRequest toProviderRequest() {
    return EmbedRequest(
      values: values,
      dimensions: dimensions,
      callOptions: callOptions,
    );
  }

  void _validate() {
    if (values.isEmpty) {
      throw ArgumentError.value(
        values,
        'values',
        'EmbeddingRequest requires at least one value.',
      );
    }

    final max = model.maxEmbeddingsPerCall;
    if (max != null && values.length > max) {
      throw ArgumentError.value(
        values,
        'values',
        'EmbeddingRequest contains ${values.length} values, but '
            '${model.providerId}:${model.modelId} accepts at most $max.',
      );
    }

    if (dimensions != null) {
      requireDescribedModelCapability(
        model: model,
        kind: ModelCapabilityKind.embedding,
        featureId: ModelCapabilityFeatureIds.embeddingDimensions,
        usageContext: 'EmbeddingRequest.dimensions',
      );
    } else {
      requireDescribedModelCapability(
        model: model,
        kind: ModelCapabilityKind.embedding,
        usageContext: 'EmbeddingRequest',
      );
    }
  }
}

final class EmbedValueResult {
  final String value;
  final List<double> embedding;
  final UsageStats? usage;
  final List<ModelWarning> warnings;
  final ModelResponseMetadata? responseMetadata;
  final ProviderMetadata? providerMetadata;

  EmbedValueResult({
    required this.value,
    required List<double> embedding,
    this.usage,
    List<ModelWarning> warnings = const [],
    this.responseMetadata,
    this.providerMetadata,
  })  : embedding = List<double>.unmodifiable(embedding),
        warnings = List<ModelWarning>.unmodifiable(warnings);
}

Future<EmbedValueResult> embed({
  required EmbeddingModel model,
  required String value,
  int? dimensions,
  CallOptions callOptions = const CallOptions(),
}) async {
  return embedForRequest(
    EmbeddingRequest.single(
      model: model,
      value: value,
      dimensions: dimensions,
      callOptions: callOptions,
    ),
  );
}

Future<EmbedValueResult> embedForRequest(EmbeddingRequest request) async {
  if (!request.isSingleValue) {
    throw ArgumentError.value(
      request.values,
      'request',
      'embedForRequest(...) requires exactly one input value.',
    );
  }

  final result = await request.model.doEmbed(
    request.toProviderRequest(),
  );

  if (result.embeddings.length != 1) {
    throw StateError(
      'EmbeddingModel.doEmbed returned ${result.embeddings.length} embeddings '
      'for a single-value embed(...) call.',
    );
  }

  return EmbedValueResult(
    value: request.values.single,
    embedding: result.embeddings.single,
    usage: result.usage,
    warnings: result.warnings,
    responseMetadata: result.responseMetadata,
    providerMetadata: result.providerMetadata,
  );
}

Future<EmbedResult> embedMany({
  required EmbeddingModel model,
  required List<String> values,
  int? dimensions,
  CallOptions callOptions = const CallOptions(),
}) async {
  return embedManyForRequest(
    EmbeddingRequest(
      model: model,
      values: values,
      dimensions: dimensions,
      callOptions: callOptions,
    ),
  );
}

Future<EmbedResult> embedManyForRequest(EmbeddingRequest request) async {
  final result = await request.model.doEmbed(request.toProviderRequest());

  if (result.embeddings.length != request.values.length) {
    throw StateError(
      'EmbeddingModel.doEmbed returned ${result.embeddings.length} embeddings '
      'for ${request.values.length} input values.',
    );
  }

  return result;
}
