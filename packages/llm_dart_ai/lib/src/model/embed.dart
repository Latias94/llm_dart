import 'package:llm_dart_provider/llm_dart_provider.dart';

final class EmbedValueResult {
  final String value;
  final List<double> embedding;
  final UsageStats? usage;
  final ProviderMetadata? providerMetadata;

  EmbedValueResult({
    required this.value,
    required List<double> embedding,
    this.usage,
    this.providerMetadata,
  }) : embedding = List<double>.unmodifiable(embedding);
}

Future<EmbedValueResult> embed({
  required EmbeddingModel model,
  required String value,
  int? dimensions,
  CallOptions callOptions = const CallOptions(),
}) async {
  final result = await model.embed(
    EmbedRequest(
      values: [value],
      dimensions: dimensions,
      callOptions: callOptions,
    ),
  );

  if (result.embeddings.length != 1) {
    throw StateError(
      'EmbeddingModel.embed returned ${result.embeddings.length} embeddings '
      'for a single-value embed(...) call.',
    );
  }

  return EmbedValueResult(
    value: value,
    embedding: result.embeddings.single,
    usage: result.usage,
    providerMetadata: result.providerMetadata,
  );
}

Future<EmbedResult> embedMany({
  required EmbeddingModel model,
  required List<String> values,
  int? dimensions,
  CallOptions callOptions = const CallOptions(),
}) async {
  if (values.isEmpty) {
    throw ArgumentError.value(
      values,
      'values',
      'embedMany(...) requires at least one value.',
    );
  }

  final result = await model.embed(
    EmbedRequest(
      values: values,
      dimensions: dimensions,
      callOptions: callOptions,
    ),
  );

  if (result.embeddings.length != values.length) {
    throw StateError(
      'EmbeddingModel.embed returned ${result.embeddings.length} embeddings '
      'for ${values.length} input values.',
    );
  }

  return result;
}
