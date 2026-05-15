import 'package:llm_dart_provider/llm_dart_provider.dart';

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
  final result = await model.doEmbed(
    EmbedRequest(
      values: [value],
      dimensions: dimensions,
      callOptions: callOptions,
    ),
  );

  if (result.embeddings.length != 1) {
    throw StateError(
      'EmbeddingModel.doEmbed returned ${result.embeddings.length} embeddings '
      'for a single-value embed(...) call.',
    );
  }

  return EmbedValueResult(
    value: value,
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
  if (values.isEmpty) {
    throw ArgumentError.value(
      values,
      'values',
      'embedMany(...) requires at least one value.',
    );
  }

  final result = await model.doEmbed(
    EmbedRequest(
      values: values,
      dimensions: dimensions,
      callOptions: callOptions,
    ),
  );

  if (result.embeddings.length != values.length) {
    throw StateError(
      'EmbeddingModel.doEmbed returned ${result.embeddings.length} embeddings '
      'for ${values.length} input values.',
    );
  }

  return result;
}
